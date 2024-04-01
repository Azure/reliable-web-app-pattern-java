terraform {
  required_providers {
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.26"
    }
    azuread = {
      source = "hashicorp/azuread"
      version = "2.41.0"
    }
  }
}

data "azuread_client_config" "current" {}

resource "azurecaf_name" "app_service" {
  name          = var.application_name
  resource_type = "azurerm_app_service"
  suffixes      = [var.environment]
}

resource "random_uuid" "admin_role_id" {}
resource "random_uuid" "user_role_id" {}
resource "random_uuid" "creator_role_id" {}

resource "azuread_application" "app_registration" {
  display_name     = "${azurecaf_name.app_service.result}-app"
  owners           = [data.azuread_client_config.current.object_id]
  sign_in_audience = "AzureADMyOrg"  # single tenant

  app_role {
    allowed_member_types = ["User"]
    description          = "ReadOnly roles have limited query access"
    display_name         = "ReadOnly"
    enabled              = true
    id                   = random_uuid.user_role_id.result
    value                = "User"
  }

  app_role {
    allowed_member_types = ["User"]
    description          = "Creator roles allows users to create content"
    display_name         = "Creator"
    enabled              = true
    id                   = random_uuid.creator_role_id.result
    value                = "Creator"
  }

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read https://marketplace.visualstudio.com/items?itemName=stephane-eyskens.aadv1appprovisioning
      type = "Scope"
    }
  }

  web {
    homepage_url  = "https://${var.frontdoor_host_name}"
    logout_url    = "https://${var.frontdoor_host_name}/logout"
    redirect_uris = ["https://${var.frontdoor_host_name}/login/oauth2/code/"]
    implicit_grant {
      id_token_issuance_enabled     = true
    }
  }
}

resource "azuread_service_principal" "application_service_principal" {
  application_id               = azuread_application.app_registration.application_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "azuread_application_password" "application_password" {
  application_object_id = azuread_application.app_registration.object_id
}

# This is not guidance and is done for demo purposes. The resource below will add the 
# "Creator" app role assignment for the application of the current user deploying this sample.
resource "azuread_app_role_assignment" "application_role_current_user" {
  app_role_id         = azuread_service_principal.application_service_principal.app_role_ids["Creator"]
  principal_object_id = data.azuread_client_config.current.object_id
  resource_object_id  = azuread_service_principal.application_service_principal.object_id
}
