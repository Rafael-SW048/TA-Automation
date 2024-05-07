#!/bin/bash

# Function to handle errors
handle_error() {
    echo "Error occurred: $1"
    exit 1
}

# # Install ZeroTier
curl -s https://install.zerotier.com | bash || handle_error "ZeroTier installation failed"

# # Check ZeroTier status IF your host is using private network
zerotier_status=$(zerotier-cli status) || handle_error "Failed to get ZeroTier status"

# # Extract the status (ONLINE, etc.)
status=$(echo "$zerotier_status" | cut -d ' ' -f -1)

# # Check if ZeroTier is online
if [ "$status" == "ONLINE" ]; then
    # Join the ZeroTier network based on the defined network ID
    ZEROTIER_NETWORK_ID="9e1948db63d35842"
    zerotier-cli join "$ZEROTIER_NETWORK_ID" || handle_error "Failed to join ZeroTier network"
fi

# # Install Cloudflare VPN (Warp) IF your network is blocking ZeroTier
curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg || handle_error "Failed to download Cloudflare VPN public key"
echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ bookworm main" | tee /etc/apt/sources.list.d/cloudflare-client.list || handle_error "Failed to add Cloudflare VPN repository"
apt-get update && apt-get install -y cloudflare-warp || handle_error "Failed to install Cloudflare VPN"

# # Connect to warp
warp-cli registration new || handle_error "Failed to register with Cloudflare VPN"
warp-cli connect || handle_error "Failed to connect to Cloudflare VPN"
curl https://www.cloudflare.com/cdn-cgi/trace/ || handle_error "Failed to verify Cloudflare VPN connection"

# # Install Packer
apt-get update && apt-get install -y gnupg software-properties-common || handle_error "Failed to install prerequisite packages for Packer"
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - || handle_error "Failed to add HashiCorp GPG key"
apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com bookworm main" -y || handle_error "Failed to add HashiCorp repository"
apt-get update && apt-get install packer -y || handle_error "Failed to install Packer"
# packer plugins install github.com/hashicorp/proxmox || handle_error "Failed to install Packer plugin for Proxmox"

# # Install Terraform
apt-get update && apt-get install -y gnupg software-properties-common || handle_error "Failed to install prerequisite packages for Terraform"
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null || handle_error "Failed to download and add HashiCorp GPG key"
gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint || handle_error "Failed to verify HashiCorp GPG key"
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list || handle_error "Failed to add HashiCorp repository"
apt-get update && apt-get install terraform -y || handle_error "Failed to install Terraform"

echo "Script execution completed successfully."
