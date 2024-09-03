# ------------------------------------------------
#  Identity for the Production Primary App Service
# ------------------------------------------------

resource "azurecaf_name" "primary_app_service_identity_name" {
  count         = var.environment == "prod" ? 1 : 0
  name          = var.application_name
  resource_type = "azurerm_user_assigned_identity"
  suffixes      = [var.location, var.environment]
}

resource "azurerm_user_assigned_identity" "primary_app_service_identity" {
  count               = var.environment == "prod" ? 1 : 0
  location            = azurerm_resource_group.spoke[0].location
  name                = azurecaf_name.primary_app_service_identity_name[0].result
  resource_group_name = azurerm_resource_group.spoke[0].name
}

# ------------------------------------------------
#  Identity for the Production Secondary App Service
# ------------------------------------------------

resource "azurecaf_name" "secondary_app_service_identity_name" {
  count         = var.environment == "prod" ? 1 : 0
  name          = var.application_name
  resource_type = "azurerm_user_assigned_identity"
  suffixes      = [var.secondary_location, var.environment]
}

resource "azurerm_user_assigned_identity" "secondary_app_service_identity" {
  count               = var.environment == "prod" ? 1 : 0
  location            = azurerm_resource_group.secondary_spoke[0].location
  name                = azurecaf_name.secondary_app_service_identity_name[0].result
  resource_group_name = azurerm_resource_group.secondary_spoke[0].name
}


# ------------------------------------------------
#  Identity for the Production Dev App Service
# ------------------------------------------------

resource "azurecaf_name" "dev_app_service_identity_name" {
  count         = var.environment == "dev" ? 1 : 0
  name          = var.application_name
  resource_type = "azurerm_user_assigned_identity"
  suffixes      = [var.location, var.environment]
}

resource "azurerm_user_assigned_identity" "dev_app_service_identity" {
  count               = var.environment == "dev" ? 1 : 0
  location            = azurerm_resource_group.dev[0].location
  name                = azurecaf_name.dev_app_service_identity_name[0].result
  resource_group_name = azurerm_resource_group.dev[0].name
}
