# ============================================================
# App Service Module
# Free tier F1 - zero compute cost
# Provides Defender for App Service CWPP coverage
# ADR: different workload type from VM for CNAPP completeness
# MCSB: PV-4, LT-1
# ============================================================

# ============================================================
# App Service Plan
# Free tier F1 - no compute charges
# Linux for Flask compatibility
# ============================================================

resource "azurerm_service_plan" "main" {
  name                = "asp-lab-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "F1"

  tags = var.tags
}

# ============================================================
# App Service (Web App)
# Runs Flask application
# Managed Identity for Key Vault access
# HTTPS only enforced
# ============================================================

resource "azurerm_linux_web_app" "main" {
  name                = "app-lab-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.main.id

  # MCSB DP-3: enforce HTTPS only
  https_only = true

  # Managed Identity - same pattern as VM
  identity {
    type = "SystemAssigned"
  }

  site_config {
    # Python 3.10 runtime for Flask
    application_stack {
      python_version = "3.10"
    }

    # Always on not available on free tier
    always_on = false

    # MCSB DP-3: minimum TLS 1.2
    minimum_tls_version = "1.2"

    # Health check endpoint
    health_check_path = "/health"
  }

  # App settings - reference Key Vault secrets
  app_settings = {
    "FLASK_ENV"                  = "production"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
    "KEY_VAULT_URI"              = var.key_vault_uri
  }

  tags = var.tags
}

# ============================================================
# Grant App Service Managed Identity access to Key Vault
# System-assigned identity created with the app
# ============================================================

resource "azurerm_role_assignment" "app_keyvault" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app.main.identity[0].principal_id
}
