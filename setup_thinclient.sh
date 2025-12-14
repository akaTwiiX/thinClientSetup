#!/bin/bash
# Script for automatic setup of a new ThinClient

echo "Updating system and installing curl..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git nano

echo "Installing Docker and Docker Compose..."
curl -sSL https://get.docker.com | sh
sudo usermod -aG docker $USER
sudo apt install -y docker-compose-plugin

echo "Setting timezone to Europe/Berlin..."
sudo timedatectl set-timezone Europe/Berlin

echo "-------------------------------------------------------------------"
echo "🌐 Network Information:"

CURRENT_IP=$(ip route get 1 | awk '{print $NF; exit}')

if [ -n "$CURRENT_IP" ]; then
    echo "The current (potentially temporary) IP address of this ThinClient is: $CURRENT_IP"
else
    echo "Could not automatically determine the current IP address."
fi

echo ""
echo "!!! CRITICAL NEXT STEPS FOR MIGRATION !!!"
echo "1. Assign the STATIC, OLD IP address to this device via Netplan or your router settings."
echo "   (E.g., change the current IP $CURRENT_IP to 192.168.178.10)"
echo "2. Upload the '.env' file and the volumes backups to this directory."
echo "3. Run 'docker-compose up -d'."
echo "-------------------------------------------------------------------"

echo "System setup complete. Please log in again for the Docker group to become active."