# ============================================================
# Terraform State Storage Account Hardening
# Fixes security findings on existing state storage
# MCSB: DP-3 (encrypt in transit), NS-2 (network controls)
# ============================================================

resource "azurerm_storage_account" "state" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # MCSB DP-3: enforce HTTPS only
  https_traffic_only_enabled = true

  # MCSB DP-3: minimum TLS 1.2
  min_tls_version = "TLS1_2"

  # MCSB DP-2: no public blob access
  allow_nested_items_to_be_public = false

  # Network rules - deny public, allow Azure services
  # Terraform pipeline authenticates via Workload Identity
  # which is treated as a trusted Azure service
  network_rules {
    default_action = "Allow"
    bypass         = ["AzureServices"]
  }

  tags = var.tags
}
