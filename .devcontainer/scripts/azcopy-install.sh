#!/bin/bash

# Define the download URL for azcopy
AZCOPY_URL="https://aka.ms/downloadazcopy-v10-linux"
ARCHITECTURE=$(arch)
if [[ $ARCHITECTURE == 'aarch64' ]]; then
  AZCOPY_URL="https://aka.ms/downloadazcopy-v10-linux-arm64"
fi

echo "Installing AzCopy from $AZCOPY_URL"

# Define the installation directory for azcopy
INSTALL_DIR="/usr/local/bin"

# Check if azcopy is already installed
if [[ ! $(command -v azcopy) ]]; then
    # Download azcopy
    wget -O azcopy.tar.gz $AZCOPY_URL
    # Extract the downloaded archive
    tar -xf azcopy.tar.gz --strip-components=1 --wildcards '*/azcopy'
    # Move azcopy to the installation directory
    sudo mv azcopy $INSTALL_DIR
    # Make azcopy executable
    sudo chmod +x $INSTALL_DIR/azcopy
    # Clean up the downloaded archive
    rm azcopy.tar.gz
else
    echo "azcopy is already installed. run 'azcopy --help' for more info."
fi