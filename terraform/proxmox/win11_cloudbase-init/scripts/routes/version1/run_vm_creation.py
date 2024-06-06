import subprocess
import signal
import sys
import os
import threading
import time
import queue

# Define constants
LOCK_FILE = "/root/TA-Automation/terraform/proxmox/win11_cloudbase-init/terraform.lock"
RETRY_INTERVAL = 5  # seconds
TIMEOUT = 300  # seconds (5 minutes)

# Define synchronization objects
LOCK = threading.Lock()
REQUEST_QUEUE = queue.Queue()

def run_command(command, directory):
    process = subprocess.Popen(command, stdout=subprocess.PIPE, text=True, cwd=directory)
    try:
        while True:
            output = process.stdout.readline()
            print(output.strip())
            # Break the loop if there is no more output and the process has finished
            if output == '' and process.poll() is not None:
                break
    except KeyboardInterrupt:
        print("Script subprocess interrupted. Exiting....")
        process.send_signal(signal.SIGINT)
        # Continue reading the subprocess's output until it has finished
        while process.poll() is None:
            output = process.stdout.readline()
            print(output.strip())
    if process.poll() != 0:
        print("Error during command execution. Exiting subprocess.")
        sys.exit(1)

def process_requests():
    while True:
        # Wait for the lock to be released
        wait_for_lock()
        
        # Try to acquire the lock
        if LOCK.acquire(blocking=False):
            try:
                # Process the next request in the queue
                if not REQUEST_QUEUE.empty():
                    request = REQUEST_QUEUE.get()
                    update_terraform_state(request)
            finally:
                # Release the lock
                LOCK.release()
        else:
            # If the lock is not available, wait and try again
            time.sleep(1)

def wait_for_lock():
    start_time = time.time()
    while os.path.exists(LOCK_FILE):
        elapsed_time = time.time() - start_time
        if elapsed_time > TIMEOUT:
            print("Timeout while waiting for the lock file to be released. Exiting.")
            return False
        print(f"Lock file exists. Waiting for {RETRY_INTERVAL} seconds...")
        time.sleep(RETRY_INTERVAL)
    return True

def update_terraform_state(request):
    try:
        # Create the lock file
        with open(LOCK_FILE, 'w') as lock_file:
            print("Creating lock file...")
            lock_file.write(f"Locked by process {os.getpid()} at {time.ctime()}\n")

        # Run the Terraform commands
        run_command(["terraform", "init"], "/root/TA-Automation/terraform/proxmox/win11_cloudbase-init")
        run_command(["terraform", "validate"], "/root/TA-Automation/terraform/proxmox/win11_cloudbase-init")
        run_command(["terraform", "plan", "-out=tf.plan", "--var-file=/root/TA-Automation/terraform/proxmox/credentials.tfvars"], "/root/TA-Automation/terraform/proxmox/win11_cloudbase-init")
        run_command(["terraform", "apply", "-auto-approve", "tf.plan"], "/root/TA-Automation/terraform/proxmox/win11_cloudbase-init")

        # os.remove("tf.plan")
    except KeyboardInterrupt:
        print("Script interrupted. Exiting.")
    finally:
        # Remove the lock file
        if os.path.exists(LOCK_FILE):
            os.remove(LOCK_FILE)

def handle_request(request):
    # Add the request to the queue
    REQUEST_QUEUE.put(request)

def start_request_processing():
    # Start a separate thread to process requests
    processing_thread = threading.Thread(target=process_requests)
    processing_thread.start()