#!/bin/bash

# This script is used to create ISO files for Proxmox, because Proxmox only accepts ISO files and not floppy disks.

# Building an ISO for Windows 11 with cloudinit
# mkisofs is a utility that creates an ISO 9660 image from files on disk
echo "[+] Build iso windows 11 with cloudinit"
mkisofs -J -l -R -V "autounatend CD" -iso-level 4 -o ./iso/autounattend_win11_cloudbase-init.iso iso/win11_cloudinit
sha_autounattend_win11_cloudbaseInit=$(sha256sum ./iso/autounattend_win11_cloudbase-init.iso|cut -d ' ' -f1)
# Update the SHA-256 checksum in the packer variable file
echo "[+] update win11_cloudbase-init.pkvars.hcl"
sed -i "s/\"sha256:iso_autounattend_checksum\"/\"sha256:$sha_autounattend_win11_cloudbaseInit\"/g" win11_cloudbaseinit/win11_cloudbase-init.pkvars.hcl

# Check if the Cloudbase Init MSI installer exists
echo "[+] Check if CloudbaseInitSetup_Stable_x64.msi exist"
if [ ! -f ./iso/scripts/sysprep/CloudbaseInitSetup_Stable_x64.msi ]; then
  # If it doesn't exist, download it
  echo "[-] CloudbaseInitSetup_Stable_x64.msi not found"
  echo "[+] Downloading CloudbaseInitSetup_Stable_x64.msi"
  wget -O ./iso/scripts/sysprep/CloudbaseInitSetup_Stable_x64.msi https://www.cloudbase.it/downloads/CloudbaseInitSetup_Stable_x64.msi
else
  echo "[+] CloudbaseInitSetup_Stable_x64.msi exist"
fi

# Building an ISO for scripts
echo "[+] Build iso for scripts"
mkisofs -J -l -R -V "scripts CD" -iso-level 4 -o ./iso/scripts_cloudbase-init.iso scripts
sha_scripts_cloudbaseInit=$(sha256sum ./iso/scripts_cloudbase-init.iso|cut -d ' ' -f1)
# Update the SHA-256 checksum in the packer variable file
echo "[+] update scripts.pkvars.hcl"
sed -i "s/\"sha256:iso_scripts_checksum\"/\"sha256:$sha_scripts_cloudbaseInit\"/g" scripts.pkvars.hcl

# Check if the virtio-win ISO exists
echo "[+] Check if virtio-win.iso exist"
if [ ! -f /var/lib/vz/template/iso/virtio-win-0.1.240.iso ] || [ ! -f /var/lib/vz/template/iso/virtio-win-0.1.248.iso ]; then
  # If it doesn't exist, download it
  echo "[-] virtio-win.iso not found"
  echo "[+] Downloading virtio-win-0.1.248.iso"
  wget -O /var/lib/vz/template/iso/virtio-win-0.1.248.iso https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win-0.1.248.iso
  sha_virtio248=$(sha256sum /var/lib/vz/template/iso/virtio-win-0.1.248.iso|cut -d ' ' -f1)
  # Update the SHA-256 checksum in the packer variable file
  echo "[+] update win11_cloudbase-init.pkvars.hcl"
  sed -i "s/\"sha256:D5B5739CF297F0538D263E30678D5A09BBA470A7C6BCBD8DFF74E44153F16549\"/\"sha256:$sha_virtio248\"/g" win11_cloudbaseinit/win11_cloudbase-init.pkvars.hcl
else
  echo "[+] virtio-win.iso exist"
fi

# Script is done
echo "[+] Done"

# echo "scripts_withcloudinit.iso"
# sha256sum ./iso/scripts_withcloudinit.iso