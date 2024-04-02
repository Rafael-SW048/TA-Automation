#!/bin/bash

# Define the filename of the sources.list file and ceph.list file
SOURCES_LIST_FILE="/etc/apt/sources.list"
CEPH_LIST_FILE="/etc/apt/sources.list.d/ceph.list"

# Define the new content for sources.list file
NEW_CONTENT_SOURCES=$(cat <<EOF
deb http://deb.debian.org/debian bookworm main contrib
deb http://deb.debian.org/debian bookworm-updates main contrib

# security updates
deb http://security.debian.org/debian-security bookworm-security main contrib

# Proxmox VE No-Subscription Repository
# This repository seems to be duplicated. Remove one of the lines.
deb http://ftp.debian.org/debian bookworm main contrib
deb http://ftp.debian.org/debian bookworm-updates main contrib

# Proxmox VE pve-no-subscription repository provided by proxmox.com,
# NOT recommended for production use
deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription
EOF
)

# Define the new content for ceph.list file
NEW_CONTENT_CEPH=$(cat <<EOF
# Previous entries have been commented out
# Add new entries below

# New entry for Proxmox ceph-reef and ceph-quincy repositories
deb http://download.proxmox.com/debian/ceph-reef bookworm no-subscription
deb http://download.proxmox.com/debian/ceph-quincy bookworm no-subscription
EOF
)

# Backup the original files
cp "$SOURCES_LIST_FILE" "$SOURCES_LIST_FILE.bak"
cp "$CEPH_LIST_FILE" "$CEPH_LIST_FILE.bak"

# Comment out existing entries in ceph.list file
sed -i '/^[^#]/ s/^/#/' "$CEPH_LIST_FILE"

# Write the new content to the files
echo "$NEW_CONTENT_SOURCES" > "$SOURCES_LIST_FILE"
echo "$NEW_CONTENT_CEPH" > "$CEPH_LIST_FILE"

echo "Modified $SOURCES_LIST_FILE and $CEPH_LIST_FILE successfully."

# Update package lists
apt-get update

# Upgrade installed packages
apt-get upgrade -y
apt-get install lsb-release -y
apt-get install software-properties-common -y

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

# Install Cloudflare VPN (Warp)
curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ bookworm main" | tee /etc/apt/sources.list.d/cloudflare-client.list
apt-get update && apt-get install -y cloudflare-warp

# Install Packer
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com bookworm main" -y
apt-get update && apt-get install packer -y

packer plugins install github.com/hashicorp/proxmox
