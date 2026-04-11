output "vm_private_ip" {
  description = "Private IP of the web application VM"
  value       = azurerm_network_interface.app.private_ip_address
}

output "vm_name" {
  description = "VM name"
  value       = azurerm_linux_virtual_machine.app.name
}

output "managed_identity_id" {
  description = "Managed Identity resource ID"
  value       = azurerm_user_assigned_identity.vm_app.id
}

output "managed_identity_principal_id" {
  description = "Managed Identity principal ID for RBAC assignments"
  value       = azurerm_user_assigned_identity.vm_app.principal_id
}
