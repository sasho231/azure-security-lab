output "appgw_public_ip" {
  description = "Application Gateway public IP - use this to access the app"
  value       = azurerm_public_ip.appgw.ip_address
}

output "appgw_name" {
  description = "Application Gateway name"
  value       = azurerm_application_gateway.main.name
}

output "waf_policy_id" {
  description = "WAF Policy resource ID"
  value       = azurerm_web_application_firewall_policy.main.id
}
