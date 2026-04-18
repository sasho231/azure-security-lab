# Azure Security Lab

A CAF-aligned Azure security lab built to develop and demonstrate cloud security
architecture skills across IaC, DevSecOps, Zero Trust, CSPM, CWPP, and CNAPP.

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
| Bicep | IaC | Microsoft-native IaC for Azure. Compiles to ARM JSON. Nothing created via portal. |
| Terraform | IaC | HashiCorp IaC. Preferred in multi-cloud engagements. |
| Azure CLI | Deployment | Authenticate to Azure, run deployments, manage resources. |
| Checkov | Security Scanning | Static IaC scanner. Checks Bicep and Terraform against MCSB and CIS. |
| tfsec | Security Scanning | Terraform-specific scanner. 74 checks passed, 0 findings. |
| OPA/Conftest | Policy as Code | Custom security policies in CI/CD pipeline. 5 rules mapped to MCSB. |
| GitHub Actions | CI/CD | Automated security gates on every push. |
| GitHub Advanced Security | Supply Chain | Secret scanning, Dependabot, push protection. |
| Workload Identity Federation | Authentication | Passwordless Azure auth from GitHub via OIDC. No secrets stored. |
| kubectl | Containers | Kubernetes CLI for AKS management. |
| Helm | Containers | Kubernetes package manager. Used to deploy Falco. |
| Falco | Runtime Security | Kernel-level threat detection for Kubernetes via eBPF. |

## Architecture Decision Records

| ADR | Decision | Status |
|-----|----------|--------|
| [ADR-001](docs/adr/ADR-001-management-group-structure.md) | CAF-aligned management group hierarchy | Accepted |
| [ADR-002](docs/adr/ADR-002-hub-spoke-network-topology.md) | Hub-spoke network topology | Accepted |
| [ADR-003](docs/adr/ADR-003-azure-firewall-and-routing.md) | Azure Firewall and traffic routing | Accepted |
| [ADR-004](docs/adr/ADR-004-web-application-vm.md) | Web application VM deployment | Accepted |
| [ADR-005](docs/adr/ADR-005-application-gateway-waf.md) | Application Gateway with WAF | Accepted |
| [ADR-006](docs/adr/ADR-006-defender-for-cloud-cspm.md) | Defender for Cloud CSPM and CWPP | Accepted |
| [ADR-007](docs/adr/ADR-007-aks-and-container-security.md) | AKS and container security | Accepted |

## Management Group Hierarchy

    Tenant Root Group
    └── mg-lab
        ├── mg-lab-platform
        │   ├── mg-lab-connectivity
        │   └── mg-lab-identity
        └── mg-lab-workloads
            └── mg-lab-lab-workloads

## Network Topology

    Hub VNet (10.0.0.0/16)
    ├── AzureFirewallSubnet       10.0.1.0/26  Azure Firewall data traffic
    ├── AzureBastionSubnet        10.0.2.0/26  Azure Bastion
    └── AzureFirewallMgmtSubnet   10.0.4.0/26  Azure Firewall management

    Spoke VNet (10.1.0.0/16)
    ├── snet-workload-lab         10.1.1.0/24  General workload
    ├── snet-appgw-lab            10.1.2.0/24  Application Gateway + WAF
    ├── snet-app-lab              10.1.3.0/24  Web application + AKS nodes
    └── snet-data-lab             10.1.4.0/24  Private Endpoints

## Deployed Workloads

| Resource | Location | Details |
|----------|----------|---------|
| vm-app-lab | snet-app-lab 10.1.3.4 | Ubuntu 22.04, D2as_v4, Flask app on port 8080 |
| Flask app | vm-app-lab | Health: /health, API: /api/items, Admin: /admin |
| kv-lab-sasho231 | rg-spoke-lab | Key Vault, RBAC auth, purge protection, 2 secrets |
| aks-lab-lab | rg-spoke-lab | AKS v1.34, Standard SKU, Falco installed (deploy_aks=true) |
| acrlabsasho231 | rg-spoke-lab | Azure Container Registry Basic SKU (deploy_aks=true) |

## Traffic Flows

### User Traffic (North-South)

    Internet (HTTP 80)
          │
          ▼
    Application Gateway + WAF           snet-appgw-lab 10.1.2.0/24
    WAF: OWASP 3.2 Prevention mode
    XSS → 403, SQLi → dropped
          │
          ▼ 8080
    Web Application VM                  snet-app-lab 10.1.3.0/24
    No public IP - Bastion access only
          │
          ▼
    Key Vault (private endpoint)        snet-data-lab 10.1.4.0/24
    RBAC authorization, purge protected

### Admin Access (Zero Trust)

    Admin browser
          │ HTTPS only
          ▼
    Azure Bastion                       AzureBastionSubnet 10.0.2.0/26
          │ SSH 22
          ▼
    VM in snet-app-lab
    No public IP on any VM - ever

### Firewall Inspection (All Spoke Outbound)

    Any spoke VM outbound traffic
          │
          ▼  UDR: 0.0.0.0/0 next-hop 10.0.1.4
    Azure Firewall fw-hub-lab           AzureFirewallSubnet 10.0.1.0/26
    Application rules: Ubuntu updates, Azure services
    Network rules: DNS port 53
    Threat intelligence: Alert mode
    Everything else: DENIED

## NSG Rules

### nsg-appgw-lab
| Direction | Priority | Rule | Port | Source/Dest | Action |
|-----------|----------|------|------|-------------|--------|
| Inbound | 100 | AllowHttpsInbound | 443 | Internet | Allow |
| Inbound | 110 | AllowHttpInbound | 80 | Internet | Allow |
| Inbound | 120 | AllowGatewayManager | 65200-65535 | GatewayManager | Allow |
| Inbound | 130 | AllowAzureLoadBalancer | * | AzureLoadBalancer | Allow |
| Inbound | 4096 | DenyAllInbound | * | * | Deny |
| Outbound | 100 | AllowToAppSubnet | 8080 | snet-app-lab | Allow |
| Outbound | 110 | AllowInternetOutbound | * | Internet | Allow |

### nsg-app-lab
| Direction | Priority | Rule | Port | Source/Dest | Action |
|-----------|----------|------|------|-------------|--------|
| Inbound | 100 | AllowFromAppGateway | 8080 | snet-appgw-lab | Allow |
| Inbound | 110 | AllowSshFromBastion | 22 | AzureBastionSubnet | Allow |
| Inbound | 4096 | DenyAllInbound | * | * | Deny |
| Outbound | 100 | AllowToDataSubnet | 5432 | snet-data-lab | Allow |
| Outbound | 110 | AllowHttpsOutbound | 443 | Internet | Allow |
| Outbound | 4096 | DenyAllOutbound | * | * | Deny |

### nsg-data-lab
| Direction | Priority | Rule | Port | Source/Dest | Action |
|-----------|----------|------|------|-------------|--------|
| Inbound | 100 | AllowFromAppSubnet | 5432 | snet-app-lab | Allow |
| Inbound | 4096 | DenyAllInbound | * | * | Deny |
| Outbound | 4096 | DenyAllOutbound | * | * | Deny |

## Security Controls

### CWPP Coverage (Defender for Cloud)
| Workload | Defender Plan | Status |
|----------|--------------|--------|
| VM (vm-app-lab) | Defender for Servers | Free tier enabled |
| AKS (aks-lab-lab) | Defender for Containers | Free tier enabled |
| Storage accounts | Defender for Storage | Free tier enabled |
| Key Vault | Defender for Key Vault | Free tier enabled |
| App Service | Defender for App Service | Free tier enabled |
| ARM operations | Defender for ARM | Free tier enabled |

### Custom Azure Policy Initiative (mg-lab-workloads)
| Policy | MCSB Control | Effect |
|--------|-------------|--------|
| Require tags on resource groups | GV-1 | Deny |
| Deny public blob access | DP-2 | Deny |
| Require HTTPS on storage | DP-3 | Deny |
| Deny public IP on VMs | NS-1 | Deny |

### Falco Runtime Security (AKS)
| Rule | MITRE Technique | Severity |
|------|----------------|---------|
| Terminal shell in container | T1059 | Notice |
| Read sensitive file untrusted | T1555 | Warning |
| Drop and execute new binary | TA0003 | Critical |
| Container escape attempt | T1611 | Critical |

## CI/CD Pipelines

### Bicep Pipeline
    Push/PR → bicep lint → bicep build → Checkov scan (blocks on findings)
    Main only → az deployment validate

### Terraform Pipeline
    Push/PR → terraform fmt → terraform validate → tfsec scan (blocks on findings)
                           → OPA/Conftest policy evaluation
    Main only → terraform plan

## Cost Management

| Resource | SKU | Cost | Control |
|----------|-----|------|---------|
| Azure Firewall | Basic | ~$0.34/hour | deploy_firewall flag |
| Azure Bastion | Basic | ~$0.19/hour | deploy_bastion flag |
| App Gateway + WAF | WAF_v2 | ~$0.26/hour | deploy_appgw flag |
| AKS + ACR | Standard | ~$0.185/hour | deploy_aks flag |
| VM D2as_v4 | Standard | ~$0.085/hour | az vm start/deallocate |
| Key Vault | Standard | ~$0.03/month | Always on |
| Storage (TF state) | LRS | ~$0.01/month | Always on |

**Idle cost (all flags false, VM deallocated): ~$0.26/day**

### Session Start
    az vm start --resource-group rg-spoke-lab --name vm-app-lab
    cd terraform/hub-spoke/environments/lab
    sed -i 's/deploy_firewall = false/deploy_firewall = true/' lab.auto.tfvars
    terraform apply

### Session End (ALWAYS RUN)
    az vm deallocate --resource-group rg-spoke-lab --name vm-app-lab --no-wait
    cd terraform/hub-spoke/environments/lab
    sed -i 's/deploy_firewall = true/deploy_firewall = false/' lab.auto.tfvars
    sed -i 's/deploy_bastion = true/deploy_bastion = false/' lab.auto.tfvars
    sed -i 's/deploy_appgw = true/deploy_appgw = false/' lab.auto.tfvars
    sed -i 's/deploy_aks = true/deploy_aks = false/' lab.auto.tfvars
    terraform apply

## Phases

| Phase | Focus | Status |
|-------|-------|--------|
| 1 | Foundation - IaC, CAF structure, CI/CD, Workload Identity | ✅ Complete |
| 2 | Networking - Hub-spoke, Firewall, Bastion, NSGs, Zero Trust | ✅ Complete |
| 3 | DevSecOps - WAF, security gates, OPA policy, STRIDE threat model | ✅ Complete |
| 4 | CSPM - Defender for Cloud, Azure Policy, Key Vault, MCSB hardening | ✅ Complete |
| 5 | Containers - AKS, ACR, Falco runtime security, Defender for Containers | 🔄 In Progress |
| 6 | Zero Trust Identity - Entra PIM, Conditional Access, Entra Private Access | ⬜ Planned |
| 7 | Sentinel - Workspace as code, detection pipeline, SOAR automation | ⬜ Planned |
