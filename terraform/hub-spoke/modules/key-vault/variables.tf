variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "suffix" {
  description = "Unique suffix for Key Vault name (3-10 chars, globally unique)"
  type        = string
}

variable "vm_managed_identity_principal_id" {
  description = "Principal ID of VM managed identity"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "data_subnet_id" {
  description = "Data subnet ID for Private Endpoint placement"
  type        = string
}

variable "hub_vnet_id" {
  description = "Hub VNet ID for Private DNS Zone link"
  type        = string
}

variable "spoke_vnet_id" {
  description = "Spoke VNet ID for Private DNS Zone link"
  type        = string
}
