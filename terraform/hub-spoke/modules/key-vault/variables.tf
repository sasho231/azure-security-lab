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
