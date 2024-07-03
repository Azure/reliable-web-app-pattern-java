terraform {
  required_providers {
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.26"
    }
  }
}

data "azuread_client_config" "current" {}

resource "azurecaf_name" "app_service" {
  name          = var.application_name
  resource_type = "azurerm_app_service"
  suffixes      = [var.environment]
}

resource "random_uuid" "account_manager_role_id" {}
resource "random_uuid" "l1_role_id" {}
resource "random_uuid" "l2_role_id" {}
resource "random_uuid" "field_service_role_id" {}
resource "random_uuid" "business_owner_role_id" {}

resource "azuread_application" "app_registration" {
  display_name     = "${azurecaf_name.app_service.result}-app"
  owners           = [data.azuread_client_config.current.object_id]
  sign_in_audience = "AzureADMyOrg"  # single tenant

  app_role {
    allowed_member_types = ["User"]
    description          = "Account Managers"
    display_name         = "Account Manager"
    enabled              = true
    id                   = random_uuid.account_manager_role_id.result
    value                = "AccountManager"
  }

  app_role {
    allowed_member_types = ["User"]
    description          = "L1 Support representative"
    display_name         = "L1 Support"
    enabled              = true
    id                   = random_uuid.l1_role_id.result
    value                = "L1Support"
  }

  app_role {
    allowed_member_types = ["User"]
    description          = "L2 Support representative"
    display_name         = "L2 Support"
    enabled              = true
    id                   = random_uuid.l2_role_id.result
    value                = "L2Support"
  }

  app_role {
    allowed_member_types = ["User"]
    description          = "Field Service representative"
    display_name         = "Field Service"
    enabled              = true
    id                   = random_uuid.field_service_role_id.result
    value                = "FieldService"
  }

  app_role {
    allowed_member_types = ["User"]
    description          = "Business owner"
    display_name         = "Business Owner"
    enabled              = true
    id                   = random_uuid.business_owner_role_id.result
    value                = "BusinessOwner"
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

  service_management_reference = var.service_management_reference
}

resource "azuread_service_principal" "application_service_principal" {
  client_id = azuread_application.app_registration.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "azuread_application_password" "application_password" {
  application_id = azuread_application.app_registration.id
  end_date = timeadd(timestamp(), "4320h") # 6 months
}

# This is not guidance and is done for demo purposes. The resource below will add the
# "L1Support", "AccountManager", and "BusinessOwner" app role assignment for the application
# of the current user deploying this sample.
resource "azuread_app_role_assignment" "application_role_current_user" {
  app_role_id         = azuread_service_principal.application_service_principal.app_role_ids["AccountManager"]
  principal_object_id = data.azuread_client_config.current.object_id
  resource_object_id  = azuread_service_principal.application_service_principal.object_id
}

resource "azuread_app_role_assignment" "application_role_current_user_l1" {
  app_role_id         = azuread_service_principal.application_service_principal.app_role_ids["L1Support"]
  principal_object_id = data.azuread_client_config.current.object_id
  resource_object_id  = azuread_service_principal.application_service_principal.object_id
}

resource "azuread_app_role_assignment" "application_role_current_user_business_owner" {
  app_role_id         = azuread_service_principal.application_service_principal.app_role_ids["BusinessOwner"]
  principal_object_id = data.azuread_client_config.current.object_id
  resource_object_id  = azuread_service_principal.application_service_principal.object_id
}
