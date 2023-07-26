variable "resource_group" {
  type        = string
  description = "The resource group"
}

variable "application_name" {
  type        = string
  description = "The name of your application"
}

variable "environment" {
  type        = string
  description = "The environment (dev, test, prod...)"
  default     = "dev"
}

variable "location" {
  type        = string
  description = "The Azure region where all resources in this example should be created"
}

variable "database_name" {
  type        = string
  description = "The name of the database"
}

variable "database_fqdn" {
  type        = string
  description = "The FQDN of the database"
}

variable "redis_host" {
  type        = string
  description = "The redis host"
}

variable "redis_port" {
  type        = number
  description = "The redis port"
}

variable "storage_account_name" {
  type        = string
  description = "The name of the storage account"
}

variable "storage_account_primary_access_key" {
  type        = string
  description = "The storage account access key"
}

variable "subnet_id" {
  type        = string
  description = "The id of the subnet for the application"
}

variable "key_vault_uri" {
  type        = string
  description = "The uri of the key vault"
}

variable "frontdoor_host_name" {
  type        = string
  description = "The front door host name"
}

variable "frontdoor_profile_uuid" {
  type        = string
  description = "The UUID of this Front Door Profile which will be sent in the HTTP Header as the X-Azure-FDID attribute.."
}

variable "app_insights_connection_string" {
  type        = string
  description = "The app insights connection string"
}

variable "trainings_share_name" {
  type        = string
  description = "The name of the share for training material"
}

variable "playlist_share_name" {
  type        = string
  description = "The name of the share for playlists"
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "The id of the log analytics workspace"
}

variable "proseware_client_id" {
  type = string
  description = "Azure AD App Registration: clientId"
}

variable "proseware_tenant_id" {
  type = string
  description = "Azure AD App Registration: tenantId"
}