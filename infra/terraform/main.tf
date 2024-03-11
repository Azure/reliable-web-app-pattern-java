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
  prod_enable_telemetry = var.environment == "prod" ? var.enable_telemetry : false
  dev_enable_telemetry = var.environment == "dev" ? var.enable_telemetry : false
}

resource "azurerm_resource_group_template_deployment" "deploymenttelemetry" {
  count               = local.prod_enable_telemetry ? 1 : 0
  name                = local.telemetryId
  resource_group_name = azurerm_resource_group.hub[0].name
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

resource "azurerm_resource_group_template_deployment" "dev_deploymenttelemetry" {
  count               = local.dev_enable_telemetry ? 1 : 0
  name                = local.telemetryId
  resource_group_name = azurerm_resource_group.dev[0].name
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

resource "azurecaf_name" "dev_resource_group" {
  count         = var.environment == "dev" ? 1 : 0
  name          = var.application_name
  resource_type = "azurerm_resource_group"
  suffixes      = ["dev"]
}

resource "azurerm_resource_group" "dev" {
  count    = var.environment == "dev" ? 1 : 0
  name     = azurecaf_name.dev_resource_group[0].result
  location = var.location
  tags     = local.base_tags
}

resource "null_resource" "fround_door_route_approval_app1" {
  count = var.environment == "prod" ? 1 : 0
  
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "bash ../scripts/front-door-route-approval.sh ${azurerm_resource_group.spoke[0].name}"
  }

  depends_on = [
    module.frontdoor,
    module.application
  ]
}


resource "null_resource" "fround_door_route_approval_app2" {
  count = var.environment == "prod" ? 1 : 0
  
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "bash ../scripts/front-door-route-approval.sh ${azurerm_resource_group.secondary_spoke[0].name}"
  }

  depends_on = [
    module.frontdoor,
    module.secondary_application
  ]
}