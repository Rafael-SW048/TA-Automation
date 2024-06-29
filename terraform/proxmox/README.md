# Overview
This API allows for managing virtual machines (VMs) including creation, deletion, and querying available templates. It is built using Flask and integrates with Terraform to handle VM provisioning on a Proxmox environment.

**Disclaimer: This project is a proof of concept and should not be used in production environments. Use at your own risk.**

# Prerequisites
Before running the code, ensure you have the following installed on your system:

- Python 3.11 or higher[https://www.python.org/downloads/]
- Terraform[https://www.terraform.io/downloads.html]
- Proxmox VE (Virtual Environment) version 8.1 or higher[https://www.proxmox.com/proxmox-ve]

# Setup Instructions for Terraform
### 1. Clone the Repository
  First, clone the repository to your local machine:
  ```
  git clone --branch remote https://github.com/Rafael-SW048/TA-Automation.git
  cd Terraform/Proxmox/win11_cloudbase-init/scripts
  ```

### 2. Configure Environment Variables or Config.py
  Ensure you have the necessary environment variables set up. You can create a `.env` file in the root directory with the following content (replace the values with your own):
  ```
  PRIMARY_NODE_URL=http://10.11.1.181:6969
  SECONDARY_NODE_URL=http://10.11.1.182:6969
  PORT=6969
  ```
  Alternatively, you can modify the `config.py` file in the `scripts/version1` directory to set the environment variables.

### 3. Edit the credentials.tfvars file
  Edit the `credentials.tfvars` file to set the necessary credentials for your Proxmox environment.

### 4. Create the templates VM
  You can use the packer repository  to create the templates VMs or create them manually.
  
  **Note:** The packer repository is not fully developed yet.

### 5. Start the Server
  To start the API server, simply run the `start.sh` script:
  ```
  ./start.sh
  ```
  This script will handle setting up the environment and starting the Flask server.

### 6. Access the API
  Once the server is running, you can access the API documentation via Swagger UI at:
  ```
  http://<your-server-ip>:6969/api/docs/v1
  ```
  or just:
  ```
  http://<your-server-ip>:6969/v1
  ```

README.md:
- [Main README](../../README.md)
- [Packer](../../packer/README.md)