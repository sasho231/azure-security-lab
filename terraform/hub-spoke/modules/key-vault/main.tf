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

  # Network access - deny public, allow via Private Endpoint
  # MCSB NS-2: secure cloud services with network controls
  # ip_rules allows Terraform management from admin workstation
  # In production this would be a jump host or managed runner IP
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = var.allowed_ip_ranges
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

# ============================================================
# Private Endpoint for Key Vault
# Gives Key Vault a private IP in the data subnet
# All traffic stays within Azure backbone - no public internet
# MCSB: NS-2 secure cloud services with network controls
# ============================================================

resource "azurerm_private_endpoint" "keyvault" {
  name                = "pe-kv-lab-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.data_subnet_id

  private_service_connection {
    name                           = "psc-kv-lab-${var.suffix}"
    private_connection_resource_id = azurerm_key_vault.main.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  tags = var.tags
}

# ============================================================
# Private DNS Zone for Key Vault
# Required for Private Endpoint DNS resolution
# Without this, Key Vault FQDN resolves to public IP
# With this, FQDN resolves to private IP 10.1.4.x
# ============================================================

resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Link DNS zone to Hub VNet
# Required so VMs in spoke can resolve Key Vault private IP
resource "azurerm_private_dns_zone_virtual_network_link" "keyvault_hub" {
  name                  = "pdnslink-kv-hub"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = var.hub_vnet_id
  registration_enabled  = false

  tags = var.tags
}

# Link DNS zone to Spoke VNet
resource "azurerm_private_dns_zone_virtual_network_link" "keyvault_spoke" {
  name                  = "pdnslink-kv-spoke"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = var.spoke_vnet_id
  registration_enabled  = false

  tags = var.tags
}

# DNS A record linking Key Vault FQDN to private IP
resource "azurerm_private_dns_a_record" "keyvault" {
  name                = "kv-lab-${var.suffix}"
  zone_name           = azurerm_private_dns_zone.keyvault.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.keyvault.private_service_connection[0].private_ip_address]

  tags = var.tags
}
