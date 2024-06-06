import subprocess
import signal
import sys

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

def packerBuild():
    try:
        dirRun = "/root/TA-Automation/packer/proxmox/windows/win11_cloudbase-init"
        # Run the Packer commands
        run_command(["packer", "validate", "--var-file=./win11_cloudbase-init.pkvars.hcl", "--var-file=../scripts.pkvars.hcl", "--var-file=../../credentials.pkr.hcl", "."], dirRun)
        run_command(["packer", "build", "--var-file=./win11_cloudbase-init.pkvars.hcl", "--var-file=../scripts.pkvars.hcl", "--var-file=../../credentials.pkr.hcl", "."], dirRun)
    except KeyboardInterrupt:
        print("Script packerBuild interrupted. Exiting...")

packerBuild()