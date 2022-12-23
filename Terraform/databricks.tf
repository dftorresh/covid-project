resource "azurerm_databricks_workspace" "db" {
  name                = var.databricks_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  sku                 = "standard"
}