output "index_name" {
  value = local.index_name
}

output "indexer_name" {
  value = local.indexer_name
}

output "datasource_name" {
  value = local.datasource_name
}

output "credential_key" {
  value = azurerm_search_service.search.primary_key
}

output "endpoint" {
  value = "https://${azurerm_search_service.search.name}.search.windows.net"
}