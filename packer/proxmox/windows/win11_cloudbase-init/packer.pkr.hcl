# Packer Configuration for Windows 11

# Packer plugin for Proxmox
packer {
  required_plugins {
    name = {
      version = "~> 1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-iso" "win11-cloudbase-init" {
    # Proxmox Connection Settings
    proxmox_url = "${var.proxmox_api_url}"
    username = "${var.proxmox_api_token_id}"
    token = "${var.proxmox_api_token_secret}"
    node = "${var.proxmox_node}"
    pool = "${var.proxmox_pool}"
    # (Optional) Skip TLS Verification
    insecure_skip_tls_verify = "${var.proxmox_skip_tls_verify}"

    # VM General Settings
    vm_name = "${var.vm_name}"
    template_description = "${var.template_description}"

    iso_file = "${var.iso_file}"
    iso_checksum = "${var.iso_checksum}"
    unmount_iso = true

    # VM System Settings
    qemu_agent = true
    
    memory = "${var.vm_memory}"
    cores = "${var.vm_cpu_cores}"
    sockets = "${var.vm_sockets}"
    os = "${var.os}"
    // bios = "ovmf"

    network_adapters {
            model = "e1000"
            bridge = "vmbr0"
            // vlan_tag = "102"
            firewall = "false"
    }

    # VM Hard Disk Settings
    disks {
        type = "sata"
        disk_size = "${var.vm_disk_size}"
        storage_pool = "${var.proxmox_vm_storage}"
        format = "raw"
    }

    additional_iso_files {
        device = "sata3"
        iso_file = "${var.iso_autounattend}"
        iso_checksum = "${var.iso_autounattend_checksum}"
        unmount = true
    }

    additional_iso_files {
        device = "sata4"
        iso_file = "${var.iso_virtio}"
        iso_checksum = "${var.iso_virtio_checksum}"
        unmount = true
    }

    additional_iso_files {
        device = "sata5"
        iso_file = "${var.iso_scripts}"
        iso_checksum = "${var.iso_scripts_checksum}"
        unmount = true
    }

    boot_command = [
        "<wait30><tab><wait><enter>"
    ]

    cloud_init = true
    cloud_init_storage_pool = "${var.proxmox_iso_storage}"
    communicator = "winrm"
    winrm_username = "${var.winrm_username}"
    winrm_password = "${var.winrm_password}"
    winrm_insecure = true
    winrm_use_ssl = true
    winrm_no_proxy = true
    winrm_timeout = "120m"
    task_timeout = "40m"
}

build {
    name = "win11-cloudbase-init"
    sources = ["source.proxmox-iso.win11-cloudbase-init"]

    // provisioner "powershell" {
    //     elevated_user     = "admin"
    //     elevated_password = "admin"
    //     scripts           = ["${path.root}/../scripts/sysprep/cloudbase-init-p1.ps1"]
    // }

    provisioner "powershell" {
        elevated_user     = "admin"
        elevated_password = "admin"
        pause_before      = "120s"
        scripts           = ["${path.root}/../scripts/sysprep/cloudbase-init-p2.ps1"]
    }
}