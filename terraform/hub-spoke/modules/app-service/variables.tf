variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "environment" {
  type = string
}

variable "suffix" {
  description = "Unique suffix for App Service name (globally unique)"
  type        = string
}

variable "key_vault_id" {
  description = "Key Vault resource ID for RBAC assignment"
  type        = string
}

variable "key_vault_uri" {
  description = "Key Vault URI for app settings"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
