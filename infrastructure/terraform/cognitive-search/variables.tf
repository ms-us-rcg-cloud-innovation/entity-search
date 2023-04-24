variable "uniquefy" {
  type = bool
  description = "Append random string of 5 alpha-characters to specific resources to ensure global uniquness"
  default = true
}

variable "location" {
  type = string
  description = "Azure region to deploy to"
}

variable "resource_group_name" {
 type = string
 description = "Name of resource group"
 default = "azure-entity-search"
}

variable "appstate_sa_name" {
  type = string
  description = "Name of Azure Storage Account for function states to deploy"
  default = "appstatasa"
}

variable "search_function_name" {
  type = string
  description = "Name to assing to the search API function"
  default =  "search-api"
}

variable "change_feed_function_name" {
  type = string
  description = "Name to assing to the change feed processor function"
  default = "change-feed-processor"
}

variable "cosmos_account_name" {
  type = string
  description = "Cosmos account name"
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
  description = "Partition key for Azure Search connected Comsmos DB container. Must be in format '/<key>'. Ex: /id"
}

variable "search_service_name" {
  type = string
  description = "Name of the Azure service"
  default = "entity-search"
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