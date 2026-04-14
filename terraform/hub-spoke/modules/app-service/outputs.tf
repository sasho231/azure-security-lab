output "app_service_url" {
  description = "App Service default URL"
  value       = "https://${azurerm_linux_web_app.main.default_hostname}"
}

output "app_service_name" {
  description = "App Service name"
  value       = azurerm_linux_web_app.main.name
}

output "managed_identity_principal_id" {
  description = "System-assigned managed identity principal ID"
  value       = azurerm_linux_web_app.main.identity[0].principal_id
}
