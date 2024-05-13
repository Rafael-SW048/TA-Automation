# Proxmox Provider
# ---
# Initial Provider Configuration for Proxmox

terraform {
  required_version = ">= 1.8.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.53.1"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.1.0"
    }
  }
}

provider "proxmox" {

    endpoint = var.proxmox_api_url
    username = var.proxmox_api_token_id
    password = var.proxmox_api_token_password

    # (Optional) Skip TLS Verification
    insecure = var.proxmox_skip_tls_verify
}

resource "proxmox_virtual_environment_vm" "win11_cloudbase-init" {
  for_each = var.vms_config

  node_name   = var.proxmox_node
  pool_id     = var.proxmox_pool

  name = each.value.name
  description = each.value.desc

  operating_system {
    type = "win11"
  }

  cpu {
    cores   = each.value.cores
    sockets = 1
    type = each.value.cpu_type
  }

  memory {
    dedicated = each.value.memory
  }

  # Add a unique host PCI device for each VM
  dynamic "hostpci" {
    for_each = each.value.pci_device != "" ? [1] : []
    content {
      device = "hostpci0"
      id     = each.value.pci_device
    }
  }

  clone {
      node_name = var.proxmox_node
      vm_id = lookup(var.vm_template_id, each.value.clone, -1)
      full  = var.vm_full_clone
      retries = 2
  }

  agent {
    # read 'Qemu guest agent' section, change to true only when ready
    enabled = true
  }

  network_device {
    bridge  = var.network_bridge
    model   = var.network_model
  }

  audio_device {
    device = "ich9-intel-hda"
  }

  vga {
    memory = 256
    type = "virtio"
  }

  initialization {
    # datastore_id = var.storage
    # dns {
    #   servers = [each.value.dns]
    # }
    # ip_config {
    #   ipv4 {
    #     address = each.value.ip
    #     gateway = each.value.gateway
    #   }
    # }
  }

  provisioner "local-exec" {
    command = "./scripts/vm_ip-address_checker.sh ${self.vm_id} ${each.value.SID}"
    when    = create
  }

  

}

# resource "null_resource" "remote_exec" {
#   depends_on = [proxmox_virtual_environment_vm.win11_cloudbase-init]

#   for_each = var.vms_config

#   connection {
#     type     = "winrm"
#     user     = "admin"
#     password = "admin"
#     host     = file("${path.module}/vm_ip-address/ip-address_${each.value.SID}.txt")
#     # timeout  = "5m"
#   }

#   provisioner "remote-exec" {
#     # when = create
#     inline = [
#       "powershell.exe -File ${path.module}/rename_computer.ps1 -newName ${each.value.SID}"
#     ]
#   }
# }
