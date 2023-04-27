#!/usr/bin/env bash

# This script will upload training vidoes stored on the local file system to Proseware.  This assumes that the download-tranings.sh script was previously executed.
# This is intended for demo purposes.

TRAININGS_DIR="videos"

STORAGE_PRIMARY_KEY=$(azd env get-values --output json | jq -r .storage_module_storage_primary_access_key)
STORAGE_ACCOUNT_NAME=$(azd env get-values --output json | jq -r .storage_module_storage_account_name)

VIDEO_STORAGE_SHARE_NAME=$(azd env get-values --output json | jq -r .application_video_share_nameaform output -raw application_video_share_name)
PLAYLIST_STORAGE_SHARE_NAME=$(azd env get-values --output json | jq -r .application_playlist_share_name)

echo "account $STORAGE_ACCOUNT_NAME video share $VIDEO_STORAGE_SHARE_NAME playlist share $PLAYLIST_STORAGE_SHARE_NAME"

ALL_TRAININGS_DIR=AllTrainings

az storage directory create --name $ALL_TRAININGS_DIR --share-name $VIDEO_STORAGE_SHARE_NAME --account-name $STORAGE_ACCOUNT_NAME --account-key $STORAGE_PRIMARY_KEY

echo "Uploading videos"
for file in $TRAININGS_DIR/*; do
  echo "Processing $file"

  if [[ -d $file ]]; then
    # Skip directories
    echo "Skipping directory $file"
    continue
  fi

  base_name=$(basename "${file}")

  # if it's a training video, upload it to the incoming share
  if [[ $base_name == *.mp4 ]]; then
    echo "Uploading video $base_name"
    az storage file upload --account-name $STORAGE_ACCOUNT_NAME --account-key $STORAGE_PRIMARY_KEY --share-name $VIDEO_STORAGE_SHARE_NAME --path "$ALL_TRAININGS_DIR/$base_name" --source "$file"

  # else print out unknown type
  else
    echo "Skipping unknown type $base_name"
  fi
    
done

PLAYLIST_DIR=${PROJECT_ROOT}/trainings
echo "Uploading playlists"

for file in $PLAYLIST_DIR/*; do
  echo "Processing $file"

  if [[ -d $file ]]; then
    # Skip directories
    echo "Skipping directory $file"
    continue
  fi

  base_name=$(basename "${file}")

  # if it's a playlist, upload it to the playlist share
  if [[ $base_name == *.m3u8 ]]; then
    echo "Uploading playlist $base_name"
    az storage file upload --account-name $STORAGE_ACCOUNT_NAME --account-key $STORAGE_PRIMARY_KEY --share-name $PLAYLIST_STORAGE_SHARE_NAME --path "$base_name" --source "$file"

  # else print out unknown type
  else
    echo "Unknown type $base_name"
  fi
    
done