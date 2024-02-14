terraform {
  backend "azurerm" {
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }

    virtual_machine {
      delete_os_disk_on_deletion     = true
      graceful_shutdown              = false
      skip_shutdown_and_force_delete = true
    }
  }
}

data "azuread_client_config" "current" {}

data "http" "myip" {
  url = "https://api.ipify.org"
}

locals {
  myip = chomp(data.http.myip.response_body)
  mynetwork = "${cidrhost("${local.myip}/16", 0)}/16"
}

resource "azurerm_resource_group_template_deployment" "deploymenttelemetry" {
  count               = var.enable_telemetry ? 1 : 0
  name                = local.telemetryId
  resource_group_name = azurerm_resource_group.hub.name
  deployment_mode     = "Incremental"
  
  template_content = <<TEMPLATE
  {
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {},
    "variables": {},
    "resources": []
  }
  TEMPLATE
}