variable "resource_group" {
  type        = string
  description = "The resource group"
}

variable "location" {
  type        = string
  description = "The Azure region where all resources in this example should be created"
}

variable "app_service_name" {
  type        = string
  description = "The name of your application"
}

variable "appsvc_webapp_id" {
  type        = string
  description = "The id of the app service"
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "The resourceId for a subnet in an Azure vnet that will be used for private endpoints"
}

variable "private_dns_resource_group" {
  type        = string
  description = "The resource group where the private dns zone is created"
}