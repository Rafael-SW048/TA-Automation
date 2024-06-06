import subprocess
import signal
import sys
import os
import threading
import time
import queue

# Constants
TERRAFORM_DIR = "/root/TA-Automation/terraform/proxmox/win11_cloudbase-init"
STATE_DIR = os.path.join(TERRAFORM_DIR, "states")
PLAN_DIR = os.path.join(TERRAFORM_DIR, "plans")
CREDENTIALS_FILE = "/root/TA-Automation/terraform/proxmox/credentials.tfvars"
RETRY_INTERVAL = 5  # seconds
TIMEOUT = 300  # seconds (5 minutes)

# Ensure the directories exist
os.makedirs(STATE_DIR, exist_ok=True)
os.makedirs(PLAN_DIR, exist_ok=True)

# Synchronization objects
LOCK_CREATE = threading.Lock()
LOCK_DESTROY = threading.Lock()
REQUEST_QUEUE = queue.Queue()

def run_command(command, directory):
    process = subprocess.Popen(command, stdout=subprocess.PIPE, text=True, cwd=directory)
    try:
        while True:
            output = process.stdout.readline()
            if output == '' and process.poll() is not None:
                break
            if output:
                print(output.strip())
    except KeyboardInterrupt:
        print("Script subprocess interrupted. Exiting...")
        process.send_signal(signal.SIGINT)
        while process.poll() is None:
            output = process.stdout.readline()
            print(output.strip())
    if process.poll() != 0:
        print("Error during command execution. Exiting subprocess.")
        sys.exit(1)

def process_requests():
    while True:
        if not REQUEST_QUEUE.empty():
            request = REQUEST_QUEUE.get()
            if request['action'] == "create":
                process_create_request(request)
            elif request['action'] == "destroy":
                process_destroy_request(request)

def wait_for_lock(lock_file_path):
    start_time = time.time()
    while os.path.exists(lock_file_path):
        elapsed_time = time.time() - start_time
        if elapsed_time > TIMEOUT:
            print("Timeout while waiting for the lock file to be released. Exiting.")
            return False
        print(f"Lock file exists. Waiting for {RETRY_INTERVAL} seconds...")
        time.sleep(RETRY_INTERVAL)
    return True

def process_create_request(request):
    lock_file_path = os.path.join(PLAN_DIR, f"create_{request['sid']}.lock")
    if wait_for_lock(lock_file_path):
        if LOCK_CREATE.acquire(blocking=False):
            try:
                update_terraform_state(request, lock_file_path)
            finally:
                LOCK_CREATE.release()

def process_destroy_request(request):
    lock_file_path = os.path.join(PLAN_DIR, f"destroy_{request['sid']}.lock")
    if wait_for_lock(lock_file_path):
        if LOCK_DESTROY.acquire(blocking=False):
            try:
                update_terraform_state(request, lock_file_path)
            finally:
                LOCK_DESTROY.release()

def update_terraform_state(request, lock_file_path):
    action = request['action']
    sid = request['sid']
    state_file = os.path.join(STATE_DIR, f"{sid}.tfstate")
    plan_file = os.path.join(PLAN_DIR, f"tf_{sid}.plan")

    try:
        with open(lock_file_path, 'w') as lock_file:
            print("Creating lock file...")
            lock_file.write(f"Locked by process {os.getpid()} at {time.ctime()}\n")

        run_command(["terraform", "init", "-backend-config", f"path={state_file}"], TERRAFORM_DIR)
        run_command(["terraform", "validate"], TERRAFORM_DIR)
        
        if action == "create":
            run_command(["terraform", "plan", "-out", plan_file, "--var-file", CREDENTIALS_FILE], TERRAFORM_DIR)
            run_command(["terraform", "apply", "-auto-approve", plan_file], TERRAFORM_DIR)
        elif action == "destroy":
            run_command(["terraform", "plan", "-destroy", "-out", plan_file, "--var-file", CREDENTIALS_FILE], TERRAFORM_DIR)
            run_command(["terraform", "apply", "-auto-approve", plan_file], TERRAFORM_DIR)

    except KeyboardInterrupt:
        print("Script interrupted. Exiting.")
    finally:
        if os.path.exists(lock_file_path):
            os.remove(lock_file_path)
        if os.path.exists(plan_file):
            os.remove(plan_file)

def handle_request(request):
    REQUEST_QUEUE.put(request)

def start_request_processing():
    processing_thread = threading.Thread(target=process_requests)
    processing_thread.daemon = True
    processing_thread.start()
