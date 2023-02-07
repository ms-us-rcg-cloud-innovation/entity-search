variable "uniquefy" {
  type = bool
  description = "Append random string of 5 alpha-characters to specific resources to ensure global uniquness"
}

variable "location" {
  type = string
  description = "Azure region to deploy to"
}

variable "resource_group_name" {
 type = string
 description = "Name of resource group"
}

variable "cosmos_account_name" {
  type = string
  description = "Name of Cosmos resource to assign"
}

variable "search_service_name" {
  type = string
}

variable "database_name" {
  type = string
}

variable "container_name" {
  type = string
}

variable "partition_key_path" {
  type = string
}

variable "index_definition_file" {
  type = string
}

variable "datasource_definition_file" {
  type = string
}

variable "indexer_definition_file" {
  type = string
}