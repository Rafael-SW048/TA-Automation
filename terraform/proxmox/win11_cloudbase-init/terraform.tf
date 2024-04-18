# Proxmox Provider
# ---
# Initial Provider Configuration for Proxmox

terraform {

    required_version = ">= 1.8.0"

    required_providers {
        proxmox = {
            source = "bpg/proxmox"
            version = ">= 0.53.1"
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

resource "proxmox_virtual_environment_vm" "win11-cloudbase-init" {
  node_name   = var.proxmox_node
  pool_id     = var.proxmox_pool

  name = var.vm_config.name
  description = var.vm_config.desc

  operating_system {
    type = "win11"
  }

  cpu {
    cores   = var.vm_config.cores
    sockets = 1
  }

  memory {
    dedicated = var.vm_config.memory
  }

  clone {
      # datastore_id = var.storage
      node_name = var.proxmox_node
      vm_id = lookup(var.vm_template_id, var.vm_config.clone, -1)
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

  lifecycle {
    ignore_changes = [
      vga,
    ]
  }

  initialization {
    datastore_id = var.storage
  #   dns {
  #     servers = [
  #       var.vm_config.dns
  #     ]
  #   }
  #   ip_config {
  #     ipv4 {
  #       address = var.vm_config.ip
  #       gateway = var.vm_config.gateway
  #     }
  #   }
  }
}


