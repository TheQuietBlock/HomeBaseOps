variable "bridge_name" {
  description = "Bridge name"
  type        = string
  default     = "vmbr0"
}

variable "vlans" {
  description = "VLAN configurations"
  type = map(object({
    vlan_id = number
    subnet  = string
  }))
  default = {}
}
