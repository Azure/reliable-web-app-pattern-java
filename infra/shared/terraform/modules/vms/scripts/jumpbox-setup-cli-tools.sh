#!/bin/bash

# Script Definition
logpath=/var/log/deploymentscriptlog

# Upgrading Linux Distribution
echo "#############################" >> $logpath
echo "Upgrading Linux Distribution" >> $logpath
echo "#############################" >> $logpath
sudo apt-get update >> $logpath
sudo apt-get -y upgrade >> $logpath
echo " " >> $logpath

# Install Azure CLI
echo "#############################" >> $logpath
echo "Installing Azure CLI" >> $logpath
echo "#############################" >> $logpath
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Java 17
echo "#############################" >> $logpath
echo "Installing Java 17" >> $logpath
echo "#############################" >> $logpath
sudo apt-get install -y openjdk-17-jdk >> $logpath
