#!/bin/bash

# Define the filename of the sources.list file and ceph.list file
SOURCES_LIST_FILE="/etc/apt/sources.list"
CEPH_LIST_FILE="/etc/apt/sources.list.d/ceph.list"
ENTERPRISE_REPO_LIST_FILE="/etc/apt/sources.list.d/pve-enterprise.list"

# Define the new content for sources.list file
NEW_CONTENT_SOURCES=$(cat <<EOF
deb http://deb.debian.org/debian bookworm main contrib
deb http://deb.debian.org/debian bookworm-updates main contrib

# security updates
deb http://security.debian.org/debian-security bookworm-security main contrib

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
sed -i '/^[^#]/ s/^/#/' "$SOURCES_LIST_FILE"
sed -i '/^[^#]/ s/^/#/' "$CEPH_LIST_FILE"
sed -i '/^[^#]/ s/^/#/' "$ENTERPRISE_REPO_LIST_FILE"

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
