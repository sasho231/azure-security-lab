# ============================================================
# VNet Peering Module
# Connects Hub and Spoke VNets bidirectionally
# allow_forwarded_traffic enables Firewall to inspect
# spoke traffic (required for hub-spoke pattern)
# ============================================================

# Hub → Spoke peering
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "peer-hub-to-spoke"
  resource_group_name       = var.hub_resource_group
  virtual_network_name      = var.hub_vnet_name
  remote_virtual_network_id = var.spoke_vnet_id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
}

# Spoke → Hub peering
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "peer-spoke-to-hub"
  resource_group_name       = var.spoke_resource_group
  virtual_network_name      = var.spoke_vnet_name
  remote_virtual_network_id = var.hub_vnet_id
  allow_forwarded_traffic   = true
  use_remote_gateways       = false
}
