# ============================================================
# Log Analytics Workspace
# Required for Defender for Containers and AKS monitoring
# Also used as Sentinel workspace in Phase 7
# ============================================================

resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-lab-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"

  # Minimum retention - 30 days
  # Phase 7 increases to 90 days for Sentinel
  retention_in_days = 30

  tags = var.tags
}
