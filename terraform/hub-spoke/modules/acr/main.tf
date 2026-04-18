# ============================================================
# Azure Container Registry Module
# Basic SKU - sufficient for lab
# Image scanning via Defender for Containers
# MCSB: PV-5 vulnerability assessment
# ============================================================

resource "azurerm_container_registry" "main" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"

  # Admin account disabled - use Managed Identity instead
  # MCSB: IM-1 use managed identities
  admin_enabled = false

  tags = var.tags
}

# ============================================================
# Grant AKS cluster pull access to ACR
# Managed Identity based - no stored credentials
# ============================================================

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = var.aks_kubelet_identity_principal_id
}
