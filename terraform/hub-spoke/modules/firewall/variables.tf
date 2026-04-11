variable "resource_group_name" {
  description = "Resource group for firewall resources"
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

variable "firewall_subnet_id" {
  description = "AzureFirewallSubnet ID from hub network"
  type        = string
}

variable "workload_subnet_id" {
  description = "Spoke workload subnet ID for UDR association"
  type        = string
}

variable "hub_vnet_cidr" {
  description = "Hub VNet CIDR for firewall rules"
  type        = string
}

variable "spoke_vnet_cidr" {
  description = "Spoke VNet CIDR for firewall rules"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "firewall_management_subnet_id" {
  description = "AzureFirewallManagementSubnet ID - required for Basic SKU"
  type        = string
}
