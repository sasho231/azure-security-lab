#!/bin/bash
# ============================================================
# Lab Start Script
# Deploys expensive resources: Firewall + Bastion
# Run at the start of each lab session
# Cost: ~$0.53/hour when both running
# ============================================================

set -e

echo "============================================"
echo "Starting Azure Security Lab"
echo "============================================"

# Fix WSL2 DNS
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null
echo "✅ DNS fixed"

# Login to Azure
echo "Logging into Azure..."
az login --tenant ae051317-75eb-4002-8966-17cfb627a012 --only-show-errors
az account set --subscription "sub-lab"
echo "✅ Azure connected"

# Navigate to Terraform directory
cd "$(dirname "$0")/../terraform/hub-spoke/environments/lab"

# Enable expensive resources
sed -i 's/deploy_firewall = false/deploy_firewall = true/' lab.auto.tfvars
sed -i 's/deploy_bastion = false/deploy_bastion = true/' lab.auto.tfvars

echo "Starting VM..."
az vm start --resource-group rg-spoke-lab --name vm-app-lab --no-wait

echo "Deploying Firewall and Bastion..."
echo "This takes 15-20 minutes..."
terraform apply -auto-approve

echo ""
echo "============================================"
echo "Lab is ready!"
echo "Firewall: running (~\$0.34/hour)"
echo "Bastion:  running (~\$0.19/hour)"
echo "Total:    ~\$0.53/hour"
echo "============================================"
