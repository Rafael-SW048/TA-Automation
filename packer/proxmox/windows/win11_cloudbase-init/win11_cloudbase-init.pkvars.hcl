vm_name = "Win11x64-VM-template-cloudbaseInit-raw-NoSysPrep"
template_description = "Windows 11 64-bit Pro template with cloudbase-Init installed built with Packer"
iso_file = "local:iso/Windows_11_Pro_23H2_Build_22631.2715__No_TPM_Required__Preactivated.iso"
iso_checksum = "sha256:C299F39A120EFAAEAFC4802C854CD67634643205D8272A4CF16B649277C07A12"
iso_virtio = "local:iso/virtio-win-0.1.248.iso"
iso_virtio_checksum = "sha256:d5b5739cf297f0538d263e30678d5a09bba470a7c6bcbd8dff74e44153f16549"
iso_autounattend = "local:iso/autounattend_win11_cloudbase-init.iso"
iso_autounattend_checksum = "sha256:63949c3c092a5a75352f254bc68a465459c5a8f1911bad8ac15fb7675fc90ada"
vm_cpu_cores = "6"
vm_memory = "8192"
vm_disk_size = "512G"
proxmox_vm_storage = "pve-ssd"
vm_sockets = "1"
os = "win11"

winrm_username = "admin"
winrm_password = "admin"
