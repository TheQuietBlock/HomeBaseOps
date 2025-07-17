output "vm_ips" {
  description = "IP addresses of created VMs"
  value = {
    for k, v in module.vms : k => v.ip_address
  }
}

output "vm_ids" {
  description = "Proxmox VM IDs"
  value = {
    for k, v in module.vms : k => v.vmid
  }
}

output "ssh_connection_strings" {
  description = "SSH connection strings for each VM"
  value = {
    for k, v in local.vms : k => "ssh patrick@${v.ip_address}"
  }
}
