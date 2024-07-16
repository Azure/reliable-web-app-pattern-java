variable "vm_name" {
  description = "name of the virtual machine"
}

variable "resource_group" {
  type        = string
  description = "The name of the resource group where all resources should be created."
}

variable "location" {
  type        = string
  description = "The location (Azure region) where the resources should be created."
}

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default     = {}
}

variable "admin_username" {
  type    = string
  default = null
}

variable "admin_password" {
  type    = string
  default = null
}

variable "subnet_id" {
  type = string
}

variable "size" {
  type    = string
  default = "Standard_B2ms"
}

variable "admin_principal_id" {
  type    = string
}
