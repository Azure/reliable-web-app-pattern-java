output "database_server_id" {
  value       = azurerm_postgresql_flexible_server.postgresql_database.id
  description = "The id of the database server"
}

output "database_server_name" {
  value       = azurerm_postgresql_flexible_server.postgresql_database.name
  description = "The name of the database server"
}

output "database_fqdn" {
  value       = azurerm_postgresql_flexible_server.postgresql_database.fqdn
  description = "The FQDN of the database"
}

output "database_username" {
  value       = var.administrator_login
  description = "The DB server user name."
}
