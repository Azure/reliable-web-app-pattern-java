variable "name" {
  default = ""
  type    = string
  validation {
    condition     = length(var.name) >= 2 && length(var.name) <= 32
    error_message = "Name must be at least 2 characters long and not longer than 32."

  }
}

variable "location" {
  default = "eastus"
  type    = string
}

variable "resource_group" {
  default = ""
  type    = string
}

variable "vnet_cidr" {
  type        = list(string)
  description = "The address space that is used by the virtual network."
}

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default     = {}
}

variable "subnets" {
  type = list(object({
    name        = string,
    subnet_cidr = list(string),
    delegation = object({
      name = string,
      service_delegation = object({
        name    = string,
        actions = list(string)
      })
    })
  }))

  description = "A list of subnets inside the virtual network."
}