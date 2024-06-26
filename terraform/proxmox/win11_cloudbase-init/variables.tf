# Credentials and configuration for the Proxmox provider
variable "proxmox_api_url" {
  type = string
  default = "https://10.11.1.181:8006/api2/json"
}

variable "proxmox_api_token_id" {
  type = string
  sensitive = true
}

variable "proxmox_api_token_password" {
  type = string
  sensitive = true
}

variable "proxmox_skip_tls_verify" {
  type = bool
  default = true
  
}

variable "proxmox_node" {
  default = "pve"
}

variable "proxmox_pool" {
  default = "VM_GAMING"
}

# VM configuration
variable "vm_full_clone" {
  default = false
}


variable "storage" {
  default = "local-lvm"
}

variable "network_bridge" {
  default = "vmbr0"
}

variable "network_model" {
  default = "virtio"
}

variable "vm_template_id" {
  type = map(number)

  # set the ids according to your templates
  default = {
    RTX-4070-Ti-sysprep-updated = 201,
    GTX-1080-sysprep = 202
  }
}


variable "vms_config" {
  type = map(object({
    name        = string
    desc        = string
    cores       = number
    cpu_type    = string
    memory      = number
    node        = string
    clone       = string
    disk_size   = number
    dns         = string
    ip          = string
    gateway     = string
    pci_device      = string
    SID         = string
  }))

  default = {
    "default" = {
      name        = "VM-CloudGaming-default"
      desc        = "CG-Default - windows 11 Pro with cloudbase-init"
      cores       = 6
      cpu_type    = "host"
      memory      = 8192
      node        = "pve"
      clone       = "RTX-4070-Ti-SysPrep-updated"
      # clone       = "RTX-4070-Ti-SysPrep"
      disk_size   = 512
      dns         = "192.168.10.1" # Placeholder
      ip          = "192.168.10.10/24" # Placeholder
      gateway     = "192.168.10.1" # Placeholder
      pci_device  = ""
      SID         = "VM-CloudGaming-default"
    }
  }
}

