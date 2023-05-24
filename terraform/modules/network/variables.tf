variable "name" {
  type        = string
  description = "The name of the virtual network."
}

variable "resource_group" {
  type        = string
  description = "The resource group"
}

variable "location" {
  type        = string
  description = "The Azure region where all resources in this example should be created"
}

variable "vnet_cidr" {
  type        = list(string)
  description = "The address space that is used by the virtual network."
}

variable "subnets" {
  type = list(object({
    name        = string,
    subnet_cidr = list(string),
    service_endpoints = list(string),
    delegation = object({
      name = string,
      service_delegation = object({
        name = string,
        actions = list(string)
      })
    })
  }))

  description = "A list of subnets inside the virtual network."
}
