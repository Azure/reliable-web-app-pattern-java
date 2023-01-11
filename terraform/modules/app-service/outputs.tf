output "application_url" {
  value       = "https://${azurerm_linux_web_app.application.default_hostname}"
  description = "The Web application URL."
}

output "application_fqdn" {
  value       = azurerm_linux_web_app.application.default_hostname
  description = "The Web application fully qualified domain name (FQDN)."
}


# Below are the values needed for the azure-webapp-maven-plugin in airsonic-main/pom.xml
output "application_name" {
  value       = azurerm_linux_web_app.application.name
  description = "The value for <appName> for the azure-webapp-maven-plugin in airsonic-main/pom.xml."
}

output "application_resource_group" {
  value       = azurerm_service_plan.application.resource_group_name
  description = "The value for <resourceGroup> for the azure-webapp-maven-plugin in airsonic-main/pom.xml."
}

output "application_region" {
  value       = azurerm_service_plan.application.location
  description = "The value for <region> for the azure-webapp-maven-plugin in airsonic-main/pom.xml."
}

output "application_pricing_tier" {
  value       = azurerm_service_plan.application.sku_name
  description = "The value for <pricingTier> for the azure-webapp-maven-plugin in airsonic-main/pom.xml."
}

output "application_runtime_webcontainer" {
  value       = "${azurerm_linux_web_app.application.site_config[0].application_stack[0].java_server} ${azurerm_linux_web_app.application.site_config[0].application_stack[0].java_server_version}"
  description = "The value for <runtime/webContainer> for the azure-webapp-maven-plugin in airsonic-main/pom.xml."
}

output "application_java_version" {
  value       = azurerm_linux_web_app.application.site_config[0].application_stack[0].java_version
  description = "The value for <runtime/javaVersion> for the azure-webapp-maven-plugin in airsonic-main/pom.xml."
}

output "application_registration_id" {
  value = azuread_application.app_registration.application_id
  description = "The id of application registration  (also called Client ID)."
}

output "airsonic_user" {
  value = azuread_user.airsonic_user.user_principal_name
  description = "The read-only user name."
}

output "airsonic_user_password" {
  value     = azuread_user.airsonic_user.password
  sensitive = true
  description = "The password of the read-only user."
}

output "airsonic_admin" {
  value = azuread_user.airsonic_admin.user_principal_name
  description = "The admin user name."
}

output "airsonic_admin_password" {
  value     = azuread_user.airsonic_admin.password
  sensitive = true
  description = "The password of the admin user."
}

#output "application_principal_id" {
#  value       = azurerm_linux_web_app.application.identity[0].principal_id
#  description = "The id of system assigned managed identity"
#}

