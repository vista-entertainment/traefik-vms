#!/usr/bin/env bash

echo "Traefik update config"
mkdir -p /etc/traefikconf
pwd
ls -lisa
#copy config files 

echo "Traefik update of backends in accordance to azure tags"
AzureVMsJson=$(get_octopusvariable "Octopus.Action[Dynamic-VM-Inventory].Output.AzureVMsJson")
echo "Azure VMs Json String"
echo " $AzureVMsJson "

echo $AzureVMsJson | python rules.py > /etc/traefikconf/rules.toml