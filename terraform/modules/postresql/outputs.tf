output "database_url" {
  value       = "${azurerm_postgresql_flexible_server.postresql_database.fqdn}:5432/${azurerm_postgresql_flexible_server_database.postresql_database.name}"
  description = "The MySQL server URL."
}

output "database_id" {
  value       = azurerm_postgresql_flexible_server_database.postresql_database.id
  description = "The id of the database"
}

output "database_server_name" {
  value       = azurerm_postgresql_flexible_server.postresql_database.name
  description = "The name of the database server"
}

output "database_fqdn" {
  value       = azurerm_postgresql_flexible_server.postresql_database.fqdn
  description = "The FQDN of the database"
}

output "database_name" {
  value       = azurerm_postgresql_flexible_server_database.postresql_database.name
  description = "The name of the database"
}

output "database_username" {
  value       = var.administrator_login
  description = "The DB server user name."
}

output "database_password" {
  value       = random_password.password.result
  sensitive   = true
  description = "The DB server password."
}
