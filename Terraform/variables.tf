variable "location" {
  default     = "eastus"
  description = "Location to be used for all the resources."
}

variable "resource_group_name" {
  default     = "rg_covid_project_28"
  description = "Resource group where all the other resources will be created."
}

variable "storage_account_name" {
  default     = "covid28datadl"
  description = "Storage account where the data will be stored"
}

variable "raw_data_container_name" {
  default     = "raw"
  description = "Container where raw data will be stored"
}

variable "processed_data_container_name" {
  default     = "processed"
  description = "Container where the data will be stored after processing"
}

variable "lookup_data_container_name" {
  default     = "lookup"
  description = "Container containing some data used to enrich the covid dataset"
}

variable "data_factory_name" {
  default     = "df-covid-project-28"
  description = "Data Factory instance that will orchestrate ingestion and transformation data processes"
}