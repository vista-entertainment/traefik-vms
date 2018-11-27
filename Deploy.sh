#!/usr/bin/env bash

echo "Traefik install and update config"
pwd


echo "Get Azure VMs Json String from Octopus"
AzureVMsJson=$(get_octopusvariable "Octopus.Action[Dynamic-VM-Inventory].Output.AzureVMsJson")
echo "Collect Azure VMs Json File"
echo $AzureVMsJson > azure.json
new_octopusartifact azure.json

echo "Generating backend rules config from tags"
sudo apt-get install python-pip -y
pip install Jinja2
echo $AzureVMsJson | python rules.py > rules.toml
echo "Generated Backend rules config file"

# Collect a file from the current working directory using the file name as the name of the artifact
cat rules.toml
new_octopusartifact rules.toml

echo "Create a folder for logs"
sudo mkdir -p /var/log/traefik

echo "Copy generated configs"
mkdir -p /etc/traefikconf
sudo cp rules.toml /etc/traefikconf/rules.toml
sudo cp traefikconf/traefik.linux-amd64.toml /etc/traefikconf/traefik.linux-amd64.toml

echo "Create systemd config "
sudo mv traefikconf/traefik.service /etc/systemd/system/traefik.service
#The unit file, source configuration file or drop-ins of traefik.service changed on disk
sudo systemctl daemon-reload

echo "Enable systemd service"
sudo mkdir -p /opt/traefik
wget --quiet https://github.com/containous/traefik/releases/download/v1.7.4/traefik_linux-amd64
sudo systemctl stop traefik
sudo mv -vn traefik_linux-amd64 /opt/traefik/traefik_linux-amd64
sudo systemctl start traefik

sudo systemctl enable traefik
sudo systemctl status traefik