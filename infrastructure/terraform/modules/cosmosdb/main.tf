resource "azurerm_cosmosdb_account" "cs" {
  name                      = var.cosmos_account_name
  location                  = var.location
  resource_group_name       = var.resource_group_name
  offer_type                = "Standard"
  kind                      = "GlobalDocumentDB"
  enable_automatic_failover = false
  geo_location {
    location          = var.location
    failover_priority = 0
  }
  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }
}

resource "azurerm_cosmosdb_sql_database" "db" {
  name                = var.database_name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.cs.name
  throughput          = 500
}

resource "azurerm_cosmosdb_sql_container" "items" {
  name                  = var.container_name
  resource_group_name   = var.resource_group_name
  account_name          = azurerm_cosmosdb_account.cs.name
  database_name         = azurerm_cosmosdb_sql_database.db.name
  partition_key_path    = var.partition_key_path
  partition_key_version = 1
  throughput            = 500

  indexing_policy {
    indexing_mode = "consistent"
    included_path {
      path = "/*"
    }

    included_path {
      path = "/included/?"
    }

    excluded_path {
      path = "/excluded/?"
    }
  }

  unique_key {
    paths = ["/definition/idlong", "/definition/idshort"]
  }
}