#!/usr/bin/env bash

# Invoked by AZD from the azure.yaml as a postprovision hook
# This script will upload training vidoes stored on the local file system to Proseware.  This assumes that the download-tranings.sh script was previously executed.
# This is intended for demo purposes.

green='\033[0;32m'
yellow='\e[0;33m'
red='\e[1;31m'
clear='\033[0m'

TRAININGS_DIR="videos"

STORAGE_PRIMARY_KEY=$(azd env get-values --output json | jq -r .storage_module_storage_primary_access_key)

if [[ $STORAGE_PRIMARY_KEY == 'null' ]]; then
  printf "${red}ERROR:${clear} STORAGE_PRIMARY_KEY could not be set from AZD env values\n\n"
  exit 1
else
  echo "loaded STORAGE_PRIMARY_KEY..."
fi

STORAGE_ACCOUNT_NAME=$(azd env get-values --output json | jq -r .storage_module_storage_account_name)

if [[ $STORAGE_ACCOUNT_NAME == 'null' ]]; then
  printf "${red}ERROR:${clear} STORAGE_ACCOUNT_NAME could not be set from AZD env values\n\n"
  exit 2
else
  echo "loaded STORAGE_ACCOUNT_NAME..."
fi

VIDEO_STORAGE_SHARE_NAME=$(azd env get-values --output json | jq -r .application_video_share_name)

if [[ $VIDEO_STORAGE_SHARE_NAME == 'null' ]]; then
  printf "${red}ERROR:${clear} VIDEO_STORAGE_SHARE_NAME could not be set from AZD env values\n\n"
  exit 3
else
  echo "loaded VIDEO_STORAGE_SHARE_NAME..."
fi

PLAYLIST_STORAGE_SHARE_NAME=$(azd env get-values --output json | jq -r .application_playlist_share_name)

if [[ $PLAYLIST_STORAGE_SHARE_NAME == 'null' ]]; then
  printf "${red}ERROR:${clear} PLAYLIST_STORAGE_SHARE_NAME could not be set from AZD env values\n\n"
  exit 4
else
  echo "loaded PLAYLIST_STORAGE_SHARE_NAME..."
fi

printf "account ${green}$STORAGE_ACCOUNT_NAME${clear} video share ${green}$VIDEO_STORAGE_SHARE_NAME${clear} playlist share ${green}$PLAYLIST_STORAGE_SHARE_NAME${clear}\n"

ALL_TRAININGS_DIR=AllTrainings

# Create directory if it doesn't exist
az storage directory create --name $ALL_TRAININGS_DIR --share-name $VIDEO_STORAGE_SHARE_NAME --account-name $STORAGE_ACCOUNT_NAME --account-key $STORAGE_PRIMARY_KEY

echo "Uploading videos"
# foreach MP4 file in the trainings directory
for file in $TRAININGS_DIR/*.mp4; do
  echo "Examining $file"

  if [[ -d $file ]]; then
    # Skip directories
    echo "Skipping directory $file"
    continue
  fi

  base_name=$(basename "${file}")

  # if it's a training video, upload it to the incoming share
  if [[ $base_name == *.mp4 ]]; then
    echo "Processing video $base_name"

    # Check if file already exists in Azure
    exists=$(az storage file exists --account-name $STORAGE_ACCOUNT_NAME --account-key $STORAGE_PRIMARY_KEY --share-name $VIDEO_STORAGE_SHARE_NAME --path "$ALL_TRAININGS_DIR/$base_name" --query "exists" -o tsv)
    if [[ $exists == 'true' ]]; then
      printf "File ${yellow}$base_name${clear} already exists in Azure, skipping upload\n"
    else
      az storage file upload --account-name $STORAGE_ACCOUNT_NAME --account-key $STORAGE_PRIMARY_KEY --share-name $VIDEO_STORAGE_SHARE_NAME --path "$ALL_TRAININGS_DIR/$base_name" --source "$file"
      printf "Uploaded ${green}$base_name${clear} to Azure\n"
    fi

  # else print out unknown type
  else
    echo "Skipping unknown type $base_name"
  fi
    
done

PLAYLIST_DIR=trainings
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