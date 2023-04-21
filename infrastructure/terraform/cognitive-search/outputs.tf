# resource group values
output "resource_group_name" {
  value = azurerm_resource_group.cog_search.name
}

output "location" {
  value = azurerm_resource_group.cog_search.location
}

# search service values
output "search_service_name" {
  value = local.search_service_name
}

output "index_name" {
  value = module.search.index_name
}

output "indexer_name" {
  value = module.search.indexer_name
}

output "datasource_name" {
  value = module.search.datasource_name
}

output "search_endpoint" {
  value = module.search.endpoint
}

# cosmos db values
output "cosmosdb_account_name" {
  value = local.cosmos_acccount_name
}

output "cosmosdb_database_name" {
  value = var.database_name
}

output "cosmosdb_container_name" {
  value = var.container_name
}

# function values
output "appstate_sa_name" {
  value = local.appstate_sa_name
}

output "change_feed_function_name" {
    value = var.change_feed_function_name
}

output "search_function_name" {
    value = var.search_function_name
}