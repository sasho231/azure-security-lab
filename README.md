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
| Azure CLI | Deployment | Used to authenticate to Azure, run deployments, and manage resources from the terminal. |
| Checkov | Security Scanning | Static security scanner for IaC files. Checks Bicep and Terraform against CIS, MCSB and NIST controls before deployment. |
| tfsec | Security Scanning | Terraform-specific security scanner. 32 checks passed on current code. |
| GitHub Actions | CI/CD | Pipeline platform built into GitHub. Runs automated checks on every push. |
| GitHub Advanced Security | Supply Chain | Secret scanning, Dependabot, push protection. Free for public repos. |
| Workload Identity Federation | Authentication | Passwordless GitHub Actions to Azure authentication via OIDC. No secrets stored anywhere. |

## Architecture Decision Records

| ADR | Decision | Status |
|-----|----------|--------|
| [ADR-001](docs/adr/ADR-001-management-group-structure.md) | CAF-aligned management group hierarchy | Accepted |
| [ADR-002](docs/adr/ADR-002-hub-spoke-network-topology.md) | Hub-spoke network topology | Accepted |
| [ADR-003](docs/adr/ADR-003-azure-firewall-and-routing.md) | Azure Firewall and traffic routing | Accepted |

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
    ├── snet-app-lab              10.1.3.0/24  Web application
    └── snet-data-lab             10.1.4.0/24  Database Private Endpoint

## Deployed Workloads

| Resource | Location | Details |
|----------|----------|---------|
| vm-app-lab | snet-app-lab 10.1.3.4 | Ubuntu 22.04, D2s_v3, Flask app on port 8080 |
| Flask app | vm-app-lab | Health: /health, API: /api/items, Admin: /admin |

## Traffic Flows

### User Traffic (North-South)

    Internet (HTTPS 443)
          │
          ▼
    Application Gateway + WAF           snet-appgw-lab 10.1.2.0/24
    WAF: OWASP Top 10, SQLi, XSS
    Inbound:  443, 80 from Internet
              65200-65535 from GatewayManager
    Outbound: 8080 to snet-app-lab only
          │
          ▼ 8080
    Web Application                     snet-app-lab 10.1.3.0/24
    Inbound:  8080 from snet-appgw-lab only
              22 from AzureBastionSubnet only
    Outbound: 5432 to snet-data-lab
              443 to Internet (via Firewall)
    Deny all: everything else
          │
          ▼ 5432
    Database Private Endpoint           snet-data-lab 10.1.4.0/24
    Inbound:  5432 from snet-app-lab only
    Outbound: denied
    No public endpoint - ever

### Admin Access (Zero Trust)

    Admin browser
          │ HTTPS only
          ▼
    Azure Bastion                       AzureBastionSubnet 10.0.2.0/26
          │ SSH 22 or RDP 3389
          ▼
    VM in snet-app-lab
    No public IP on any VM - ever

### Firewall Inspection (All Spoke Outbound)

    Any spoke VM outbound traffic
          │
          ▼  UDR: 0.0.0.0/0 next-hop 10.0.1.4
    Azure Firewall fw-hub-lab           AzureFirewallSubnet 10.0.1.0/26
    Application rules (FQDN):
      ALLOW *.ubuntu.com, *.launchpad.net (Ubuntu updates)
      ALLOW WindowsUpdate tag
      ALLOW AzureKubernetesService tag
    Network rules:
      ALLOW DNS port 53 to 168.63.129.16
    Threat intelligence: Alert mode
    Everything else: DENIED
          │
          ▼
    Internet

## NSG Rules

### nsg-bastion-lab

| Direction | Priority | Rule | Port | Source/Dest | Action |
|-----------|----------|------|------|-------------|--------|
| Inbound | 100 | AllowHttpsInbound | 443 | Internet | Allow |
| Inbound | 110 | AllowGatewayManager | 443 | GatewayManager | Allow |
| Inbound | 120 | AllowAzureLoadBalancer | 443 | AzureLoadBalancer | Allow |
| Inbound | 130 | AllowBastionHostComm | 8080,5701 | VirtualNetwork | Allow |
| Inbound | 4096 | DenyAllInbound | * | * | Deny |
| Outbound | 100 | AllowSshRdpOutbound | 22,3389 | VirtualNetwork | Allow |
| Outbound | 110 | AllowAzureCloud | 443 | AzureCloud | Allow |
| Outbound | 120 | AllowBastionHostComm | 8080,5701 | VirtualNetwork | Allow |
| Outbound | 4096 | DenyAllOutbound | * | * | Deny |

### nsg-appgw-lab

| Direction | Priority | Rule | Port | Source/Dest | Action |
|-----------|----------|------|------|-------------|--------|
| Inbound | 100 | AllowHttpsInbound | 443 | Internet | Allow |
| Inbound | 110 | AllowHttpInbound | 80 | Internet | Allow |
| Inbound | 120 | AllowGatewayManager | 65200-65535 | GatewayManager | Allow |
| Inbound | 130 | AllowAzureLoadBalancer | * | AzureLoadBalancer | Allow |
| Inbound | 4096 | DenyAllInbound | * | * | Deny |
| Outbound | 100 | AllowToAppSubnet | 8080 | snet-app-lab | Allow |
| Outbound | 4096 | DenyAllOutbound | * | * | Deny |

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

### nsg-workload-lab

| Direction | Priority | Rule | Port | Source/Dest | Action |
|-----------|----------|------|------|-------------|--------|
| Inbound | 100 | AllowSshFromBastion | 22 | AzureBastionSubnet | Allow |
| Inbound | 110 | AllowRdpFromBastion | 3389 | AzureBastionSubnet | Allow |
| Inbound | 4096 | DenyAllInbound | * | * | Deny |

## CI/CD Pipelines

### Bicep Pipeline (bicep-validate.yml)
Triggers on every push to any branch and every PR to main.

    Push/PR
        bicep lint          syntax and best practice checks
        bicep build         compile to ARM JSON
        Checkov scan        security misconfiguration scanning
        [main only]
        az deployment validate   confirm deployable against Azure

### Terraform Pipeline (terraform-validate.yml)
Triggers on every push that modifies terraform/ files.

    Push/PR
        terraform fmt       code formatting check
        terraform validate  syntax validation
        tfsec scan          security misconfiguration scanning (32 passed)
        [main only]
        terraform plan      show planned changes against Azure state

## Cost Management

| Resource | SKU | Cost | Status |
|----------|-----|------|--------|
| Management Groups | - | Free | Always on |
| VNets + Subnets | - | Free | Always on |
| NSGs | - | Free | Always on |
| Azure Firewall | Basic | ~$0.34/hour | Stop when idle |
| Azure Bastion | Basic | ~$0.19/hour | Stop when idle |
| Storage (TF state) | LRS | ~$0.01/month | Always on |

Use scripts/lab-start.sh and scripts/lab-stop.sh to control costs.
Estimated idle cost: ~$0.01/month. Active cost: ~$0.53/hour.

## Phases

| Phase | Focus | Status |
|-------|-------|--------|
| 1 | Foundation - IaC discipline, CAF structure, CI/CD pipeline | ✅ Complete |
| 2 | Networking - Hub-spoke, Firewall, Bastion, subnets, NSGs | ✅ Complete |
| 3 | DevSecOps - Security gates, OPA policy, shift-left enforcement | ✅ Complete |
| 4 | CSPM - Defender for Cloud, custom Azure Policy, MCSB hardening | ⬜ Planned |
| 5 | Zero Trust - Entra PIM, Conditional Access, Entra Private Access | ⬜ Planned |
| 6 | Sentinel - Workspace as code, detection pipeline, SOAR automation | ⬜ Planned |
