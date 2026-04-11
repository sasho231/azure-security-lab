output "spoke_vnet_id" {
  value = azurerm_virtual_network.spoke.id
}

output "spoke_vnet_name" {
  value = azurerm_virtual_network.spoke.name
}

output "workload_subnet_id" {
  value = azurerm_subnet.workload.id
}

output "appgw_subnet_id" {
  value = azurerm_subnet.appgw.id
}

output "app_subnet_id" {
  value = azurerm_subnet.app.id
}

output "data_subnet_id" {
  value = azurerm_subnet.data.id
}
