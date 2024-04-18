import subprocess
import os
import sys

def run_command(command):
    process = subprocess.Popen(command, stdout=subprocess.PIPE, text=True)
    while True:
        output = process.stdout.readline()
        print(output.strip())
        # Break the loop if there is no more output and the process has finished
        if output == '' and process.poll() is not None:
            break
    if process.poll() != 0:
        print("Error during command execution. Exiting.")
        sys.exit(1)

def main():
    try:
        # Run the user_vm_config.py script
        run_command(["python3", "/root/TA-Automation/terraform/proxmox/win11_cloudbase-init/user_vm_config.py"])

        # Run the Terraform commands
        run_command(["terraform", "validate"])
        run_command(["terraform", "plan", "--var-file=../credentials.tfvars", "-out", "test.plan"])
        run_command(["terraform", "apply", "-auto-approve", "test.plan"])

        os.remove("test.plan")
    except KeyboardInterrupt:
        print("Script interrupted. Exiting.")

if __name__ == "__main__":
    main()