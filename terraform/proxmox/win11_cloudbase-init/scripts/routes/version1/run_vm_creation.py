import subprocess
import sys
import threading
import time
import queue
import signal
import logging
import os

# Configure a dedicated logger for this module
logger = logging.getLogger('run_vm_creation')
logger.setLevel(logging.INFO)

# Create file handler for logging to a separate file
file_handler = logging.FileHandler('run_vm_creation.log')
file_handler.setLevel(logging.INFO)

# Create a logging format
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
file_handler.setFormatter(formatter)

# Add the file handler to the logger
logger.addHandler(file_handler)

# Ensure the logger does not propagate to the root logger
logger.propagate = False

# Define synchronization objects
LOCK = threading.Lock()
REQUEST_QUEUE = queue.Queue()
STOP_EVENT = threading.Event()

def run_command(command, directory):
    logger.info(f"Running command: {command}")
    process = subprocess.Popen(command, stdout=subprocess.PIPE, text=True, cwd=directory)
    try:
        while True:
            output = process.stdout.readline()
            if output:
                logger.info(output.strip())
            if output == '' and process.poll() is not None:
                break
    except KeyboardInterrupt:
        logger.warning("Script subprocess interrupted. Exiting....")
        process.send_signal(signal.SIGINT)
        while process.poll() is None:
            output = process.stdout.readline()
            if output:
                logger.info(output.strip())
    if process.poll() != 0:
        logger.error("Error during command execution. Exiting subprocess.")
        sys.exit(1)

def process_requests():
    logger.info("Processing requests")
    try:
        count_idle = 0
        sleep_time = 3
        while not STOP_EVENT.is_set():
            logger.info(f"Checking lock. Sleep time: {sleep_time}. Count idle: {count_idle}")
            with LOCK:
                logger.info("Lock acquired, checking request queue")
                if not REQUEST_QUEUE.empty():
                    count_idle = 0
                    sleep_time = 3
                    request = REQUEST_QUEUE.get()
                    update_terraform_state(request)
                else:
                    logger.info("Request queue is empty")
                    if count_idle < 5:
                        count_idle += 1
                    elif 10 <= count_idle < 20:
                        count_idle += 1
                        sleep_time = 15
                    elif 20 <= count_idle < 50:
                        count_idle += 1
                        sleep_time = 30
                    elif 50 <= count_idle:
                        sleep_time = 60
                        
            time.sleep(sleep_time)
    except KeyboardInterrupt:
        logger.warning("Script interrupted. Exiting.")

def update_terraform_state(request):
    logger.info(f"Updating Terraform state for request: {request}")
    try:
        run_command(["terraform", "init"], "/root/TA-Automation/terraform/proxmox/win11_cloudbase-init")
        run_command(["terraform", "validate"], "/root/TA-Automation/terraform/proxmox/win11_cloudbase-init")
        run_command(["terraform", "plan", "-out=tf.plan", "--var-file=/root/TA-Automation/terraform/proxmox/credentials.tfvars"], "/root/TA-Automation/terraform/proxmox/win11_cloudbase-init")
        run_command(["terraform", "apply", "-auto-approve", "tf.plan"], "/root/TA-Automation/terraform/proxmox/win11_cloudbase-init")
        logger.info("Terraform state updated successfully")
        logger.info("\n--------------------------------------------------------\n")

        os.remove("tf.plan")
    except KeyboardInterrupt:
        logger.warning("Script interrupted. Exiting.")
        logger.info("\n--------------------------------------------------------\n")
    except Exception as e:
        logger.error(f"Error updating Terraform state: {e}")
        logger.info("\n--------------------------------------------------------\n")

def handle_request(request):
    logger.info(f"Handling request: {request}")
    REQUEST_QUEUE.put(request)

def start_request_processing():
    logger.info("Starting request processing")
    processing_thread = threading.Thread(target=process_requests)
    processing_thread.start()
    return processing_thread

def stop_request_processing():
    logger.info("Stopping request processing")
    STOP_EVENT.set()
