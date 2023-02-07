resource "azurerm_search_service" "search" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "standard"

  provisioner "local-exec" {
    # indexes provisioner
    command = "${path.module}/_provisioner.ps1 -ServiceName ${azurerm_search_service.search.name} -DefinitionFile '${var.index_definition_file}' -APIVersion '2020-06-30' -ResourceType Index"
    interpreter = [
      "pwsh", "-Command"
    ]
    environment = {
      AZSEARCH_ADMIN_KEY = azurerm_search_service.search.primary_key
    }
  }

  provisioner "local-exec" {
    # datasource provisioner
    command = "${path.module}/_provisioner.ps1 -ServiceName ${azurerm_search_service.search.name} -DefinitionFile '${var.datasource_definition_file}' -APIVersion '2020-06-30' -ResourceType DataSource"
    interpreter = [
      "pwsh", "-Command"
    ]
    environment = {
      AZSEARCH_ADMIN_KEY = azurerm_search_service.search.primary_key
      COSMOS_DB          = var.cosmosdb_connectionstring
    }
  }

  provisioner "local-exec" {
    # indexer provisioner
    command = "${path.module}/_provisioner.ps1 -ServiceName ${azurerm_search_service.search.name} -DefinitionFile '${var.indexer_definition_file}' -APIVersion '2020-06-30' -ResourceType Indexer"
    interpreter = [
      "pwsh", "-Command"
    ]
    environment = {
      AZSEARCH_ADMIN_KEY = azurerm_search_service.search.primary_key
    }
    on_failure = continue
  }
}
