variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "hub_vnet_cidr" {
  description = "CIDR block for Hub VNet"
  type        = string
}

variable "firewall_subnet_cidr" {
  description = "CIDR for AzureFirewallSubnet"
  type        = string
}

variable "bastion_subnet_cidr" {
  description = "CIDR for AzureBastionSubnet"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "firewall_management_subnet_cidr" {
  description = "CIDR for AzureFirewallManagementSubnet - required for Basic SKU"
  type        = string
  default     = "10.0.4.0/26"
}
