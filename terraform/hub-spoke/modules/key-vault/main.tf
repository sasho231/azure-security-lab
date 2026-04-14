# ============================================================
# Key Vault Module
# Secure secrets management for lab workloads
# MCSB: DP-1 (data classification), DP-3 (encrypt at rest)
# ============================================================

# ============================================================
# Key Vault
# Soft delete and purge protection enabled
# RBAC authorization (not legacy access policies)
# Private endpoint in Phase 5
# ============================================================

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                = "kv-lab-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # MCSB DP-1: soft delete protects against accidental deletion
  soft_delete_retention_days = 7

  # MCSB DP-1: purge protection prevents permanent deletion
  # even by administrators during retention period
  purge_protection_enabled = true

  # RBAC authorization - modern approach
  # Replaces legacy access policies
  # Allows fine-grained role assignments
  enable_rbac_authorization = true

  # Network access - allow all for now
  # Phase 5 adds Private Endpoint and restricts to VNet only
  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  tags = var.tags
}

# ============================================================
# Grant VM Managed Identity access to Key Vault
# Least privilege - read secrets only
# VM uses this to retrieve Flask app configuration
# ============================================================

resource "azurerm_role_assignment" "vm_keyvault_reader" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.vm_managed_identity_principal_id
}

# ============================================================
# Grant your own account admin access
# Needed to add secrets to Key Vault
# ============================================================

resource "azurerm_role_assignment" "admin_keyvault" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# ============================================================
# Lab Secrets
# Placeholder secrets for Flask app configuration
# In production these would be real credentials
# ============================================================

resource "azurerm_key_vault_secret" "db_connection" {
  name         = "db-connection-string"
  value        = "postgresql://labuser:placeholder@db-lab.postgres.database.azure.com:5432/labdb"
  key_vault_id = azurerm_key_vault.main.id

  tags = var.tags

  depends_on = [azurerm_role_assignment.admin_keyvault]
}

resource "azurerm_key_vault_secret" "flask_secret_key" {
  name         = "flask-secret-key"
  value        = "lab-secret-key-replace-in-production"
  key_vault_id = azurerm_key_vault.main.id

  tags = var.tags

  depends_on = [azurerm_role_assignment.admin_keyvault]
}
