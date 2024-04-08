# Variable Definitions
variable "proxmox_api_url" {
    type = string
    default = "https://0.0.0.0:8006/api2/json"
}

variable "proxmox_api_token_id" {
    type = string
}

variable "proxmox_api_token_secret" {
    type = string
}

variable "proxmox_skip_tls_verify" {
    type = bool
}

variable "proxmox_node" {
    type = string
    default = "pve"
}

variable "proxmox_pool" {
    type = string
}

variable "proxmox_iso_storage" {
    type = string
    default = "local"
}

variable "proxmox_vm_storage" {
    type = string
    default = "local-lvm"
}

variable "vm_name" {
    type = string
}

variable "template_description" {
    type = string
}

variable "iso_file" {
    type = string
}

variable "iso_checksum" {
    type = string
}

variable "iso_autounattend" {
    type = string
}

variable "iso_autounattend_checksum" {
    type = string
}

variable "iso_scripts" {
    type = string
}

variable "iso_scripts_checksum" {
    type = string
}

variable "iso_virtio" {
    type = string
}

variable "iso_virtio_checksum" {
    type = string
}

variable "vm_cpu_cores" {
    type = string
    default = "4"
}

variable "vm_memory" {
    type = string
    default = "4096"
}

variable "vm_disk_size" {
    type = string
    default = "32"
}

variable "vm_sockets" {
    type = string
    default = "1"
}

variable "os" {
    type = string
}

variable "winrm_username" {
    type = string
}

variable "winrm_password" {
    type = string
}