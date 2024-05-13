# Credentials and configuration for the Proxmox provider
variable "proxmox_api_url" {
  type = string
  default = "https://0.0.0.0:8006/api2/json"
}

variable "proxmox_api_token_id" {
  type = string
  sensitive = true
}

variable "proxmox_api_token_password" {
  type = string
  sensitive = true
  # default = "admin"
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
  default = "e1000"
}

variable "vm_template_id" {
  type = map(number)

  # set the ids according to your templates
  default = {
    Win11x64-VM-template-cloudbaseInit-raw-NoSysPrep-ovmf = 104,
    Win11x64-VM-template-cloudbaseInit-raw-NoSysPrep = 100
  }
}


variable "vms_config" {
  type = map(object({
    name        = string
    desc        = string
    cores       = number
    cpu_type    = string
    memory      = number
    clone       = string
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
      clone       = "Win11x64-VM-template-cloudbaseInit-ovmf-autorun-jordan-scripts"
      dns         = "192.168.10.1" # Placeholder
      ip          = "192.168.10.10/24" # Placeholder
      gateway     = "192.168.10.1" # Placeholder
      pci_device  = ""
      SID         = "VM-CloudGaming-default"
    }
  }
}


# variable "vm_config" {
#   type = object({
#     name               = string
#     desc               = string
#     cores              = number
#     cpu_type           = string
#     memory             = number
#     clone              = string
#     dns                = string
#     ip                 = string
#     gateway            = string
#   })

#   default = {
#     name               = "VM-CloudGaming-default"
#     desc               = "CG-Default - windows 11 Pro with cloudbase-init"
#     cores              = 6
#     cpu_type           = "host"
#     memory             = 8192
#     clone              = "Win11x64-VM-template-cloudbaseInit-raw-NoSysPrep"
#     dns                = "192.168.10.1" # Only for placeholder
#     ip                 = "192.168.10.10/24" # Only for placeholder
#     gateway            = "192.168.10.1" # Only for placeholder
#   }
# }