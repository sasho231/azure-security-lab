#!/bin/bash
# ============================================================
# Lab Stop Script
# Destroys expensive resources: Firewall + Bastion
# Run at the end of each lab session
# Saves ~$0.53/hour (~$12.72/day)
# ============================================================

set -e

echo "============================================"
echo "Stopping Azure Security Lab"
echo "============================================"

# Fix WSL2 DNS
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null

# Navigate to Terraform directory
cd "$(dirname "$0")/../terraform/hub-spoke/environments/lab"

# Disable expensive resources
sed -i 's/deploy_firewall = true/deploy_firewall = false/' lab.auto.tfvars
sed -i 's/deploy_bastion = true/deploy_bastion = false/' lab.auto.tfvars

echo "Destroying Firewall and Bastion..."
terraform apply -auto-approve

echo ""
echo "============================================"
echo "Lab stopped - costs minimised"
echo "Remaining cost: ~\$0.01/month (storage only)"
echo "============================================"
