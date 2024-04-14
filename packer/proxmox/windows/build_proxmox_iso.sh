#!/bin/bash

# This script is used to create ISO files for Proxmox, because Proxmox only accepts ISO files and not floppy disks.

# Building an ISO for Windows 11 with cloudbase init

# Get the directory of the script
script_dir=$(dirname "$0")

# Get the user input from the command line
replace_choice1=$1
replace_choice2=$replace_choice1

echo "----------------------------------------"

# mkisofs is a utility that creates an ISO 9660 image from files on disk
echo "[+] Build iso windows 11 with cloudbase init"
# Check if the ISO file already exists
echo "[+] Checking if autounattend ISO file already exists"
if [ -f $script_dir/iso/autounattend_win11_cloudbase-init.iso ]; then
  echo "[-] Autounattend ISO file already exists"
  if [ -z "$replace_choice1" ]; then
    read -p "Do you want to replace the existing autounattend ISO with a new one? (y/n): " replace_choice1
  fi
  replace_choice1=$(echo $replace_choice1 | tr '[:upper:]' '[:lower:]')  # Convert to lowercase
  if [ "$replace_choice1" == "y" ] || [ "$replace_choice1" == "yes" ]; then
    # Create a temporary ISO file
    echo "[+] Creating temporary autounattend ISO file"
    mkisofs -J -l -R -V "autounatend CD" -iso-level 4 -o $script_dir/iso/temp.iso $script_dir/iso/win11_cloudbase-init
    # Calculate the checksum of the temporary ISO file
    echo "[+] Calculating checksum of the temporary autounattend ISO file"
    sha_temp=$(sha256sum $script_dir/iso/temp.iso | cut -d ' ' -f1)
    # Replace the existing ISO with the new one
    echo "[+] Replacing the existing autounattend ISO with the new one"
    mv $script_dir/iso/temp.iso $script_dir/iso/autounattend_win11_cloudbase-init.iso
    echo "[+] Updating win11_cloudbase-init.pkvars.hcl"
    sed -i "/iso_autounattend_checksum =/s/\"sha256:.*\"/\"sha256:$sha_temp\"/g" $script_dir/win11_cloudbase-init/win11_cloudbase-init.pkvars.hcl
  else
    echo "[+] Keeping the existing autounattend ISO"
  fi
else
  echo "[+] ISO file does not exist"
  mkisofs -J -l -R -V "autounatend CD" -iso-level 4 -o $script_dir/iso/autounattend_win11_cloudbase-init.iso $script_dir/iso/win11_cloudbase-init
  sha_autounattend_win11_cloudbaseInit=$(sha256sum $script_dir/iso/autounattend_win11_cloudbase-init.iso|cut -d ' ' -f1)
  # Update the SHA-256 checksum in the packer variable file
  echo "[+] Updating win11_cloudbase-init.pkvars.hcl"
  sed -i "/iso_autounattend_checksum =/s/\"sha256:.*\"/\"sha256:$sha_autounattend_win11_cloudbaseInit\"/g" $script_dir/win11_cloudbase-init/win11_cloudbase-init.pkvars.hcl
fi

echo "----------------------------------------"

# Check if the Cloudbase Init MSI installer exists
echo "[+] Check if CloudbaseInitSetup_1_1_4_x64.msi exist"
if [ ! -f $script_dir/scripts/sysprep/CloudbaseInitSetup_1_1_4_x64.msi ]; then
  # If it doesn't exist, download it
  echo "[-] CloudbaseInitSetup_1_1_4_x64.msi not found"
  echo "[+] Downloading CloudbaseInitSetup_1_1_4_x64.msi"
  wget https://cloudbase.it/downloads/CloudbaseInitSetup_1_1_4_x64.msi -P $script_dir/scripts/sysprep/ && echo "[+] Downloading CloudbaseInitSetup_1_1_4_x64.msi done"
else
  echo "[+] CloudbaseInitSetup_1_1_4_x64.msi exist"
fi

echo "----------------------------------------"

# Building an ISO for scripts
echo "[+] Build iso for scripts"
# Check if the scripts_cloudbase-init.iso already exists
echo "[+] Checking if scripts_cloudbase-init.iso already exists"
if [ -f $script_dir/iso/scripts_cloudbase-init.iso ]; then
  echo "[-] scripts_cloudbase-init.iso already exists"
  if [ -z "$replace_choice2" ]; then
    read -p "Do you want to replace the existing scripts ISO with a new one? (y/n): " replace_choice2
  fi
  replace_choice2=$(echo $replace_choice2 | tr '[:upper:]' '[:lower:]')  # Convert to lowercase
  if [ "$replace_choice2" == "y" ] || [ "$replace_choice2" == "yes" ]; then
    # Create a temporary ISO file for comparison
    echo "[+] Creating temporary ISO file"
    mkisofs -J -l -R -V "scripts CD" -iso-level 4 -o $script_dir/iso/temp.iso $script_dir/scripts
    # Calculate the checksum of the temporary ISO file
    echo "[+] Calculating checksum of the temporary ISO file"
    sha_temp=$(sha256sum $script_dir/iso/temp.iso | cut -d ' ' -f1)
    # Replace the existing ISO with the new one
    echo "[+] Replacing the existing scripts ISO with the new one"
    mv $script_dir/iso/temp.iso $script_dir/iso/scripts_cloudbase-init.iso
    echo "[+] Updating scripts.pkvars.hcl"
    sed -i "/iso_scripts_checksum =/s/\"sha256:.*\"/\"sha256:$sha_temp\"/g" $script_dir/scripts.pkvars.hcl
  else
    echo "[+] Keeping the existing scripts ISO"
  fi
else
  echo "[+] scripts_cloudbase-init.iso does not exist"
  mkisofs -J -l -R -V "scripts CD" -iso-level 4 -o $script_dir/iso/scripts_cloudbase-init.iso $script_dir/scripts
  sha_scripts_cloudbaseInit=$(sha256sum $script_dir/iso/scripts_cloudbase-init.iso|cut -d ' ' -f1)
  # Update the SHA-256 checksum in the packer variable file
  echo "[+] Updating scripts.pkvars.hcl"
  sed -i "/iso_scripts_checksum =/s/\"sha256:.*\"/\"sha256:$sha_scripts_cloudbaseInit\"/g" $script_dir/scripts.pkvars.hcl
fi

echo "----------------------------------------"

# Check if the virtio-win ISO exists
echo "[+] Check if virtio-win.iso exist"
if [ ! -f /var/lib/vz/template/iso/virtio-win-0.1.248.iso ]; then
  # If it doesn't exist, download it
  echo "[-] virtio-win.iso not found"
  echo "[+] Downloading virtio-win-0.1.248.iso"
  wget https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.248-1/virtio-win-0.1.248.iso -P /var/lib/vz/template/iso/ && echo "[+] Downloading virtio-win-0.1.248.iso done"
  sha_virtio248=$(sha256sum /var/lib/vz/template/iso/virtio-win-0.1.248.iso|cut -d ' ' -f1)
  # Update the SHA-256 checksum in the packer variable file
  echo "[+] Updating win11_cloudbase-init.pkvars.hcl"
  sed -i "/iso_virtio_checksum =/s/\"sha256:.*\"/\"sha256:$sha_virtio248\"/g" $script_dir/win11_cloudbase-init/win11_cloudbase-init.pkvars.hcl
else
  echo "[+] virtio-win.iso exist"
fi

echo "----------------------------------------"

# Script is done
echo "[+] Done"
echo "----------------------------------------"

# echo "scripts_withcloudinit.iso"
# sha256sum ./iso/scripts_withcloudinit.iso