output "db_connectionstring" {
  value = azurerm_cosmosdb_account.cs.primary_sql_connection_string
}

output "db_name" {
  value = azurerm_cosmosdb_sql_database.db.name
}