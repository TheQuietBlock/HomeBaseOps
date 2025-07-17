# Create test VMs in each VLAN
module "vms" {
  source   = "./modules/vm"
  for_each = local.vms

  vm_name        = each.value.name
  vmid           = each.value.vmid
  target_node    = var.proxmox_node
  cores          = lookup(each.value, "cores", var.vm_cores)
  memory         = lookup(each.value, "memory", var.vm_memory)
  disk_size      = var.vm_disk_size
  storage        = var.vm_storage
  network_bridge = "vmbr0"
  vlan_tag       = var.vlans[each.value.vlan].vlan_id
  ip_address     = each.value.ip_address
  gateway        = var.vlans[each.value.vlan].gateway
  netmask        = tonumber(split("/", var.vlans[each.value.vlan].subnet)[1])
  vm_password    = var.vm_password
  vm_user        = var.vm_user
  ssh_key        = var.ssh_public_key
  description    = each.value.description
  os_type        = each.value.os_type
  cloudinit_file = each.value.cloudinit_file
  clone_template = "ubuntu-cloudinit-template"
}
