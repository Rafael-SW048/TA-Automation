variable "vm_name" {
  description = "The name of the VM"
  type        = string
}

variable "vmid" {
  description = "The ID of the VM"
  type        = number
}

variable "desc" {
  description = "The description of the VM"
  type        = string
}

variable "vm_template" {
  description = "The template to clone the VM from"
  type        = string
}

variable "cores" {
  description = "The number of CPU cores for the VM"
  type        = number
}

variable "sockets" {
  description = "The number of CPU sockets for the VM"
  type        = number
}

variable "memory" {
  description = "The amount of memory for the VM"
  type        = number
}



