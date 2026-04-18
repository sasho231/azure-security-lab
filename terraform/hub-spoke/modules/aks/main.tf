# ============================================================
# AKS Cluster Module
# Azure Kubernetes Service for containerised workloads
# Defender for Containers + Falco for CWPP coverage
# ADR-007: docs/adr/ADR-007-aks-and-container-security.md
# ============================================================

# ============================================================
# AKS Cluster
# ============================================================

resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-lab-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "aks-lab-${var.environment}"

  # Standard tier required for LTS versions in North Europe
  # Free tier does not support LTS Kubernetes versions
  sku_tier = "Standard"

  # ============================================================
  # System Node Pool
  # Single node for cost efficiency
  # D2as_v4 - same as VM, proven available in North Europe
  # ============================================================

  default_node_pool {
    name                = "system"
    node_count          = 1
    vm_size             = "Standard_D2as_v4"
    os_disk_size_gb     = 30

    # Place nodes in app subnet
    vnet_subnet_id = var.app_subnet_id

    tags = var.tags
  }

  # ============================================================
  # Managed Identity
  # AKS uses managed identity for Azure resource access
  # No service principal credentials to manage
  # ============================================================

  identity {
    type = "SystemAssigned"
  }

  # ============================================================
  # Network Profile
  # Azure CNI - pods get real VNet IPs
  # Required for proper network policy enforcement
  # ============================================================

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    service_cidr   = "172.16.0.0/16"
    dns_service_ip = "172.16.0.10"
  }

  # ============================================================
  # Microsoft Defender for Containers
  # CWPP for Kubernetes workloads
  # Provides: image scanning, audit logs, runtime detection
  # ============================================================

  microsoft_defender {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  # ============================================================
  # Azure Monitor for containers
  # ============================================================

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  # ============================================================
  # RBAC and Azure AD integration
  # ============================================================

  role_based_access_control_enabled = true

  azure_active_directory_role_based_access_control {
    managed            = true
    azure_rbac_enabled = true
  }

  tags = var.tags
}
