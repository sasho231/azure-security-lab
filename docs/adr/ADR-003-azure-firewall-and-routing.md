# ADR-003: Azure Firewall and Traffic Routing

## Status
Accepted

## Date
2026-04-11

## Context
With hub-spoke topology in place, all spoke traffic must be inspected
before reaching workloads or the internet. A centralised firewall is
required to enforce network security policy, provide threat intelligence,
and give visibility into all east-west and north-south traffic flows.

## Decision
Deploy Azure Firewall Basic SKU in the hub VNet with:
- Firewall Policy defining application and network rules
- User Defined Route (UDR) on spoke subnets forcing all traffic
  through the Firewall
- Default deny-all with explicit allow rules only
- Threat intelligence in Alert mode

## Rationale

### MCRA Alignment
MCRA places Azure Firewall as the central network security control
in the hub. All spoke traffic routes through hub Firewall before
reaching destinations — this is the standard Microsoft reference
architecture for enterprise Azure.

### Zero Trust Alignment
Assume breach principle: never trust traffic implicitly even between
internal subnets. All traffic inspected regardless of source.

### MCSB Alignment
- NS-4: Deploy intrusion detection and prevention systems
- NS-7: Simplify network security configuration

## Alternatives Considered

### Network Virtual Appliance (NVA)
Rejected — complex to manage, requires HA configuration,
more expensive than Azure Firewall Basic for lab scale.

### No central firewall
Rejected — NSGs alone provide segmentation but no deep packet
inspection, no FQDN filtering, no threat intelligence.

## Cost Controls
- Basic SKU — cheapest option (~$0.34/hour)
- Deploy only when actively using the lab
- Controlled via Terraform — comment out to destroy

## Consequences
- All spoke subnet traffic routes through Firewall via UDR
- Internet outbound from workloads requires explicit Firewall rules
- Firewall logs feed into Sentinel in Phase 6
- Latency increases slightly due to traffic inspection

## Related Frameworks
- MCRA: Hub network security
- MCSB: NS-4, NS-7
- WAF Security Pillar: network controls
- Zero Trust: verify explicitly, assume breach
