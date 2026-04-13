# ADR-005: Application Gateway with WAF

## Status
Accepted

## Date
2026-04-13

## Context
The Flask web application needs a secure ingress point that inspects
inbound HTTP/HTTPS traffic before it reaches the application VM.
Direct internet access to the VM is not permitted by design.

## Decision
Deploy Azure Application Gateway v2 with WAF_v2 SKU in snet-appgw-lab:
- WAF Policy with OWASP Core Rule Set 3.2 in Prevention mode
- HTTPS termination at the gateway
- Health probe on /health endpoint
- Backend pool pointing to VM private IP (10.1.3.4:8080)
- HTTP to HTTPS redirect rule

## Rationale

### MCRA Alignment
Application Gateway + WAF is the standard Microsoft reference
architecture for securing web workloads in Azure.

### MCSB Alignment
- NS-6: Deploy web application firewall
- NS-1: Network segmentation via dedicated subnet

### Zero Trust
No direct internet access to VM - all traffic inspected by WAF first.

## Cost
WAF_v2 SKU ~$0.246/hour + $0.008/capacity unit/hour
Minimum 2 capacity units = ~$0.262/hour
Stop when not in use.

## Consequences
- All inbound web traffic inspected against OWASP 3.2 rules
- SSL termination at gateway - backend uses HTTP
- Health probe required on /health endpoint
- VM only reachable from App Gateway subnet
