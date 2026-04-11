# ADR-004: Web Application VM Deployment

## Status
Accepted

## Date
2026-04-11

## Context
A compute workload is required to host the Flask web application.
The workload must follow Zero Trust principles - no public IP,
access only via Bastion, traffic only from Application Gateway.

## Decision
Deploy a single Linux VM (Ubuntu 22.04) in snet-app-lab with:
- No public IP address
- SSH access via Azure Bastion only
- Managed Identity for Azure service authentication
- Azure Monitor Agent for logging
- Defender for Servers Plan 1 enabled
- Flask application running on port 8080

## Rationale

### Zero Trust
No public IP means no direct internet exposure.
All admin access goes through Bastion (identity-verified).
Application traffic only from App Gateway subnet.

### MCSB Alignment
- PV-4: Audit and enforce secure configurations on VMs
- LT-1: Enable threat detection via Defender for Servers
- LT-2: Enable audit logging via Azure Monitor Agent

## Cost
B2s SKU (~$30/month) - stop when not in use via Terraform.

## Consequences
- VM accessible only via Bastion browser session
- Application deployed via cloud-init on first boot
- Managed Identity used for Key Vault access in Phase 4
