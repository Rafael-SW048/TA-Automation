import subprocess
import os
import sys

def run_command(command, directory):
    process = subprocess.Popen(command, stdout=subprocess.PIPE, text=True, cwd=directory)
    while True:
        output = process.stdout.readline()
        print(output.strip())
        # Break the loop if there is no more output and the process has finished
        if output == '' and process.poll() is not None:
            break
    if process.poll() != 0:
        print("Error during command execution. Exiting.")
        sys.exit(1)

def update_terraform_state():
    try:
        # Run the user_vm_config.py script
        # run_command(["python3", "/root/TA-Automation/terraform/proxmox/win11_cloudbase-init/scripts/user_vm_config.py"])

        # Run the Terraform commands
        run_command(["terraform", "init"], "/root/TA-Automation/terraform/proxmox/win11_cloudbase-init")
        run_command(["terraform", "validate"], "/root/TA-Automation/terraform/proxmox/win11_cloudbase-init")
        run_command(["terraform", "plan", "-out=tf.plan", "--var-file=/root/TA-Automation/terraform/proxmox/credentials.tfvars"], "/root/TA-Automation/terraform/proxmox/win11_cloudbase-init")
        run_command(["terraform", "apply", "-auto-approve", "tf.plan"], "/root/TA-Automation/terraform/proxmox/win11_cloudbase-init")

        # os.remove("tf.plan")
    except KeyboardInterrupt:
        print("Script interrupted. Exiting.")