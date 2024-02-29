output "database_server_id" {
  value       = length(azurerm_postgresql_flexible_server.postgresql_database) > 0 ? azurerm_postgresql_flexible_server.postgresql_database[0].id : ""
  description = "The id of the database server"
}

output "database_name" {
  value       = length(azurerm_postgresql_flexible_server.postgresql_database) > 0 ? azurerm_postgresql_flexible_server.postgresql_database[0].name : ""
  description = "The name of the database server"
}

output "database_fqdn" {
  value       = length(azurerm_postgresql_flexible_server.postgresql_database) > 0 ? azurerm_postgresql_flexible_server.postgresql_database[0].fqdn : ""
  description = "The FQDN of the database"
}

output "database_username" {
  value       = var.administrator_login
  description = "The DB server user name."
}

output "dev_database_server_id" {
  value       = length(azurerm_postgresql_flexible_server.dev_postresql_database) > 0 ? azurerm_postgresql_flexible_server.dev_postresql_database[0].id : ""
  description = "The id of the database server"
}

output "dev_database_fqdn" {
  value       = length(azurerm_postgresql_flexible_server.dev_postresql_database) > 0 ? azurerm_postgresql_flexible_server.dev_postresql_database[0].fqdn : ""
  description = "The FQDN of the database"
}
