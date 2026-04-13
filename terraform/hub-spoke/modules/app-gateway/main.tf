# ============================================================
# Application Gateway + WAF Module
# WAF_v2 SKU with OWASP 3.2 in Prevention mode
# HTTP only for Phase 3 - HTTPS added in Phase 4
# ADR-005: docs/adr/ADR-005-application-gateway-waf.md
# MCSB: NS-6 deploy web application firewall
# ============================================================

resource "azurerm_web_application_firewall_policy" "main" {
  name                = "wafpol-appgw-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }

  policy_settings {
    mode                        = "Prevention"
    enabled                     = true
    request_body_check          = true
    max_request_body_size_in_kb = 128
    file_upload_limit_in_mb     = 100
  }

  tags = var.tags
}

resource "azurerm_public_ip" "appgw" {
  name                = "pip-appgw-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

locals {
  backend_pool_name      = "backend-pool-webapp"
  backend_http_settings  = "backend-http-settings"
  frontend_ip_config     = "frontend-ip-config"
  frontend_port_http     = "frontend-port-http"
  http_listener_name     = "http-listener"
  routing_rule_name      = "routing-rule-http"
  health_probe_name      = "health-probe-webapp"
}

resource "azurerm_application_gateway" "main" {
  name                = "appgw-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 1
  }

  firewall_policy_id = azurerm_web_application_firewall_policy.main.id

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = var.appgw_subnet_id
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_config
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  frontend_port {
    name = local.frontend_port_http
    port = 80
  }

  backend_address_pool {
    name         = local.backend_pool_name
    ip_addresses = [var.backend_vm_ip]
  }

  probe {
    name                = local.health_probe_name
    protocol            = "Http"
    host                = var.backend_vm_ip
    path                = "/health"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3

    match {
      status_code = ["200"]
    }
  }

  backend_http_settings {
    name                  = local.backend_http_settings
    cookie_based_affinity = "Disabled"
    port                  = 8080
    protocol              = "Http"
    request_timeout       = 60
    probe_name            = local.health_probe_name
  }

  http_listener {
    name                           = local.http_listener_name
    frontend_ip_configuration_name = local.frontend_ip_config
    frontend_port_name             = local.frontend_port_http
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.routing_rule_name
    rule_type                  = "Basic"
    priority                   = 100
    http_listener_name         = local.http_listener_name
    backend_address_pool_name  = local.backend_pool_name
    backend_http_settings_name = local.backend_http_settings
  }

  # TLS policy - enforce TLS 1.2 minimum
  # MCSB DP-3: encrypt data in transit
  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101"
  }

  tags = var.tags
}
