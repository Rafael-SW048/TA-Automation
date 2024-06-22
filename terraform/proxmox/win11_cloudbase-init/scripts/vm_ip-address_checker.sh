#!/bin/bash

# Get the VM ID and SID from the command-line arguments
vm_id=$1
SID=$2
username=$3

# Define retry parameters
max_retries=20
retry_delay=5  # seconds
retries=0

# Loop until a valid IP address is obtained or maximum retries are reached
while [[ $retries -lt $max_retries ]]; do
    # Get the JSON output
    json_output=$(pvesh get /nodes/pve/qemu/$vm_id/agent/network-get-interfaces -output-format=json-pretty)

    # Parse the JSON output and extract the non-loopback IP address
    ip_address=$(echo $json_output | jq -r '.result[] | select(.name == "Ethernet") | .["ip-addresses"][] | select(.["ip-address-type"] == "ipv4" and .["ip-address"] != "127.0.0.1") | .["ip-address"]')

    # Check if the IP address is empty or does not start with "10.11.1"
    if [[ -z "$ip_address" || ! "$ip_address" =~ ^10\.11\.1 ]]; then
        ((retries++))
        echo "Retry $retries: IP address is empty or does not start with '10.11.1'. Retrying in $retry_delay seconds..."
        sleep $retry_delay
    else
        # Output the IP address
        echo "IP Address: $ip_address"

        # Create the directory if it doesn't exist
        mkdir -p vm_ip-address

        # Write the IP address and SID to a file
        echo "$SID" > "vm_ip-address/$ip_address-$vm_id.txt"

        # Append the username to the file
        echo "$username" >> "vm_ip-address/$ip_address-$vm_id.txt"
        
        # Exit the loop since a valid IP address is obtained
        break
    fi
done