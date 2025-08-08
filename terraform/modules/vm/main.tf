terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc03"
    }
  }
}
resource "proxmox_vm_qemu" "vm" {
  name        = var.vm_name
  target_node = var.target_node
  vmid        = var.vmid
  clone       = var.clone_template
  desc        = var.description

  # Hardware Configuration
  cpu {
    type    = "host"
    sockets = 1
    cores   = var.cores
  }
  memory     = var.memory
  scsihw     = "virtio-scsi-pci"
  boot       = "order=scsi0;ide3;net0"
  agent      = 1
  ciuser     = var.vm_user
  cipassword = var.vm_password
  sshkeys    = var.ssh_key
  ipconfig0  = "ip=${var.ip_address}/${var.netmask},gw=${var.gateway}"

  # OS Configuration
  os_type = var.os_type == "ubuntu" ? "l26" : "l26"
  bios    = "seabios"

  # Disk Configuration
  disks {
    scsi {
      scsi0 {
        disk {
          size    = var.disk_size
          storage = var.storage
        }
      }
    }
    ide {
      ide3 {
        cloudinit {
          storage = var.storage
        }
      }
    }
  }

  # Network Configuration
  network {
    id     = 0
    model  = "virtio"
    bridge = var.network_bridge
    tag    = var.vlan_tag
  }

  # Lifecycle
  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}
