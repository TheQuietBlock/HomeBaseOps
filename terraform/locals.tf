locals {
  # Common tags for all resources
  common_tags = {
    Environment = "HomeBaseOps"
    ManagedBy   = "terraform"
    Project     = "proxmox-vlans"
  }

  # VM configurations for each VLAN
  vms = {
    automation = {
      name           = "vm-server-automation"
      vmid           = 100
      vlan           = "server"
      ip_address     = var.vm_ip_addresses["automation"]
      os_type        = "ubuntu"
      cloudinit_file = "cloudinit/ubuntu-cloudinit.yaml"
      description    = "rundeck server"
    }
    docker1 = {
      name           = "port-o-party-1"
      vmid           = 101
      cores          = 4
      memory         = 8192
      vlan           = "server"
      ip_address     = var.vm_ip_addresses["docker1"]
      os_type        = "ubuntu"
      cloudinit_file = "cloudinit/ubuntu-cloudinit.yaml"
      description    = "Docker server 1"
    }
    docker2 = {
      name           = "port-o-party-2"
      vmid           = 102
      cores          = 4
      memory         = 8192
      vlan           = "server"
      ip_address     = var.vm_ip_addresses["docker2"]
      os_type        = "ubuntu"
      cloudinit_file = "cloudinit/ubuntu-cloudinit.yaml"
      description    = "Docker server 2"
    }
    docker3 = {
      name           = "port-o-party-3"
      vmid           = 103
      cores          = 4
      memory         = 8192
      vlan           = "server"
      ip_address     = var.vm_ip_addresses["docker3"]
      os_type        = "ubuntu"
      cloudinit_file = "cloudinit/ubuntu-cloudinit.yaml"
      description    = "Docker server 2"
    }
    minecraft = {
      name           = "vm-server-minecraft"
      vmid           = 104
      cores          = 4
      memory         = 8192
      vlan           = "server"
      ip_address     = var.vm_ip_addresses["minecraft"]
      os_type        = "ubuntu"
      cloudinit_file = "cloudinit/ubuntu-cloudinit.yaml"
      description    = "Minecraft server"
    }
  }
}
