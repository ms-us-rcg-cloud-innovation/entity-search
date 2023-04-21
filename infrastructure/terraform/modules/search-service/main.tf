locals {
  index_json = file(var.index_definition_file)
  index_raw  = jsondecode(local.index_json)
  index_name = local.index_raw.name

  datasource_json = file(var.datasource_definition_file)
  datasource_raw  = jsondecode(local.datasource_json)
  datasource_name = local.datasource_raw.name

  indexer_json = file(var.indexer_definition_file)
  indexer_raw  = jsondecode(local.indexer_json)
  indexer_name = local.indexer_raw.name
}


data "azurerm_cosmosdb_account" "db" {
  name                = var.cosmos_account_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_search_service" "search" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = "standard"
  public_network_access_enabled = true
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "cosmos_reader" {
  scope                = data.azurerm_cosmosdb_account.db.id
  role_definition_name = "Cosmos DB Account Reader Role"
  principal_id         = azurerm_search_service.search.identity[0].principal_id
}

resource "null_resource" "configure_index" {
  provisioner "local-exec" {
    # indexes provisioner
    command = "${path.module}/_provisioner.ps1 -ServiceName ${azurerm_search_service.search.name} -Definition '${local.index_json}' -ResourceType Index"
    interpreter = [
      "pwsh", "-Command"
    ]
    environment = {
      AZSEARCH_ADMIN_KEY = azurerm_search_service.search.primary_key
    }
    on_failure = fail
  }

  provisioner "local-exec" {
    # datasource provisioner
    command = "${path.module}/_provisioner.ps1 -ServiceName ${azurerm_search_service.search.name} -Definition '${local.datasource_json}' -ResourceType DataSource"
    interpreter = [
      "pwsh", "-Command"
    ]
    environment = {
      AZSEARCH_ADMIN_KEY         = azurerm_search_service.search.primary_key
      COSMOS_DB_CONNECTIONSTRING = "ResourceId=${data.azurerm_cosmosdb_account.db.id};Database=${var.cosmos_account_database}"
    }
    on_failure = fail
  }

  provisioner "local-exec" {
    # indexer provisioner
    command = "${path.module}/_provisioner.ps1 -ServiceName ${azurerm_search_service.search.name} -Definition '${local.indexer_json}' -ResourceType Indexer"
    interpreter = [
      "pwsh", "-Command"
    ]
    environment = {
      AZSEARCH_ADMIN_KEY = azurerm_search_service.search.primary_key
    }
    on_failure = fail
  }

  depends_on = [
    azurerm_search_service.search,
    azurerm_role_assignment.cosmos_reader
  ]
}
