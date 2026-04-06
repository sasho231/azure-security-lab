# ADR-001: Management Group Structure

## Status
Accepted

## Date
2026-04-06

## Context
A management group hierarchy is required to organise Azure subscriptions,
apply governance controls at scale, and align with the Microsoft Cloud
Adoption Framework (CAF). This decision defines the top-level structure
for the lab environment, which mirrors a real enterprise landing zone
at smaller scale.

## Decision
Adopt a CAF-aligned management group hierarchy with the following structure:
Tenant Root Group
└── mg-lab (top-level lab MG)
├── mg-platform
│   ├── mg-connectivity    (Hub networking, Firewall, DNS)
│   └── mg-identity        (Entra ID, PIM, domain services)
└── mg-workloads
└── mg-lab-workloads   (Lab deployments, test workloads)

## Rationale

### CAF Alignment
CAF defines platform and workload separation as a core principle.
Platform subscriptions host shared services consumed by all workloads.
Workload subscriptions are isolated and governed by inherited policies.

### Policy Inheritance
Azure Policy assignments at a management group level are inherited by
all child subscriptions. This allows security controls to be enforced
once at the MG level rather than repeated per subscription.

### MCSB Alignment
Microsoft Cloud Security Benchmark controls NS-1 (network segmentation)
and GV-1 (governance) require clear organisational boundaries. The MG
hierarchy provides the enforcement boundary for these controls.

### Separation of Concerns
- Connectivity MG: owns all network topology decisions
- Identity MG: owns all Entra ID and privileged access decisions  
- Workloads MG: owns deployed applications and services

## Alternatives Considered

### Flat structure (all subscriptions under root)
Rejected — no policy inheritance, no separation of concerns, does not
reflect real enterprise environments that contractors work in.

### Single subscription
Rejected — cannot demonstrate governance at scale, no MG-level policy
enforcement, not representative of client environments.

## Consequences
- All Azure Policy assignments will target MG level, not subscriptions
- RBAC assignments follow least privilege per MG scope
- New workload subscriptions automatically inherit security baseline
- Cost: Management Groups are free, no cost impact

## Related Frameworks
- CAF: Landing Zone design — platform and workload separation
- MCSB: GV-1 (governance), NS-1 (network segmentation)
- WAF Security Pillar: governance and compliance controls
