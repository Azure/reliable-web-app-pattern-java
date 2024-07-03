variable "application_name" {
  type        = string
  description = "The name of your application"
}

variable "environment" {
  type        = string
  description = "The environment (dev, test, prod...)"
}

variable "frontdoor_host_name" {
  type        = string
  description = "The front door host name"
}

variable "service_management_reference" {
  type = string
  description = "value for the service management reference"
  default = null
}
