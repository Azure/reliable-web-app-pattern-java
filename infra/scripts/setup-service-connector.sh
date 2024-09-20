#!/usr/bin/env bash

source_id=$1
target_id=$2

random_string=$RANDOM
connection_name=postgresql_${RANDOM}

az webapp connection create postgres-flexible --connection ${connection_name} --source-id ${source_id} --target-id ${target_id} --client-type springBoot --system-identity