#!/usr/bin/env bash

STORAGE_PRIMARY_KEY=$(terraform -chdir=$PROJECT_ROOT/terraform output -raw storage_module_storage_primary_access_key)
STORAGE_ACCOUNT_NAME=$(terraform -chdir=$PROJECT_ROOT/terraform output -raw storage_module_storage_account_name)
STORAGE_SHARE_NAME=$(terraform -chdir=$PROJECT_ROOT/terraform output -raw application_storage_share_name)

echo "account $STORAGE_ACCOUNT_NAME share $STORAGE_SHARE_NAME"

TRAININGS_DIR=AllTrainings
PLAYLIST_DIR=playlists

az storage directory create --name $PLAYLIST_DIR --share-name $STORAGE_SHARE_NAME --account-name $STORAGE_ACCOUNT_NAME --account-key $STORAGE_PRIMARY_KEY
az storage directory create --name $TRAININGS_DIR --share-name $STORAGE_SHARE_NAME --account-name $STORAGE_ACCOUNT_NAME --account-key $STORAGE_PRIMARY_KEY

MEDIA_DIR=${PROJECT_ROOT}/trainings

for file in $MEDIA_DIR/*; do
  echo "Processing $file"

  if [[ -d $file ]]; then
    # Skip directories
    echo "Skipping directory $file"
    continue
  fi

  base_name=$(basename "${file}")

  # if it's a playlist, upload it to the playlist share
  if [[ $file == *.m3u8 ]]; then
    echo "Uploading playlist $base_name"
    az storage file upload --account-name $STORAGE_ACCOUNT_NAME --account-key $STORAGE_PRIMARY_KEY --share-name $STORAGE_SHARE_NAME --path "$PLAYLIST_DIR/$base_name" --source "$file"

  # if it's a training video, upload it to the incoming share
  elif [[ $file == *.mp4 ]]; then
    echo "Uploading video $base_name"
    az storage file upload --account-name $STORAGE_ACCOUNT_NAME --account-key $STORAGE_PRIMARY_KEY --share-name $STORAGE_SHARE_NAME --path "$TRAININGS_DIR/$base_name" --source "$file"

  # else print out unknown type
  else
    echo "Unknown type $base_name"

  fi
    
done