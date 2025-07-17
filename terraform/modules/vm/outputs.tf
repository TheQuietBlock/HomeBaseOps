output "vmid" {
  description = "VM ID"
  value       = proxmox_vm_qemu.vm.vmid
}

output "ip_address" {
  description = "IP address of the VM"
  value       = var.ip_address
}

output "vm_name" {
  description = "Name of the VM"
  value       = proxmox_vm_qemu.vm.name
}

output "mac_address" {
  description = "MAC address of the VM"
  value       = proxmox_vm_qemu.vm.network[0].macaddr
}
