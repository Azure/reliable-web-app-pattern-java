#!/usr/bin/env bash

# Invoked by AZD from the azure.yaml as a postprovision hook
# This script will upload training vidoes stored on the local file system to Proseware.  This assumes that the download-trainings.sh script was previously executed.
# This is intended for demo purposes.

green='\033[0;32m'
yellow='\e[0;33m'
red='\e[1;31m'
clear='\033[0m'

TRAININGS_DIR="videos"

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

CONNECTION_STRING=`az storage account show-connection-string --name $STORAGE_ACCOUNT_NAME --query "connectionString" -o tsv`

echo "Uploading videos"

# Create directory if it doesn't exist
az storage directory create --name $ALL_TRAININGS_DIR --share-name $VIDEO_STORAGE_SHARE_NAME --account-name $STORAGE_ACCOUNT_NAME --connection-string $CONNECTION_STRING 

EXPIRY=`date -u -d "30 minutes" '+%Y-%m-%dT%H:%MZ'`
SAS=`az storage share generate-sas -n $VIDEO_STORAGE_SHARE_NAME --connection-string $CONNECTION_STRING --account-name $STORAGE_ACCOUNT_NAME --https-only --permissions dlrw --expiry $EXPIRY -o tsv`

# move all files from proseware videos into our newly created storage account using Azure server to server APIs
# https://learn.microsoft.com/azure/storage/common/storage-use-azcopy-blobs-copy#copy-a-directory
azcopy copy "https://prosewaretrainingvideos.blob.core.windows.net/videos/" "https://$STORAGE_ACCOUNT_NAME.file.core.windows.net/$VIDEO_STORAGE_SHARE_NAME/$ALL_TRAININGS_DIR?${SAS}" --recursive=true --as-subdir=false --overwrite=false

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
    az storage file upload --account-name $STORAGE_ACCOUNT_NAME --connection-string $CONNECTION_STRING --share-name $PLAYLIST_STORAGE_SHARE_NAME --path "$base_name" --source "$file"

  # else print out unknown type
  else
    echo "Unknown type $base_name"
  fi
    
done