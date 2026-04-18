# ============================================================
# Phase 2 - Hub-Spoke Network Topology
# CAF-aligned network foundation for the lab
# ADR-002: docs/adr/ADR-002-hub-spoke-network-topology.md
# ============================================================

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0"
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
  subscription_id = var.subscription_id
}

# ============================================================
# Resource Groups
# Separate RGs for hub and spoke — clean separation of concern
# ============================================================

resource "azurerm_resource_group" "hub" {
  name     = "rg-hub-${var.environment}"
  location = var.location

  tags = local.common_tags
}

resource "azurerm_resource_group" "spoke" {
  name     = "rg-spoke-${var.environment}"
  location = var.location

  tags = local.common_tags
}

# ============================================================
# Hub Network Module
# ============================================================

module "hub_network" {
  source = "../../modules/hub-network"

  resource_group_name = azurerm_resource_group.hub.name
  location            = var.location
  environment         = var.environment
  hub_vnet_cidr       = var.hub_vnet_cidr
  firewall_subnet_cidr = var.firewall_subnet_cidr
  bastion_subnet_cidr  = var.bastion_subnet_cidr
  tags                = local.common_tags
  deploy_bastion      = var.deploy_bastion

  depends_on = [azurerm_resource_group.hub]
}

# ============================================================
# Spoke Network Module
# ============================================================

module "spoke_network" {
  source = "../../modules/spoke-network"

  resource_group_name  = azurerm_resource_group.spoke.name
  location             = var.location
  environment          = var.environment
  spoke_vnet_cidr      = var.spoke_vnet_cidr
  appgw_subnet_cidr    = var.appgw_subnet_cidr
  app_subnet_cidr      = var.app_subnet_cidr
  data_subnet_cidr     = var.data_subnet_cidr
  bastion_subnet_cidr  = var.bastion_subnet_cidr
  workload_subnet_cidr = var.workload_subnet_cidr
  tags                 = local.common_tags

  depends_on = [azurerm_resource_group.spoke]
}

# ============================================================
# VNet Peering Module
# Connects hub and spoke bidirectionally
# ============================================================

module "vnet_peering" {
  source = "../../modules/peering"

  hub_vnet_name        = module.hub_network.hub_vnet_name
  hub_vnet_id          = module.hub_network.hub_vnet_id
  hub_resource_group   = azurerm_resource_group.hub.name
  spoke_vnet_name      = module.spoke_network.spoke_vnet_name
  spoke_vnet_id        = module.spoke_network.spoke_vnet_id
  spoke_resource_group = azurerm_resource_group.spoke.name

  depends_on = [module.hub_network, module.spoke_network]
}

# ============================================================
# Local values
# Common tags applied to every resource
# WAF: tagging strategy for cost management and governance
# ============================================================

locals {
  common_tags = {
    Environment = var.environment
    Project     = "azure-security-lab"
    ManagedBy   = "terraform"
    Phase       = "2-networking"
    Framework   = "CAF"
  }
}

# ============================================================
# Firewall Module
# Deploys Azure Firewall, Policy, and UDR
# ADR-003: centralised traffic inspection
# COMMENT OUT to destroy Firewall and save cost
# ============================================================

module "firewall" {
  count  = var.deploy_firewall ? 1 : 0
  source = "../../modules/firewall"

  resource_group_name = azurerm_resource_group.hub.name
  location            = var.location
  environment         = var.environment
  firewall_subnet_id            = module.hub_network.firewall_subnet_id
  workload_subnet_id  = module.spoke_network.workload_subnet_id
  app_subnet_id                 = module.spoke_network.app_subnet_id
  hub_vnet_cidr       = var.hub_vnet_cidr
  spoke_vnet_cidr                = var.spoke_vnet_cidr
  firewall_management_subnet_id = module.hub_network.firewall_management_subnet_id
  tags                = local.common_tags

  depends_on = [module.hub_network, module.spoke_network]
}

# ============================================================
# Web Application VM Module
# Deploys Flask web application on Ubuntu 22.04
# No public IP - access via Bastion only
# ADR-004: docs/adr/ADR-004-web-application-vm.md
# ============================================================

module "vm_app" {
  count  = var.deploy_vm_app ? 1 : 0
  source = "../../modules/vm-app"

  resource_group_name = azurerm_resource_group.spoke.name
  location            = var.location
  environment         = var.environment
  app_subnet_id       = module.spoke_network.app_subnet_id
  admin_username      = var.vm_admin_username
  ssh_public_key      = var.vm_ssh_public_key
  tags                = local.common_tags

  depends_on = [module.spoke_network, module.firewall]
}

# ============================================================
# Application Gateway + WAF Module
# Internet-facing ingress with OWASP 3.2 WAF protection
# ADR-005: docs/adr/ADR-005-application-gateway-waf.md
# ============================================================

module "app_gateway" {
  count  = var.deploy_appgw ? 1 : 0
  source = "../../modules/app-gateway"

  resource_group_name = azurerm_resource_group.spoke.name
  location            = var.location
  environment         = var.environment
  appgw_subnet_id     = module.spoke_network.appgw_subnet_id
  backend_vm_ip       = module.vm_app[0].vm_private_ip
  tags                = local.common_tags

  depends_on = [module.spoke_network, module.vm_app]
}

# ============================================================
# Defender for Cloud Module
# CSPM and CWPP across all workloads
# ADR-006: docs/adr/ADR-006-defender-for-cloud-cspm.md
# ============================================================

module "defender" {
  source = "../../modules/defender"

  security_contact_email = var.security_contact_email
  enable_defender_paid   = var.enable_defender_paid
}

# ============================================================
# Key Vault Module
# Secure secrets management, Defender for Key Vault coverage
# ============================================================

module "key_vault" {
  source = "../../modules/key-vault"

  resource_group_name              = azurerm_resource_group.spoke.name
  location                         = var.location
  suffix                           = var.key_vault_suffix
  vm_managed_identity_principal_id = module.vm_app[0].managed_identity_principal_id
  tags                             = local.common_tags

  depends_on = [module.vm_app]
}

# App Service: skipped - quota restrictions on pay-as-you-go subscription

# ============================================================
# Terraform State Storage Hardening
# Fixes TLS and network settings on state storage account
# MCSB: DP-3, NS-2
# ============================================================

module "terraform_state" {
  source = "../../modules/terraform-state"

  storage_account_name = "stterraformstate10323"
  resource_group_name  = "rg-terraform-state"
  location             = var.location
  tags                 = local.common_tags
}

# ============================================================
# Log Analytics Workspace
# Required for Defender for Containers and AKS monitoring
# Reused as Sentinel workspace in Phase 7
# ============================================================

module "log_analytics" {
  source = "../../modules/log-analytics"

  resource_group_name = azurerm_resource_group.spoke.name
  location            = var.location
  environment         = var.environment
  tags                = local.common_tags

  depends_on = [azurerm_resource_group.spoke]
}

# ============================================================
# Azure Container Registry
# Image storage and scanning for containerised workloads
# ============================================================

module "acr" {
  count  = var.deploy_aks ? 1 : 0
  source = "../../modules/acr"

  acr_name                          = var.acr_name
  resource_group_name               = azurerm_resource_group.spoke.name
  location                          = var.location
  aks_kubelet_identity_principal_id = module.aks[0].kubelet_identity_principal_id
  tags                              = local.common_tags

  depends_on = [module.aks]
}

# ============================================================
# AKS Cluster
# Kubernetes for containerised workloads
# Defender for Containers + Falco for CWPP
# ADR-007: docs/adr/ADR-007-aks-and-container-security.md
# ============================================================

module "aks" {
  count  = var.deploy_aks ? 1 : 0
  source = "../../modules/aks"

  resource_group_name        = azurerm_resource_group.spoke.name
  location                   = var.location
  environment                = var.environment
  app_subnet_id              = module.spoke_network.app_subnet_id
  log_analytics_workspace_id = module.log_analytics.workspace_id
  kubernetes_version         = var.kubernetes_version
  tags                       = local.common_tags

  depends_on = [module.spoke_network, module.log_analytics]
}
