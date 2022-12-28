data "azurerm_client_config" "current_rm" {}
data "azuread_client_config" "current_ad" {}

resource "azurerm_key_vault" "key_vault" {
  name                       = var.key_vault_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current_rm.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 30
  depends_on                 = [azurerm_resource_group.rg]

  access_policy {
    tenant_id = data.azurerm_client_config.current_rm.tenant_id
    object_id = data.azuread_client_config.current_ad.object_id

    key_permissions = [
      "Create",
      "Get",
    ]

    secret_permissions = [
      "Set",
      "Get",
      "Delete",
      "Purge",
      "Recover",
      "List"
    ]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current_rm.tenant_id
    object_id    = azurerm_data_factory.adf.identity.principal_id

    secret_permissions = [
      "Get",
      "List"
    ]
  }
}

resource "azurerm_key_vault_secret" "covid_projectapp_secret" {
  name         = "covid-project28-secret"
  value        = azuread_service_principal_password.sp_pass.value
  key_vault_id = azurerm_key_vault.key_vault.id
}

