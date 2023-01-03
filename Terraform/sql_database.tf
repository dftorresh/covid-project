resource "azurerm_mssql_server" "sql_server" {
  name                         = var.sql_server_name
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = "aduser"
  administrator_login_password = "&UserPass123&"
}

resource "azurerm_mssql_firewall_rule" "allow_my_public_ip" {
  name             = "my_ip"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = "186.114.44.183"
  end_ip_address   = "186.114.44.183"
}

resource "azurerm_mssql_firewall_rule" "allow_az_resources" {
  name                = "allow-azure-service"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_mssql_database" "sql_database" {
  name           = var.sql_database_name
  server_id      = azurerm_mssql_server.sql_server.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 2
  sku_name       = "Basic"
  geo_backup_enabled = false
  storage_account_type = "LRS"
  zone_redundant = false
}
