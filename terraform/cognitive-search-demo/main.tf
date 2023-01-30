terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  suffix               = var.uniquefy ? "-${random_string.rand.result}" : ""
  resource_group_name  = "${var.resource_group_name}${local.suffix}"
  cosmos_acccount_name = "${var.cosmos_account_name}${local.suffix}"
  search_service_name  = "${var.search_service_name}${local.suffix}"
  database_name        = "${var.database_name}${local.suffix}"
  container_name       = "${var.container_name}${local.suffix}"
  partition_key_path   = var.partition_key_path

}

resource "random_string" "rand" {
  length  = 5
  lower   = true
  upper   = false
  numeric = false
  special = false
}

resource "azurerm_resource_group" "cog_search" {
  name     = local.resource_group_name
  location = var.location
}

module "cosmosdb" {
  source              = "../modules/cosmosdb"
  resource_group_name = azurerm_resource_group.cog_search.name
  location            = azurerm_resource_group.cog_search.location
  cosmos_account_name = local.cosmos_acccount_name
  database_name       = local.database_name
  container_name      = local.container_name
  partition_key_path  = local.partition_key_path
}

module "search" {
  source                     = "../modules/search-service"
  name                       = local.search_service_name
  resource_group_name        = azurerm_resource_group.cog_search.name
  location                   = azurerm_resource_group.cog_search.location
  index_definition_file      = "../../data/search-demo/products-index.json"
  datasource_definition_file = "../../data/search-demo/products-datasource.json"
  indexer_definition_file    = "../../data/search-demo/products-indexer.json"
}
