#!/usr/bin/env bash

# This script will download to the local file system previously recorded videos for Proseware from https://prosewaretrainingvideos.blob.core.windows.net.
# This is intended for demo purposes.

green='\033[0;32m'
yellow='\e[0;33m'
red='\e[1;31m'
clear='\033[0m'

TRAININGS_DIR="videos"
mkdir -p $TRAININGS_DIR
cd $TRAININGS_DIR

# These are videos that will be placed in the TRAININGS_DIR
TRAININGS_VIDEOS=("01-Communication.mp4" "01-Energy-Conservation.mp4" "02-Brainstorming.mp4" "02-Financial-Planning.mp4" "02-Waste-Reduction.mp4" "03-Ideation.mp4" "03-Sustainable-Living.mp4" "01-Creativity.mp4" "01-Market-Research.mp4" "02-Data-Visualization.mp4" "02-Motivation.mp4" "03-Conflict-Resolution.mp4" "03-Marketing.mp4" "03-Team-Building.mp4" "01-Data-Collection.mp4" "01-Password-Security.mp4" "02-Delegation.mp4" "02-Phishing-Scam.mp4" "03-Data-Privacy.mp4" "03-Predictive-Modeling.mp4")

# Check if each of the files in the array TRAININGS_VIDEOS exists on disk
have_all_files=true
for video in "${TRAININGS_VIDEOS[@]}"
do
    if [[ ! -f "../videos/$video" ]]; then
        echo "$video does not exist on disk"
        # skipping download of files 1-by-1 to use xargs below for parallel downloads
        have_all_files=false
    fi
done

if [[ $have_all_files == true ]]; then
    printf "Skipping download.\nAll files ${green}already exist on disk${clear}.\n\n"
    exit 0
fi

# Pass one argument at a time (-n 1) to wget, and execute at most 8 parallel wget processes at a time (-P 8). 
# xarg returns after the last spawned process has finished, which is just what we wanted to know.
printf "https://prosewaretrainingvideos.blob.core.windows.net/videos/%s\n" "${TRAININGS_VIDEOS[@]}" | xargs -n 1 -P 8 wget

# These are intended to be skipped by the upload-trainings.sh script.  They will be used to demo the upload functionality in the UI.
UPLOAD_DEMO_DIR=$TRAININGS_DIR/UploadDemo
mkdir -p $UPLOAD_DEMO_DIR
cd $UPLOAD_DEMO_DIR

# These are videos that will be placed in the UPLOAD_DEMO_DIR
UPLOAD_DEMO_VIDEOS=("01-Data-Protection.mp4" "02-Privacy-Policies.mp4" "03-Privacy-Rights.mp4")
# Pass one argument at a time (-n 1) to wget, and execute at most 8 parallel wget processes at a time (-P 8). 
# xarg returns after the last spawned process has finished, which is just what we wanted to know.
printf "https://prosewaretrainingvideos.blob.core.windows.net/videos/%s\n" "${UPLOAD_DEMO_VIDEOS[@]}" | xargs -n 1 -P 8 wget 

printf "${green}Success${clear}.\n"
printf "File download is complete.\n\n"

cd $PROJECT_ROOT