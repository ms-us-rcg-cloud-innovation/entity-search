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
  database_name       = var.database_name
  container_name      = var.container_name
  partition_key_path  = var.partition_key_path
}

module "search" {
  source                     = "../modules/search-service"
  name                       = local.search_service_name
  resource_group_name        = azurerm_resource_group.cog_search.name
  location                   = azurerm_resource_group.cog_search.location
  index_definition_file      = var.index_definition_file
  datasource_definition_file = var.datasource_definition_file
  indexer_definition_file    = var.indexer_definition_file
  cosmosdb_connectionstring  = "${module.cosmosdb.db_connectionstring}Database=${var.database_name}"

  depends_on = [
    module.cosmosdb
  ]
}
