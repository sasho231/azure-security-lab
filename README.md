# Azure Security Lab

A CAF-aligned Azure security lab built to develop and demonstrate cloud security
architecture skills across IaC, DevSecOps, Zero Trust, and CSPM.

## Frameworks

| Framework | Role |
|-----------|------|
| CAF | Subscription and governance structure |
| MCSB | Hardening baseline and policy definitions |
| MCRA | Microsoft security product integration reference |
| WAF | Architecture quality and design validation |

## Architecture Decision Records

| ADR | Decision | Status |
|-----|----------|--------|
| [ADR-001](docs/adr/ADR-001-management-group-structure.md) | CAF-aligned management group hierarchy | Accepted |

## Management Group Hierarchy
Tenant Root Group
└── mg-lab
├── mg-lab-platform
│   ├── mg-lab-connectivity
│   └── mg-lab-identity
└── mg-lab-workloads
└── mg-lab-lab-workloads

## Pipeline

Every push triggers bicep lint, bicep build, and Checkov security scan.
Pushes to `main` additionally run `az deployment what-if` against the target tenant.
Workload Identity Federation — no secrets stored in GitHub.

## Phases

| Phase | Focus | Status |
|-------|-------|--------|
| 1 | Foundation — IaC discipline, CAF structure, CI/CD pipeline | 🔄 In Progress |
| 2 | Networking — Hub-spoke, Firewall, Bastion, Private Endpoints | ⬜ Planned |
| 3 | DevSecOps — Security gates, OPA policy, shift-left enforcement | ⬜ Planned |
| 4 | CSPM — Defender for Cloud, custom Azure Policy, MCSB hardening | ⬜ Planned |
| 5 | Sentinel — Workspace as code, detection pipeline, SOAR automation | ⬜ Planned |

## Cost

Estimated ~$10-15/month. All compute destroyed when idle and redeployed via IaC.
