locals {
  // If an environment is set up (dev, test, prod...), it is used in the application name
  environment = var.environment == "" ? "dev" : var.environment
  telemetryId = "BB720B18-3C24-4D84-8C28-7AC01F4D7F2C-services-${var.location}"

  base_tags = merge({
    "terraform"         = true
    "environment"       = local.environment
    "application-name"  = var.application_name
    "contoso-version"   = "1.0"
    "app-pattern-name"  = "java-rwa"
    "azd-env-name"     = var.application_name
  }, var.tags)

  spoke_tokens              = split("/", var.spoke_vnet_id)
  spoke_subscription_id     = local.spoke_tokens[2]
  spoke_vnet_resource_group = local.spoke_tokens[4]
  spoke_vnet_name           = local.spoke_tokens[8]

  app_insights_tokens            = split("/", var.app_insights_id)
  app_insights_subscription_id   = local.app_insights_tokens[2]
  app_insights_resource_group    = local.app_insights_tokens[4]
  app_insights_name              = local.app_insights_tokens[8]

  // Read Replicas are currently supported for the General Purpose and Memory Optimized server compute tiers,
  // Burstable server compute tier is not supported. (https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-read-replicas)
  // The SKU therefore needs to be General Purpose for multi region deployments
  
  // TODO: multi region deployments are not supported yet
  postgresql_sku_name = var.environment == "prod" ? "GP_Standard_D4s_v3" : "B_Standard_B1ms"

  front_door_sku_name = "Premium_AzureFrontDoor"

  app_service_subnet_name   = "serverFarm"
  ingress_subnet_name       = "ingress"
  postgresql_subnet_name    = "fs"
  private_link_subnet_name  = "privateLink"
}