# ============================================================
# Web Application VM Module
# Ubuntu 22.04 LTS running Flask web application
# No public IP - access via Bastion only
# ADR-004: docs/adr/ADR-004-web-application-vm.md
# MCSB: PV-4, LT-1, LT-2
# ============================================================

# ============================================================
# Managed Identity
# Allows VM to authenticate to Azure services without
# storing credentials anywhere - Zero Trust principle
# Used for Key Vault access in Phase 4
# ============================================================

resource "azurerm_user_assigned_identity" "vm_app" {
  name                = "id-vm-app-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = var.tags
}

# ============================================================
# Network Interface
# Attached to snet-app-lab
# No public IP - only private IP
# ============================================================

resource "azurerm_network_interface" "app" {
  name                = "nic-vm-app-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.app_subnet_id
    private_ip_address_allocation = "Dynamic"
    # No public_ip_address_id - intentionally omitted
  }

  tags = var.tags
}

# ============================================================
# Linux Virtual Machine
# Ubuntu 22.04 LTS - B2s SKU for cost efficiency
# cloud-init deploys Flask app on first boot
# ============================================================

resource "azurerm_linux_virtual_machine" "app" {
  name                = "vm-app-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_D2as_v4"

  # Admin account - SSH key only, no password
  # Password authentication disabled for security
  admin_username                  = var.admin_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  network_interface_ids = [azurerm_network_interface.app.id]

  # Managed Identity - allows VM to access Azure services
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.vm_app.id]
  }

  os_disk {
    name                 = "osdisk-vm-app-${var.environment}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"

    # Encrypt OS disk - MCSB DP-3
    # Uses platform managed keys (PMK) by default
    # Phase 4 upgrades to customer managed keys (CMK)
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # cloud-init script runs on first boot
  # Installs Python, Flask and deploys the web application
  custom_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
    environment = var.environment
  }))

  tags = var.tags
}
