output "key_vault_id" {
  value = azurerm_key_vault.main.id
}

output "key_vault_name" {
  value = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  value = azurerm_key_vault.main.vault_uri
}

output "private_endpoint_ip" {
  description = "Private IP address of Key Vault Private Endpoint"
  value       = azurerm_private_endpoint.keyvault.private_service_connection[0].private_ip_address
}
