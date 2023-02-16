output "cache_secret" {
  value       = azurerm_redis_cache.cache.primary_access_key
  description = "The secret to use when connecting to Azure Cache for Redis"
}

output "cache_hostname" {
  value       = azurerm_redis_cache.cache.hostname
  description = "The hostname to use when connecting to Azure Cache for Redis"
}