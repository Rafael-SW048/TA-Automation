## Overview

This packer template is used to create a Windows 11 template VM with Cloudbase-Init, Steam, and ZeroTier installed.

**Disclaimer: This project is a proof of concept and should not be used in production environments. Use at your own risk.**

The API is not yet fully developed, but the packer template is ready to use. However, there is room for improvement to make it more dynamic.

## Prerequisites

Before running the code, ensure you have the following installed on your system:

1. Packer[https://www.packer.io/downloads]
2. Proxmox VE (Virtual Environment) version 8.1 or higher[https://www.proxmox.com/proxmox-ve]
3. Windows 11 ISO[https://www.microsoft.com/en-us/software-download/windows11]
4. VirtIO drivers ISO[https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso]

## Setup Instructions for Packer

1. Clone the Repository

   First, clone the repository to your local machine.

2. Edit the `credentials.pkr.hcl` file

   Edit the `credentials.pkr.hcl` file to set the necessary credentials for your Proxmox environment.

3. Edit the `packer.pkr.hcl` file

   Edit the `packer.pkr.hcl` file to set the necessary variables for your Windows 11 VM.

4. Choice:

   - Run vmTemplating.sh: This script will run the build_proxmox.iso, packer validate, and build command automatically. The script is located in the `packer/proxmox/api` directory.
   - Run the build_proxmox.iso, packer validate, and build command directly in the terminal. You can find the commands in the `vmTemplating.sh` script. Or for you lazy people, here is the command:

     Change directory to the packer template directory:

     ```bash
     cd /root/TA-Automation/packer/proxmox/windows/win11_cloudbase-init
     ```

     Run the packer validate command:

     ```bash
     packer validate --var-file=./win11_cloudbase-init.pkvars.hcl --var-file=../scripts.pkvars.hcl --var-file=../../credentials.pkr.hcl .
     ```

     Run the packer build command:

     ```bash
     packer build --var-file=./win11_cloudbase-init.pkvars.hcl --var-file=../scripts.pkvars.hcl --var-file=../../credentials.pkr.hcl .
     ```

Potential improvements/changes:

- Edit the `Autounattend.xml` file to support more configurations, especially for better customization of the VM virtual hardware using virtio drivers.

Current limitations:

`Autounattend.xml` is not yet fully developed to support all configurations. It can only create a VM with default and disk and NIC and not using the virtio drivers at all because we need to install the driver manually for both of those virtual hardisk.