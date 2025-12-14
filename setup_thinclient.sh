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

echo "Please configure the static IP manually in the router or Netplan to the old IP (e.g. 192.168.178.10)."

echo "System setup complete. Please log in again for the Docker group to become active."