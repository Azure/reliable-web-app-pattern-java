#!/usr/bin/env bash

# The ID of your Azure Subscription, https://learn.microsoft.com/azure/azure-portal/get-subscription-tenant-id
export SUBSCRIPTION_ID=

# The APP_NAME is used as the base for naming Azure resources. There is a limit to keep APP_NAME to less than 18 characters.
export APP_NAME=

# The DATABASE_PASSWORD is used for the password associated with the PostgreSQL Flexible Server.
export DATABASE_PASSWORD=

# APP_ENVIRONMENT can either be prod or dev
export APP_ENVIRONMENT=dev

# Telemetry collection is on by default. To opt out, set ENABLE_TELEMETRY to false.
export ENABLE_TELEMETRY=true

export PROJECT_ROOT=${PWD}
export TRAININGS_DIR="$PROJECT_ROOT/videos"
