# Proxmox Setup Guide

This guide will help you set up Proxmox on your bare metal server and perform initial setup.

## Step 1: Install Proxmox

First, you need to install Proxmox on your bare metal server. You can follow the official Proxmox installation guide for this.

## Step 2: Correct Proxmox Repositories

After installing Proxmox, you need to correct the Proxmox repositories. You can do this by creating a file and adding the commands from `PVE_RepoCorrection.sh` to it, or you can run the `PVE_RepoCorrection.sh` script directly if you have it.

> **Note:** The corrected Proxmox repositories provided in the `PVE_RepoCorrection.sh` script are not advised to be used in a production environment. They are intended for testing and development purposes only. Please use caution and consult the official Proxmox documentation for recommended repository configurations in production environments.

## Step 3: Run Initial Setup Script

Finally, you need to run the `PVE_inital_setup.sh` script. This script will perform the initial setup of your Proxmox server.

[docs for terraform](terraform/README.md)
[docs for packer](packer/README.md)