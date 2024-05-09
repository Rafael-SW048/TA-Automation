#!/bin/bash

# This script is used to create ISO files for Proxmox, because Proxmox only accepts ISO files and not floppy disks.

# Function to check and download file
check_and_download() {
  local filename=$1
  local url=$2
  echo "[+] Check if $filename exists"
  if [ ! -f "$script_dir/scripts/sysprep/app/$filename" ]; then
    # If it doesn't exist, download it
    echo "[-] $filename not found"
    echo "[+] Downloading $filename"
    wget "$url" -P "$script_dir/scripts/sysprep/app/" && echo "[+] Downloading $filename done"
  else
    echo "[+] $filename exist"
  fi
}

# Function to create ISO
create_iso() {
  local iso_name=$1
  local iso_dir=$2
  local iso_source=$3
  local iso_label=$4
  local pkvars_file=$5
  echo "[+] Building ISO $iso_name"
  # Check if the ISO file already exists
  echo "[+] Checking if $iso_name already exists"
  if [ -f "$iso_dir/$iso_name" ]; then
    echo "[-] $iso_name already exists"
    if [ -z "$replace_choice" ]; then
      read -p "Do you want to replace the existing $iso_name with a new one? (y/n): " replace_choice
    fi
    replace_choice=$(echo $replace_choice | tr '[:upper:]' '[:lower:]')  # Convert to lowercase
    if [ "$replace_choice" == "y" ] || [ "$replace_choice" == "yes" ]; then
      # Create a temporary ISO file
      echo "[+] Creating temporary ISO file"
      mkisofs -J -l -R -V "$iso_label CD" -iso-level 4 -o "$iso_dir/temp.iso" "$iso_source"
      # Calculate the checksum of the temporary ISO file
      echo "[+] Calculating checksum of the temporary ISO file"
      sha_temp=$(sha256sum "$iso_dir/temp.iso" | cut -d ' ' -f1)
      # Replace the existing ISO with the new one
      echo "[+] Replacing the existing $iso_name with the new one"
      mv "$iso_dir/temp.iso" "$iso_dir/$iso_name"
      echo "[+] Updating $pkvars_file"
      sed -i "/iso_autounattend_checksum =/s/\"sha256:.*\"/\"sha256:$sha_temp\"/g" "$pkvars_file"
    else
      echo "[+] Keeping the existing $iso_name"
    fi
  else
    echo "[+] $iso_name does not exist"
    mkisofs -J -l -R -V "$iso_label CD" -iso-level 4 -o "$iso_dir/$iso_name" "$iso_dir/iso"
    sha_iso=$(sha256sum "$iso_dir/$iso_name" | cut -d ' ' -f1)
    # Update the SHA-256 checksum in the packer variable file
    echo "[+] Updating $pkvars_file"
    sed -i "/iso_autounattend_checksum =/s/\"sha256:.*\"/\"sha256:$sha_iso\"/g" "$pkvars_file"
  fi
}

# Get the directory of the script
script_dir=$(dirname "$0")

# Get the user input from the command line
replace_choice=$1

echo "----------------------------------------"

# Check and download additional files
check_and_download "SteamSetup.exe" "https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe"
check_and_download "ZeroTier One.msi" "https://download.zerotier.com/dist/ZeroTier%20One.msi?_gl=1*1snqeb8*_up*MQ..*_ga*MTYxNDY0ODg4MC4xNzE1MjM2Njc5*_ga_6TEJNMZS6N*MTcxNTIzNjY3Ni4xLjAuMTcxNTIzNjY3Ni4wLjAuMA..*_ga_NX38HPVY1Z*MTcxNTIzNjY3Ni4xLjAuMTcxNTIzNjY3Ni4wLjAuMA.."
check_and_download "Cloudflare_WARP_2024.3.409.0.msi" "https://1111-releases.cloudflareclient.com/windows/Cloudflare_WARP_Release-x64.msi"
check_and_download "552.22-desktop-win10-win11-64bit-international-dch-whql.exe" "https://us.download.nvidia.com/Windows/552.22/552.22-desktop-win10-win11-64bit-international-dch-whql.exe"

echo "----------------------------------------"

# Build ISO for Windows 11 with cloudbase init
create_iso "autounattend_win11_cloudbase-init.iso" "/var/lib/vz/template/iso" "$script_dir/iso/win11_cloudbase-init" "autounatend CD" "$script_dir/win11_cloudbase-init/win11_cloudbase-init.pkvars.hcl"

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

# Build ISO for scripts
  local iso_name=$1
  local iso_dir=$2
  local iso_source=$3
  local iso_label=$4
  local pkvars_file=$5
create_iso "scripts_cloudbase-init.iso" "/var/lib/vz/template/iso" "$script_dir/scripts" "scripts CD" "$script_dir/scripts.pkvars.hcl"

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