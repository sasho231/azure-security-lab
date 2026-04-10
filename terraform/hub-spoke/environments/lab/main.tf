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
