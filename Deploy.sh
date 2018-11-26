#!/usr/bin/env bash

echo "Traefik install and update config"
pwd
ls -lisa

echo "Traefik update of backends in accordance to azure tags"
AzureVMsJson=$(get_octopusvariable "Octopus.Action[Dynamic-VM-Inventory].Output.AzureVMsJson")
echo "Get Azure VMs Json String from Octopus"

echo "Generate backend rules config from tags"
echo $AzureVMsJson | python rules.py > rules.toml

echo "Copy generated configs"
mkdir -p /etc/traefikconf
sudo cp rules.toml /etc/traefikconf/rules.toml
sudo cp traefikconf/traefik.linux-amd64.toml /etc/traefikconf/traefik.linux-amd64.toml

echo "Create systemd config "
sudo mv traefikconf/traefik.service /etc/systemd/system/traefik.service

echo "Enable systemd service"
sudo mkdir -p /opt/traefik
wget --quiet https://github.com/containous/traefik/releases/download/v1.7.4/traefik_linux-amd64
sudo systemctl stop traefik
sudo mv -vn traefik_linux-amd64 /opt/traefik/traefik_linux-amd64
sudo systemctl start traefik

sudo systemctl enable traefik
sudo systemctl status traefik