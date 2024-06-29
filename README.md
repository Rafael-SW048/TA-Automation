# Proxmox Setup Guide

This guide provides instructions for setting up Proxmox on your bare metal server and performing the initial setup.

## Step 1: Install Proxmox

To begin, install [Proxmox](https://www.proxmox.com/en/downloads/proxmox-virtual-environment/iso) on your bare metal server. You can follow the official Proxmox installation guide for detailed instructions.

## Step 2: Correct Proxmox Repositories

After installing Proxmox, it is important to correct the Proxmox repositories. You can do this by creating a file and adding the commands from the `PVE_RepoCorrection.sh` script, or by directly running the `PVE_RepoCorrection.sh` script if you have it.

> **Note:** The corrected Proxmox repositories provided in the `PVE_RepoCorrection.sh` script are intended for testing and development purposes only. They are not recommended for use in a production environment. Please exercise caution and consult the official Proxmox documentation for recommended repository configurations in production environments.

## Step 3: Run Initial Setup Script

Finally, execute the `PVE_initial_setup.sh` script to perform the initial setup of your Proxmox server.

For more detailed instructions on setting up Proxmox, refer to the individual setup guides for Terraform and Packer.
- [Terraform](terraform/proxmox/README.md)
- [Packer](packer/proxmox/README.md)