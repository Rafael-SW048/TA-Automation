#!/bin/bash

run_command() {
    command=$1
    directory=$2

    cd $directory

    ( $command ) &
    pid=$!

    trap 'echo "Script subprocess interrupted. Exiting...."; kill -INT $pid' INT

    wait $pid

    if [ $? -ne 0 ]; then
        echo "Error during command execution. Exiting subprocess."
        exit 1
    fi
}

packerBuild() {
    dirRun="/root/TA-Automation/packer/proxmox/windows/win11_cloudbase-init"

    run_command "packer validate --var-file=./win11_cloudbase-init.pkvars.hcl --var-file=../scripts.pkvars.hcl --var-file=../../credentials.pkr.hcl ." $dirRun
    run_command "packer build --var-file=./win11_cloudbase-init.pkvars.hcl --var-file=../scripts.pkvars.hcl --var-file=../../credentials.pkr.hcl ." $dirRun
}

# If no argument is provided, prompt the user for input
if [ -z "$1" ]; then
    read -p "Do you want to build iso? (y/n): " arg
else
    arg=$(echo $1 | tr '[:upper:]' '[:lower:]')
fi

# Check if the argument is "y" or "yes"
if [ "$arg" = "y" ] || [ "$arg" = "yes" ]; then
    echo "Running build_proxmox_iso.sh script..."
    run_command "/root/TA-Automation/packer/proxmox/windows/build_proxmox_iso.sh y" "/root/TA-Automation/packer/proxmox/windows/"
fi

trap 'echo "Script packerBuild interrupted. Exiting..."' INT
packerBuild