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
  description = "Name of the Azure service"
}

variable "database_name" {
  type = string
  description = "Name of database to be created in Cosmos"
}

variable "container_name" {
  type = string
  description = "Name of initial container in database"
}

variable "partition_key_path" {
  type = string
  description = "Partition key for the container. Must be in format '/<key>'. Ex: /id"
}

variable "index_definition_file" {
  type = string
  description = "Index definition file to be used by Search service. This file declares all the indexed fieds of your data"
}

variable "datasource_definition_file" {
  type = string
  description = "Data source definition file to be used by Search service. This includes connection and container details"
}

variable "indexer_definition_file" {
  type = string
  description = "Indexer definition for crawling and indexing data in your data source. Indexer description must use the defined indexes from your index file"
}