#!/bin/bash

# This script facilitates the creation of ISO files specifically tailored for Proxmox VE environments. Proxmox VE, a virtualization platform, requires ISO files for the installation of operating systems on virtual machines. This script automates the process of generating these ISO files, including the downloading of necessary files, creation of ISOs with custom configurations, and updating checksums for verification. It supports creating ISOs with pre-included applications and drivers, such as Steam, ZeroTier One, Cloudflare WARP, and NVIDIA drivers, as well as Cloudbase Init for Windows automation. Additionally, it handles the creation of ISOs containing scripts for Cloudbase Init and checks for the presence of the VirtIO drivers ISO, downloading it if missing. The script is designed to be run in environments where automated, repeatable setup of virtual machines is required, streamlining the process of preparing ISO files with all necessary components for deployment in Proxmox VE.

check_and_download() {
  local filename=$1
  local url=$2
  echo "[+] Check if $filename exists"
  if [ ! -f "$script_dir/scripts/sysprep/apps/$filename" ]; then
    echo "[-] $filename not found"
    echo "[+] Downloading $filename"
    wget "$url" -P "$script_dir/scripts/sysprep/apps/" && echo "[+] Downloading $filename done"
  else
    echo "[+] $filename exist"
  fi
}

create_iso() {
  local iso_name=$1
  local iso_dir=$2
  local iso_source=$3
  local iso_label=$4
  local pkvars_file=$5
  echo "[+] Building ISO $iso_name"
  echo "[+] Checking if $iso_name already exists"
  if [ -f "$iso_dir/$iso_name" ]; then
    echo "[-] $iso_name already exists"
    if [ -z "$replace_choice" ]; then
      read -p "Do you want to replace the existing $iso_name with a new one? (y/n): " replace_choice
    fi
    replace_choice=$(echo $replace_choice | tr '[:upper:]' '[:lower:]')  # Convert to lowercase
    if [ "$replace_choice" == "y" ] || [ "$replace_choice" == "yes" ]; then
      echo "[+] Creating temporary ISO file"
      mkisofs -J -l -R -V "$iso_label CD" -iso-level 4 -o "$iso_dir/temp.iso" "$iso_source"
      echo "[+] Calculating checksum of the temporary ISO file"
      sha_temp=$(sha256sum "$iso_dir/temp.iso" | cut -d ' ' -f1)
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
    echo "[+] Updating $pkvars_file"
    sed -i "/iso_autounattend_checksum =/s/\"sha256:.*\"/\"sha256:$sha_iso\"/g" "$pkvars_file"
  fi
}

script_dir=$(dirname "$0")

replace_choice=$1

echo "----------------------------------------"

check_and_download "SteamSetup.exe" "https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe"
check_and_download "ZeroTier One.msi" "https://download.zerotier.com/dist/ZeroTier%20One.msi?_gl=1*1snqeb8*_up*MQ..*_ga*MTYxNDY0ODg4MC4xNzE1MjM2Njc5*_ga_6TEJNMZS6N*MTcxNTIzNjY3Ni4xLjAuMTcxNTIzNjY3Ni4wLjAuMA..*_ga_NX38HPVY1Z*MTcxNTIzNjY3Ni4xLjAuMTcxNTIzNjY3Ni4wLjAuMA.."
check_and_download "Cloudflare_WARP_2024.3.409.0.msi" "https://1111-releases.cloudflareclient.com/windows/Cloudflare_WARP_Release-x64.msi"
check_and_download "552.44-desktop-win10-win11-64bit-international-dch-whql.exe" "https://us.download.nvidia.com/Windows/552.44/552.44-desktop-win10-win11-64bit-international-dch-whql.exe"

echo "----------------------------------------"

create_iso "autounattend_win11_cloudbase-init.iso" "/var/lib/vz/template/iso" "$script_dir/iso/win11_cloudbase-init" "autounatend CD" "$script_dir/win11_cloudbase-init/win11_cloudbase-init.pkvars.hcl"

echo "----------------------------------------"

echo "[+] Check if CloudbaseInitSetup_1_1_4_x64.msi exist"
if [ ! -f $script_dir/scripts/sysprep/CloudbaseInitSetup_1_1_4_x64.msi ]; then
  echo "[-] CloudbaseInitSetup_1_1_4_x64.msi not found"
  echo "[+] Downloading CloudbaseInitSetup_1_1_4_x64.msi"
  wget https://cloudbase.it/downloads/CloudbaseInitSetup_1_1_4_x64.msi -P $script_dir/scripts/sysprep/ && echo "[+] Downloading CloudbaseInitSetup_1_1_4_x64.msi done"
else
  echo "[+] CloudbaseInitSetup_1_1_4_x64.msi exist"
fi

echo "----------------------------------------"

create_iso "scripts_cloudbase-init.iso" "/var/lib/vz/template/iso" "$script_dir/scripts" "scripts CD" "$script_dir/scripts.pkvars.hcl"

echo "----------------------------------------"

echo "[+] Check if virtio-win.iso exist"
if [ ! -f /var/lib/vz/template/iso/virtio-win-0.1.248.iso ]; then
  echo "[-] virtio-win.iso not found"
  echo "[+] Downloading virtio-win-0.1.248.iso"
  wget https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.248-1/virtio-win-0.1.248.iso -P /var/lib/vz/template/iso/ && echo "[+] Downloading virtio-win-0.1.248.iso done"
  sha_virtio248=$(sha256sum /var/lib/vz/template/iso/virtio-win-0.1.248.iso|cut -d ' ' -f1)
  echo "[+] Updating win11_cloudbase-init.pkvars.hcl"
  sed -i "/iso_virtio_checksum =/s/\"sha256:.*\"/\"sha256:$sha_virtio248\"/g" $script_dir/win11_cloudbase-init/win11_cloudbase-init.pkvars.hcl
else
  echo "[+] virtio-win.iso exist"
fi

echo "----------------------------------------"

echo "[+] Done"
echo "----------------------------------------"
