# Spoke Network Module
# Contains: Spoke VNet, Workload subnet, NSG deny-all default
# MCSB: NS-1 network segmentation
# Zero Trust: no implicit trust between subnets
# ============================================================

resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-spoke-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.spoke_vnet_cidr]

  tags = var.tags
}

resource "azurerm_subnet" "workload" {
  name                 = "snet-workload-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [var.workload_subnet_cidr]
}

# ============================================================
# NSG with deny-all defaults
# Zero Trust principle: deny everything, allow explicitly
# MCSB NS-1: implement security boundaries
# All future workload access rules added here explicitly
# ============================================================

resource "azurerm_network_security_group" "workload" {
  name                = "nsg-workload-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow inbound SSH from Bastion subnet only
  # No direct SSH from internet - ever
  security_rule {
    name                       = "AllowSshFromBastion"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.2.0/26"
    destination_address_prefix = "*"
  }

  # Allow inbound RDP from Bastion subnet only
  security_rule {
    name                       = "AllowRdpFromBastion"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "10.0.2.0/26"
    destination_address_prefix = "*"
  }

  # Deny all other inbound - explicit deny-all
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "workload" {
  subnet_id                 = azurerm_subnet.workload.id
  network_security_group_id = azurerm_network_security_group.workload.id
}
