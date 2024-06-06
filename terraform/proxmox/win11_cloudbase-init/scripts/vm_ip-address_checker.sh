#!/bin/bash

# Get the VM ID and SID from the command-line arguments
vm_id=$1
SID=$2

# qm stop $vm_id

# sleep 3

# qm start $vm_id

# sleep 20

# Get the JSON output
json_output=$(pvesh get /nodes/pve/qemu/$vm_id/agent/network-get-interfaces -output-format=json-pretty)
# echo "JSON Output: $json_output"

# Parse the JSON output and extract the non-loopback IP address
ip_address=$(echo $json_output | jq -r '.result[] | select(.name == "Ethernet") | .["ip-addresses"][] | select(.["ip-address-type"] == "ipv4" and .["ip-address"] != "127.0.0.1") | .["ip-address"]')

# Create the directory if it doesn't exist
mkdir -p vm_ip-address

pwd

# Write the IP address and SID to a file
echo "$SID" > "vm_ip-address/$ip_address-$vm_id.txt"