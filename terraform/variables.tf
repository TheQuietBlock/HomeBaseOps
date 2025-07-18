# Proxmox Connection
variable "proxmox_url" {
  description = "Proxmox API URL"
  type        = string
  sensitive   = true
}

variable "proxmox_api_token_id" {
  description = "Proxmox API Token ID"
  type        = string
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API Token Secret"
  type        = string
  sensitive   = true
}

# Proxmox Node
variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
  default     = "proxmox"
}

# VM User
variable "vm_user" {
  description = "Default user for VMs"
  type        = string
  default     = "patrick"
}
# VM Credentials
variable "vm_password" {
  description = "Default password for VMs"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  default     = ""
}

# Network Configuration
variable "vlans" {
  description = "VLAN configurations"
  type = map(object({
    vlan_id     = number
    subnet      = string
    gateway     = string
    description = string
  }))
}

# VLAN ID used untagged by the Proxmox host. VMs on this VLAN will have no tag.
variable "proxmox_native_vlan" {
  description = "Proxmox host native VLAN"
  type        = number
  default     = 55
}

# VM Defaults
variable "vm_cores" {
  description = "Default number of CPU cores"
  type        = number
  default     = 2
}

variable "vm_memory" {
  description = "Default memory in MB"
  type        = number
  default     = 2048
}

variable "vm_disk_size" {
  description = "Default disk size"
  type        = string
  default     = "40G"
}

variable "vm_storage" {
  description = "Storage location for VMs"
  type        = string
  default     = "storage"
}

variable "vm_ip_addresses" {
  description = "IP addresses for VMs"
  type        = map(string)
}

variable "rhel_subscription_key" {
  description = "Activation key for RHEL subscription"
  type        = string
  sensitive   = true
}
