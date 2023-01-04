output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}


output "sp_password" {
  value     = azuread_service_principal_password.sp_pass.value
  sensitive = true
}