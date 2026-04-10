# ADR-002: Hub-Spoke Network Topology

## Status
Accepted

## Date
2026-04-10

## Context
A network topology is required for the lab that mirrors real enterprise
Azure environments. The design must enforce Zero Trust network principles,
centralise traffic inspection, and eliminate public exposure of workloads.

## Decision
Adopt a hub-spoke topology with the following design:
- Single Hub VNet hosting Azure Firewall and Azure Bastion
- Single Spoke VNet for lab workloads
- VNet peering between hub and spoke
- All spoke traffic routed through Hub Firewall via UDR
- No public IPs on any workload subnet
- Deny-all NSG defaults with explicit allow rules only

## Rationale

### CAF Alignment
CAF recommends hub-spoke as the standard enterprise network topology.
The hub hosts shared platform services (firewall, bastion, DNS).
Spokes are isolated workload networks that consume platform services.

### Zero Trust Alignment
MCRA Zero Trust network principles require:
- Verify explicitly: all traffic inspected by firewall
- Least privilege: NSG deny-all defaults
- Assume breach: no implicit trust between subnets

### MCSB Alignment
- NS-1: Implement security boundaries using Virtual Networks
- NS-2: Secure cloud services with network controls
- NS-7: Simplify network security configuration

## Alternatives Considered

### Flat single VNet
Rejected — no traffic inspection, no segmentation,
does not reflect enterprise environments.

### Azure Virtual WAN
Rejected — too complex and expensive for lab scale.
Appropriate for multi-region enterprise deployments.

## Cost Controls
- Azure Firewall Basic SKU — cheapest option (~$0.34/hour)
- Azure Bastion Basic SKU (~$0.19/hour)
- Both stopped when lab is not in use via start/stop scripts
- Estimated idle cost: ~$5/month

## Consequences
- All workload traffic inspected by Azure Firewall
- SSH/RDP only via Azure Bastion — no public IPs
- UDR (User Defined Routes) required on spoke subnets
- Private Endpoints required for PaaS services in Phase 4

## Related Frameworks
- CAF: Hub-spoke network topology
- MCRA: Zero Trust network access
- MCSB: NS-1, NS-2, NS-7
- WAF Security Pillar: network segmentation
