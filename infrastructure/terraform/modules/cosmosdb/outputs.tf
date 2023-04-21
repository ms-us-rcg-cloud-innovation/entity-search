output "primary_connectionstring" {
  value = azurerm_cosmosdb_account.cs.primary_sql_connection_string
}

output "secondary_connectionstring" {
  value = azurerm_cosmosdb_account.cs.secondary_readonly_sql_connection_string
}

output "database_name" {
  value = azurerm_cosmosdb_sql_database.db.name
}
