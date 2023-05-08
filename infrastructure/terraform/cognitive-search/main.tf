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
  appstate_sa_name     = "${var.appstate_sa_name}${random_string.rand.result}"
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
  cosmos_account_name        = local.cosmos_acccount_name
  cosmos_account_database    = var.database_name

  depends_on = [
    module.cosmosdb
  ]
}

resource "azurerm_storage_account" "appstate" {
  name                      = local.appstate_sa_name
  resource_group_name       = azurerm_resource_group.cog_search.name
  location                  = azurerm_resource_group.cog_search.location
  account_tier              = "Standard"
  account_replication_type  = "ZRS"
  enable_https_traffic_only = true
  min_tls_version           = "TLS1_2"

  access_tier = "Hot"
}

module "search-func" {
  source              = "../modules/isolated-dotnet-linux-function"
  service_plan_name   = var.search_function_name
  app_name            = var.search_function_name
  resource_group_name = azurerm_resource_group.cog_search.name
  location            = azurerm_resource_group.cog_search.location
  dotnet_version      = "6.0"
  host_sku            = "EP1"
  app_settings = {
    "SEARCH_INDEX_NAME"               = module.search.index_name
    "SEARCH_CREDENTIAL_KEY"           = module.search.credential_key
    "SEARCH_ENDPOINT"                 = module.search.endpoint
    "COSMOSDB_DATABASE_NAME"          = var.database_name
    "COSMOSDB_CONTAINER_NAME"         = var.container_name
    "COSMOSDB_CONNECTION_STRING"      = module.cosmosdb.primary_connectionstring
    "COSMOSDB_CONTAINER_PARTITIONKEY" = var.partition_key_path
    # run function from package file as described here: 
    # https://learn.microsoft.com/en-us/azure/azure-functions/run-functions-from-deployment-package
    # General considerations of running from package
    # https://learn.microsoft.com/en-us/azure/azure-functions/run-functions-from-deployment-package#general-considerations
    "WEBSITE_RUN_FROM_PACKAGE"        = 1

    // site configs
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = false
  }
  sa_key  = azurerm_storage_account.appstate.primary_access_key
  sa_name = azurerm_storage_account.appstate.name
}

module "change-feed-func" {
  source              = "../modules/isolated-dotnet-linux-function"
  service_plan_name   = var.change_feed_function_name
  app_name            = var.change_feed_function_name
  resource_group_name = azurerm_resource_group.cog_search.name
  location            = azurerm_resource_group.cog_search.location
  dotnet_version      = "6.0"
  host_sku            = "EP1"
  app_settings = {
    "SEARCH_INDEX_NAME"               = module.search.index_name
    "SEARCH_CREDENTIAL_KEY"           = module.search.credential_key
    "SEARCH_ENDPOINT"                 = module.search.endpoint
    "COSMOSDB_DATABASE_NAME"          = var.database_name
    "COSMOSDB_CONTAINER_NAME"         = var.container_name
    "COSMOSDB_CONNECTION_STRING"      = module.cosmosdb.primary_connectionstring
    "COSMOSDB_CONTAINER_PARTITIONKEY" = var.partition_key_path
    "COSMOSDB_LEASE_CONTAINER_NAME"   = "changed-feed"
    # run function from package file as described here: 
    # https://learn.microsoft.com/en-us/azure/azure-functions/run-functions-from-deployment-package
    # General considerations of running from package
    # https://learn.microsoft.com/en-us/azure/azure-functions/run-functions-from-deployment-package#general-considerations
    "WEBSITE_RUN_FROM_PACKAGE"        = 1

    "SearchIndexerOptions__InitialBatchActionCount"  = 500,
    "SearchIndexerOptions__MaxRetriesPerIndexAction" = 3,
    "SearchIndexerOptions__ThrottlingDelay"          = "0.00:00:05",
    "SearchIndexerOptions__MaxThrottlingDelay"       = "0.00:01:00"

    // site config
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = false
  }
  sa_key  = azurerm_storage_account.appstate.primary_access_key
  sa_name = azurerm_storage_account.appstate.name
}
