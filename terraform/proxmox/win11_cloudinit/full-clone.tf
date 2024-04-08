# Proxmox Full-Clone
# ---
# Create a new VM from a clone

resource "proxmox_vm_qemu" "vms" {
    
    # VM General Settings
    target_node = "pve"
    vmid = var.vmid
    name = var.vm_name
    desc = var.desc

    # VM Advanced General Settings
    onboot = true 

    # VM OS Settings
    clone = var.vm_template

    # VM System Settings
    agent = 1
    
    # VM CPU Settings
    cores = var.cores
    sockets = var.sockets
    cpu = "host"    
    
    # VM Memory Settings
    memory = var.memory

    # VM Network Settings
    network {
        bridge = "vmbr0"
        model  = "virtio"
    }

    # VM Cloud-Init Settings
    os_type = "cloud-init"

    # (Optional) IP Address and Gateway
    # ipconfig0 = "ip=0.0.0.0/0,gw=0.0.0.0"
    ipconfig0 = "ip=dhcp"
    
    # (Optional) Default User
    ciuser = "xcad"
    
    # (Optional) Add your SSH KEY
    sshkeys = <<EOF
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC4hUOxUKMDVUTvp/zrK8KVw0Ts0nXUiOGKQaeV8OAO5AU55aozvcYZHYdJ+wa1uKb2r+jPRTrfvAz7aA/Jhy7kEFUTJtmZrZMp/Ga5Qo9TxrAKDEyUY7oXk/R6Iim4gZJU08j8sVjoCngqJyvct9y7/h2ln7udhnDVR+l6l56w5XWDr9dzTVHIqq/EUD9+Y3f74CWxeaz7rLMONWaZEOGjC52EnaSz9PrUL1YXJhBraQRD/3ySOgN980xz1mZjg6Nz9xQawYQEg/wP4z3e8tKZB+ZoeceIRbZy2ra3f0xz9BhsV85lecIbNfNi7tTqfp4vCXVNsCKU39eVwIB021vQhORSznojWWsLR/PRaeIBRdV4GMF/JIVmT8oFGrh/F0bv46EQ+9BV+6jVRf2sqqGgJrc6m4+Qn+z6S3M4+Y9e9rxkv5LgcQba8YzUdB9zaapsErsOyabUPMe16CgTswXJaq+SBzxO8JRUAz5W3BAPCSftfYeg+hqY+egPBEL9+8Ve3zr7AtMKADZVj7/FUJ5M++S4RBlIKZv91/rGdLBOp28H1aZSXRawGDImKjwKjUaWz0lLlomrpTebsJepjGQYRRzvyH1ST22mGFMbH5hdwJq97/4578rEN0HhEZ/lPFWPkcBWmRk4pC8ssqsdDIx3KrUrH9d/QRAK3gwQ150wLQ
    EOF
}


