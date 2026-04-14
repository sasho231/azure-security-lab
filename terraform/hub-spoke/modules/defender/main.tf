# ============================================================
# Defender for Cloud Module
# Enables CSPM and CWPP across the subscription
# ADR-006: docs/adr/ADR-006-defender-for-cloud-cspm.md
# ============================================================

# ============================================================
# Security Center Contact
# Alerts sent to this email address
# ============================================================

resource "azurerm_security_center_contact" "main" {
  email               = var.security_contact_email
  alert_notifications = true
  alerts_to_admins    = true
}

# ============================================================
# Defender Plans — CWPP coverage per workload type
# Each plan protects a specific resource type
# ============================================================

# Defender for Servers — protects VMs
# Plan 1: basic threat detection, Just-in-time VM access
# Cost: ~$5/server/month
resource "azurerm_security_center_subscription_pricing" "servers" {
  tier          = var.enable_defender_paid ? "Standard" : "Free"
  resource_type = "VirtualMachines"
}

# Defender for Storage — protects storage accounts
# Detects: malware uploads, suspicious access, data exfiltration
# Cost: ~$10/storage account/month
resource "azurerm_security_center_subscription_pricing" "storage" {
  tier          = var.enable_defender_paid ? "Standard" : "Free"
  resource_type = "StorageAccounts"
}

# Defender for Key Vault — protects key vaults
# Detects: unusual access patterns, suspicious operations
# Cost: ~$0.02/10k operations
resource "azurerm_security_center_subscription_pricing" "keyvault" {
  tier          = var.enable_defender_paid ? "Standard" : "Free"
  resource_type = "KeyVaults"
}

# Defender for App Service — protects web apps
# Detects: web attacks, suspicious outbound traffic
# Cost: ~$15/App Service plan/month
resource "azurerm_security_center_subscription_pricing" "appservice" {
  tier          = var.enable_defender_paid ? "Standard" : "Free"
  resource_type = "AppServices"
}

# Defender for Containers — protects AKS
# Detects: container escapes, suspicious processes, crypto mining
# Cost: ~$7/core/month
resource "azurerm_security_center_subscription_pricing" "containers" {
  tier          = var.enable_defender_paid ? "Standard" : "Free"
  resource_type = "Containers"
}

# Defender for ARM — protects Azure Resource Manager operations
# Detects: suspicious management operations, impossible travel
# Cost: ~$3.50/subscription/month
resource "azurerm_security_center_subscription_pricing" "arm" {
  tier          = var.enable_defender_paid ? "Standard" : "Free"
  resource_type = "Arm"
}

# ============================================================
# Auto Provisioning
# Automatically installs agents on VMs
# Azure Monitor Agent replaces deprecated MMA
# ============================================================

resource "azurerm_security_center_auto_provisioning" "mma" {
  auto_provision = "Off"
}

# ============================================================
# MCSB Regulatory Compliance
# Maps Defender findings to MCSB controls
# Shows compliance percentage per control
# ============================================================

resource "azurerm_security_center_setting" "mcsb" {
  setting_name = "MCAS"
  enabled      = false
}
