variable "resource_group" {
  type        = string
  description = "The resource group"
}

variable "azure_ad_tenant_id" {
  type        = string
  description = "The AD tenant id"
}

variable "azure_ad_object_id" {
  type        = string
  description = "The AD object id"
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

variable "airsonic_database_admin" {
  type        = string
  description = "The airsonic admin database username"
}

variable "airsonic_database_admin_password" {
  type        = string
  description = "The airsonic admin database password"
}

variable "airsonic_database_server" {
  type        = string
  description = "The airsonic database server"
}

variable "airsonic_database_dbname" {
  type        = string
  description = "The airsonic database name"
}