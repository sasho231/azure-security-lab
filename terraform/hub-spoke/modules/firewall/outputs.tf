output "firewall_private_ip" {
  description = "Firewall private IP - used as next hop in UDRs"
  value       = azurerm_firewall.hub.ip_configuration[0].private_ip_address
}

output "firewall_public_ip" {
  description = "Firewall public IP"
  value       = azurerm_public_ip.firewall.ip_address
}

output "firewall_policy_id" {
  description = "Firewall Policy ID"
  value       = azurerm_firewall_policy.hub.id
}

output "route_table_id" {
  description = "Spoke route table ID"
  value       = azurerm_route_table.spoke.id
}
