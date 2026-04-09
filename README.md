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

## Toolchain

| Tool | Category | Purpose |
|------|----------|---------|
| Bicep | IaC | Microsoft-native IaC language for Azure. Compiles to ARM JSON. All resources defined as code — nothing created via portal. |
| Terraform | IaC | HashiCorp IaC tool used alongside Bicep. Preferred in multi-cloud engagements and where clients already use it. |
| Azure CLI | Deployment | Used to authenticate to Azure, run what-if deployments, and manage resources from the terminal. |
| Checkov | Security Scanning | Static security scanner for IaC files. Checks Bicep and Terraform against CIS, MCSB and NIST controls before deployment. Runs in the pipeline on every push. |
| GitHub Actions | CI/CD | Pipeline platform built into GitHub. Runs automated checks on every push — lint, build, security scan, and what-if deployment. |
| GitHub Advanced Security | Supply Chain Security | Includes secret scanning (blocks committed credentials), Dependabot (flags vulnerable dependencies and outdated actions), and code scanning. Free for public repos. |
| Workload Identity Federation | Authentication | Passwordless authentication between GitHub Actions and Azure using OIDC tokens. No client secrets stored in GitHub — a Zero Trust principle applied to the pipeline itself. |

## Pipeline
Push to any branch
│
▼
┌──────────────────────────────────┐
│ Validate (every push)            │
│  bicep lint → bicep build        │
│  → Checkov scan                  │
└──────────────────────────────────┘
│ main branch only
▼
┌──────────────────────────────────┐
│ What-If (main only)              │
│  az deployment tenant what-if    │
│  Shows planned changes without   │
│  applying them to Azure          │
└──────────────────────────────────┘

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

## Phases

| Phase | Focus | Status |
|-------|-------|--------|
| 1 | Foundation — IaC discipline, CAF structure, CI/CD pipeline | ✅ Complete |
| 2 | Networking — Hub-spoke, Firewall, Bastion, Private Endpoints | ⬜ Planned |
| 3 | DevSecOps — Security gates, OPA policy, shift-left enforcement | ⬜ Planned |
| 4 | CSPM — Defender for Cloud, custom Azure Policy, MCSB hardening | ⬜ Planned |
| 5 | Sentinel — Workspace as code, detection pipeline, SOAR automation | ⬜ Planned |

## Cost

Estimated ~$10-15/month. All compute destroyed when idle and redeployed via IaC.
