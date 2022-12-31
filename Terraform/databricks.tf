resource "azurerm_databricks_workspace" "db" {
  name                = var.databricks_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  sku                 = "standard"
}

resource "databricks_token" "pat" {
  comment          = "General purpose"
  lifetime_seconds = 5000000
  depends_on = [
    azurerm_databricks_workspace.db
  ]
}

data "databricks_spark_version" "latest_lts" {
  long_term_support = true

  depends_on = [
    azurerm_databricks_workspace.db
  ]
}

resource "databricks_cluster" "data_transformation_cluster" {
  cluster_name            = var.databricks_cluster_name
  node_type_id            = var.cluster_note_type
  spark_version           = data.databricks_spark_version.latest_lts.id
  autotermination_minutes = var.cluster_autotermination_minutes

  spark_conf = {
    "spark.databricks.cluster.profile" : "singleNode"
    "spark.master" : "local[*]"
  }

  custom_tags = {
    "ResourceClass" = "SingleNode"
  }
}

resource "databricks_secret_scope" "db_secre_scope" {
  name = "terraform"
}

resource "databricks_secret" "db_secret" {
  key          = "service_principal_key"
  string_value = azuread_service_principal_password.sp_pass.value
  scope        = databricks_secret_scope.db_secre_scope.name
}

resource "databricks_azure_adls_gen2_mount" "mount_gen2" {
  cluster_id             = databricks_cluster.data_transformation_cluster.id
  storage_account_name   = azurerm_storage_account.sa.name
  container_name         = azurerm_storage_container.raw_data_container.name
  mount_name             = "raw"
  tenant_id              = azuread_service_principal.service_principal.application_tenant_id
  client_id              = azuread_service_principal.service_principal.application_id
  client_secret_scope    = databricks_secret_scope.db_secre_scope.name
  client_secret_key      = databricks_secret.db_secret.key
  initialize_file_system = true
}

resource "databricks_mount" "processed" {
  name        = "processed"
  abfs {
    storage_account_name   = azurerm_storage_account.sa.name
    container_name         = azurerm_storage_container.processed_data_container.name
    tenant_id              = azuread_service_principal.service_principal.application_tenant_id
    client_id              = azuread_service_principal.service_principal.application_id
    client_secret_scope    = databricks_secret_scope.db_secre_scope.name
    client_secret_key      = databricks_secret.db_secret.key
    initialize_file_system = true
  }
}