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

variable "firewall_management_subnet_cidr" {
  description = "CIDR for AzureFirewallManagementSubnet"
  type        = string
  default     = "10.0.4.0/26"
}

variable "deploy_firewall" {
  description = "Deploy Azure Firewall - costs ~$0.34/hour. Set false to destroy."
  type        = bool
  default     = true
}

variable "deploy_bastion" {
  description = "Deploy Azure Bastion - costs ~$0.19/hour. Set false to destroy."
  type        = bool
  default     = false
}

variable "appgw_subnet_cidr" {
  description = "CIDR for Application Gateway subnet"
  type        = string
  default     = "10.1.2.0/24"
}

variable "app_subnet_cidr" {
  description = "CIDR for web application subnet"
  type        = string
  default     = "10.1.3.0/24"
}

variable "data_subnet_cidr" {
  description = "CIDR for database Private Endpoint subnet"
  type        = string
  default     = "10.1.4.0/24"
}

variable "deploy_vm_app" {
  description = "Deploy web application VM - costs ~$0.04/hour"
  type        = bool
  default     = false
}

variable "vm_admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "azureuser"
}

variable "vm_ssh_public_key" {
  description = "SSH public key for VM authentication"
  type        = string
}
