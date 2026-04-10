variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "northeurope"
}

variable "environment" {
  description = "Environment name used in resource naming"
  type        = string
  default     = "lab"
}

variable "hub_vnet_cidr" {
  description = "CIDR block for Hub VNet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "firewall_subnet_cidr" {
  description = "CIDR for AzureFirewallSubnet - name is fixed by Azure"
  type        = string
  default     = "10.0.1.0/26"
}

variable "bastion_subnet_cidr" {
  description = "CIDR for AzureBastionSubnet - name is fixed by Azure"
  type        = string
  default     = "10.0.2.0/26"
}

variable "spoke_vnet_cidr" {
  description = "CIDR block for Spoke VNet"
  type        = string
  default     = "10.1.0.0/16"
}

variable "workload_subnet_cidr" {
  description = "CIDR for workload subnet inside spoke"
  type        = string
  default     = "10.1.1.0/24"
}
