data "azuread_client_config" "current" {}

resource "azuread_application" "service_principal_app" {
  display_name = var.service_principal_app_name
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "service_principal" {
  application_id               = azuread_application.service_principal_app.application_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal_password" "sp_pass" {
  service_principal_id = azuread_service_principal.service_principal.id
}