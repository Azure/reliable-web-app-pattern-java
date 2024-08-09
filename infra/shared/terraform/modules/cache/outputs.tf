output "cache_id" {
  value       = azurerm_redis_cache.cache.id
  description = "The id of the Azure Cache for Redis"
}

output "cache_hostname" {
  value       = azurerm_redis_cache.cache.hostname
  description = "The hostname to use when connecting to Azure Cache for Redis"
}

output "cache_ssl_port" {
  value       = azurerm_redis_cache.cache.ssl_port
  description = "The ssl port to use when connecting to Azure Cache for Redis"
}