# ============================================================
# Azure Firewall Module
# Basic SKU - cost effective for lab
# Basic SKU requires management IP configuration
# ADR-003: docs/adr/ADR-003-azure-firewall-and-routing.md
# ============================================================

resource "azurerm_firewall_policy" "hub" {
  name                     = "fwpol-hub-${var.environment}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  threat_intelligence_mode = "Alert"
  sku                      = "Basic"

  tags = var.tags
}

resource "azurerm_firewall_policy_rule_collection_group" "lab" {
  name               = "rcg-lab-${var.environment}"
  firewall_policy_id = azurerm_firewall_policy.hub.id
  priority           = 100

  application_rule_collection {
    name     = "arc-allow-outbound"
    priority = 100
    action   = "Allow"

    rule {
      name = "allow-windows-update"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses      = [var.spoke_vnet_cidr]
      destination_fqdn_tags = ["WindowsUpdate"]
    }

    rule {
      name = "allow-ubuntu-updates"
      protocols {
        type = "Https"
        port = 443
      }
      protocols {
        type = "Http"
        port = 80
      }
      source_addresses  = [var.spoke_vnet_cidr]
      destination_fqdns = [
        "*.ubuntu.com",
        "*.launchpad.net",
        "security.ubuntu.com"
      ]
    }

    rule {
      name = "allow-azure-services"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses      = [var.spoke_vnet_cidr]
      destination_fqdn_tags = ["AzureKubernetesService"]
    }
  }

  network_rule_collection {
    name     = "nrc-allow-dns"
    priority = 200
    action   = "Allow"

    rule {
      name                  = "allow-dns"
      protocols             = ["UDP", "TCP"]
      source_addresses      = [var.hub_vnet_cidr, var.spoke_vnet_cidr]
      destination_addresses = ["168.63.129.16"]
      destination_ports     = ["53"]
    }
  }
}

# Public IP for data traffic
resource "azurerm_public_ip" "firewall" {
  name                = "pip-firewall-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

# Public IP for management traffic
# Basic SKU requires a separate management public IP
resource "azurerm_public_ip" "firewall_management" {
  name                = "pip-firewall-mgmt-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

# ============================================================
# Azure Firewall Basic SKU
# Requires both ip_configuration AND management_ip_configuration
# ============================================================

resource "azurerm_firewall" "hub" {
  name                = "fw-hub-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_name            = "AZFW_VNet"
  sku_tier            = "Basic"
  firewall_policy_id  = azurerm_firewall_policy.hub.id

  # Data traffic configuration
  ip_configuration {
    name                 = "configuration"
    subnet_id            = var.firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }

  # Management traffic configuration - required for Basic SKU
  management_ip_configuration {
    name                 = "management"
    subnet_id            = var.firewall_management_subnet_id
    public_ip_address_id = azurerm_public_ip.firewall_management.id
  }

  tags = var.tags
}

# UDR - forces all spoke traffic through Firewall
resource "azurerm_route_table" "spoke" {
  name                          = "rt-spoke-${var.environment}"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  bgp_route_propagation_enabled = false

  route {
    name                   = "default-to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.hub.ip_configuration[0].private_ip_address
  }

  tags = var.tags
}

resource "azurerm_subnet_route_table_association" "spoke_workload" {
  subnet_id      = var.workload_subnet_id
  route_table_id = azurerm_route_table.spoke.id
}
