#!/usr/bin/env bash

export PROJECT_ROOT=${PWD}
export SUBSCRIPTION=
export APP_NAME=

# APP_ENVIRONMENT can either be prod or dev
export APP_ENVIRONMENT=dev

# Telemetry collection is on by default. To opt out, set ENABLE_TELEMETRY to false.
export ENABLE_TELEMETRY=true

export TRAININGS_DIR="$PROJECT_ROOT/videos"