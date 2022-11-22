output "application_url" {
  value       = module.application.application_url
  description = "The Web application URL."
}

output "resource_group" {
  value       = azurerm_resource_group.main.name
  description = "The resource group."
}

output "app_service_module_outputs" {
  value = module.application
}

output "postresql_database_module_outputs" {
  value = module.postresql_database.database_url
}

output "keyvault_module_outputs" {
  value = module.key-vault
}

output "storage_module_storage_account_name" {
  value = module.storage.storage_account_name
}

#output "storage_module_storage_dns_a_record" {
#  value = module.storage.storage_dns_a_record
#}

