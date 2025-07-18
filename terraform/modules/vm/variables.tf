variable "vm_name" {
  description = "Name of the VM"
  type        = string
}

variable "vmid" {
  description = "VM ID"
  type        = number
}

variable "target_node" {
  description = "Proxmox node to create the VM on"
  type        = string
}

variable "clone_template" {
  description = "Name of the Proxmox VM template to clone"
  type        = string
  default     = "ubuntu-cloudinit-template"
}


variable "cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 2048
}

variable "disk_size" {
  description = "Disk size"
  type        = string
  default     = "20G"
}

variable "storage" {
  description = "Storage pool"
  type        = string
  default     = "local-lvm"
}

variable "network_bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

variable "vlan_tag" {
  description = "VLAN tag (0 for untagged)"
  type        = number
  default     = 0
}

variable "ip_address" {
  description = "IP address for the VM"
  type        = string
}

variable "gateway" {
  description = "Gateway IP"
  type        = string
}

variable "vm_password" {
  description = "Root password for the VM"
  type        = string
  sensitive   = true
}

variable "ssh_key" {
  description = "SSH public key"
  type        = string
}

variable "description" {
  description = "VM description"
  type        = string
  default     = ""
}

variable "os_type" {
  description = "Operating system type"
  type        = string
  default     = "ubuntu"
}

variable "cloudinit_file" {
  description = "Path to cloud-init user data file"
  type        = string
  default     = ""
}

variable "vm_user" {
  description = "Username for the VM"
  type        = string
  default     = "patrick"
}

variable "netmask" {
  description = "Network prefix length"
  type        = number
  default     = 24
}
