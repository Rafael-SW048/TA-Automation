#!/bin/bash

# transform files into iso, because proxmox only accept iso and no floppy A:\

echo "[+] Build iso windows 11 with cloudinit"
mkisofs -J -l -R -V "autounatend CD" -iso-level 4 -o ./iso/autounattend_win11_cloudbase-init.iso iso/win11_cloudinit
sha_autounattend_win11_cloudbaseInit=$(sha256sum ./iso/autounattend_win11_cloudbase-init.iso|cut -d ' ' -f1)
echo "[+] update win11_cloudbase-init.pkvars.hcl"
sed -i "s/\"sha256:iso_autounattend_checksum\"/\"sha256:$sha_autounattend_win11_cloudbaseInit\"/g" win11_cloudbaseinit/win11_cloudbase-init.pkvars.hcl

echo "[+] Check if CloudbaseInitSetup_Stable_x64.msi exist"
if [ ! -f ./iso/scripts/sysprep/CloudbaseInitSetup_Stable_x64.msi ]; then
  echo "[-] CloudbaseInitSetup_Stable_x64.msi not found"
  echo "[+] Downloading CloudbaseInitSetup_Stable_x64.msi"
  wget -O ./iso/scripts/sysprep/CloudbaseInitSetup_Stable_x64.msi https://www.cloudbase.it/downloads/CloudbaseInitSetup_Stable_x64.msi
else
  echo "[+] CloudbaseInitSetup_Stable_x64.msi exist"
fi

echo "[+] Build iso for scripts"
mkisofs -J -l -R -V "scripts CD" -iso-level 4 -o ./iso/scripts_cloudbase-init.iso scripts
sha_scripts_cloudbaseInit=$(sha256sum ./iso/scripts_cloudbase-init.iso|cut -d ' ' -f1)
echo "[+] update scripts.pkvars.hcl"
sed -i "s/\"sha256:iso_scripts_checksum\"/\"sha256:$sha_scripts_cloudbaseInit\"/g" scripts.pkvars.hcl

echo "[+] Check if virtio-win.iso exist"
if [ ! -f /var/lib/vz/template/iso/virtio-win-0.1.240.iso ] || [ ! -f /var/lib/vz/template/iso/virtio-win-0.1.248.iso ]; then
  echo "[-] virtio-win.iso not found"
  echo "[+] Downloading virtio-win-0.1.248.iso"
  wget -O /var/lib/vz/template/iso/virtio-win-0.1.248.iso https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win-0.1.248.iso
else
  echo "[+] virtio-win.iso exist"
fi

echo "[+] Done"

# echo "scripts_withcloudinit.iso"
# sha256sum ./iso/scripts_withcloudinit.iso