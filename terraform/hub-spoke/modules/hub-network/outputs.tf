output "hub_vnet_id" {
  description = "Hub VNet resource ID"
  value       = azurerm_virtual_network.hub.id
}

output "hub_vnet_name" {
  description = "Hub VNet name"
  value       = azurerm_virtual_network.hub.name
}

output "firewall_subnet_id" {
  description = "Firewall subnet ID"
  value       = azurerm_subnet.firewall.id
}

output "firewall_management_subnet_id" {
  description = "Firewall management subnet ID"
  value       = azurerm_subnet.firewall_management.id
}

output "bastion_subnet_id" {
  description = "Bastion subnet ID"
  value       = azurerm_subnet.bastion.id
}

output "bastion_host_name" {
  description = "Bastion host name - null if not deployed"
  value       = var.deploy_bastion ? azurerm_bastion_host.hub[0].name : null
}
