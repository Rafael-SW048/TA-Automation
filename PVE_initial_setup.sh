#!/bin/bash

# Install ZeroTier
curl -s https://install.zerotier.com | bash

# Check ZeroTier status
zerotier_status=$(zerotier-cli status)

# Extract the status (ONLINE, etc.)
status=$(echo "$zerotier_status" | cut -d ' ' -f -1)

# Check if ZeroTier is online
if [ "$status" == "ONLINE" ]; then
    # Join the ZeroTier network based on the defined network ID
    ZEROTIER_NETWORK_ID="9e1948db63d35842"
    zerotier-cli join "$ZEROTIER_NETWORK_ID"
fi

# # Install Cloudflare VPN (Warp) IF your network is blocking ZeroTier
# curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
# echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ bookworm main" | tee /etc/apt/sources.list.d/cloudflare-client.list
# apt-get update && apt-get install -y cloudflare-warp

# Install Packer
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com bookworm main" -y
apt-get update && apt-get install packer -y

packer plugins install github.com/hashicorp/proxmox
