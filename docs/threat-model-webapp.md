# Threat Model: Azure Security Lab Web Application

## Date
2026-04-13

## Scope
Flask web application running on VM in snet-app-lab, exposed via
Application Gateway + WAF. Includes the data flow from internet
through to the database layer.

## Architecture

    Internet User
         │
         ▼
    Application Gateway + WAF (snet-appgw-lab)
         │
         ▼
    Flask VM (snet-app-lab 10.1.3.4:8080)
         │
         ▼
    Database Private Endpoint (snet-data-lab)

## Data Flow Diagram

    [User Browser] → HTTPS → [App Gateway] → HTTP → [Flask App] → TCP 5432 → [Database]

    Trust boundaries:
    - Internet / Azure perimeter (App Gateway is the entry point)
    - Application subnet (Flask VM)
    - Data subnet (Database - no public access)

## STRIDE Analysis

### S — Spoofing

| Threat | Component | Mitigation | Status |
|--------|-----------|------------|--------|
| Attacker impersonates legitimate user | /login endpoint | Entra ID authentication (Phase 5) | ⬜ Planned |
| Attacker spoofs App Gateway health probe | /health endpoint | Health probe restricted to App Gateway IP | ✅ Mitigated |
| Attacker impersonates Azure service | VM Managed Identity | User-assigned managed identity, no stored credentials | ✅ Mitigated |

### T — Tampering

| Threat | Component | Mitigation | Status |
|--------|-----------|------------|--------|
| Attacker modifies HTTP request in transit | All endpoints | TLS at App Gateway (Phase 4) | ⬜ Planned |
| SQL injection via API parameters | /api/items?id= | WAF OWASP rule SQLi detection | ✅ Mitigated |
| Attacker modifies VM OS disk | VM storage | Premium_LRS disk encryption at rest | ✅ Mitigated |
| Attacker tampers with IaC code | GitHub repo | Branch protection, PR required, pipeline gates | ✅ Mitigated |

### R — Repudiation

| Threat | Component | Mitigation | Status |
|--------|-----------|------------|--------|
| Attacker denies making malicious requests | WAF | WAF logs all blocked requests | ✅ Mitigated |
| Admin denies making configuration changes | Azure resources | Azure Activity Log, Sentinel (Phase 6) | ⬜ Planned |
| User denies API actions | /api/items POST | Application logging (Phase 4) | ⬜ Planned |

### I — Information Disclosure

| Threat | Component | Mitigation | Status |
|--------|-----------|------------|--------|
| Database connection string exposed | Flask app config | Key Vault integration (Phase 4) | ⬜ Planned |
| VM private IP exposed in response headers | App Gateway | Header rewrite rules (Phase 4) | ⬜ Planned |
| Error messages reveal stack traces | Flask app | Debug mode disabled in production | ✅ Mitigated |
| Database accessible from internet | PostgreSQL | Private Endpoint only, no public endpoint | ✅ Mitigated |
| SSH keys exposed in Terraform state | State file | State stored in Azure Storage, access controlled | ✅ Mitigated |

### D — Denial of Service

| Threat | Component | Mitigation | Status |
|--------|-----------|------------|--------|
| HTTP flood against App Gateway | Public IP | WAF rate limiting (Phase 4) | ⬜ Planned |
| Large request body exhausts Flask memory | /api/items POST | WAF max request body 128KB enforced | ✅ Mitigated |
| Slowloris attack against Flask | Port 8080 | App Gateway terminates slow connections | ✅ Mitigated |
| Resource exhaustion via file upload | Flask app | WAF file upload limit 100MB enforced | ✅ Mitigated |

### E — Elevation of Privilege

| Threat | Component | Mitigation | Status |
|--------|-----------|------------|--------|
| Attacker accesses /admin without auth | /admin endpoint | Entra ID Conditional Access (Phase 5) | ⬜ Planned |
| Compromised VM pivots to other subnets | snet-app-lab | NSG deny-all, only port 5432 to data subnet | ✅ Mitigated |
| SQL injection grants DB admin access | Database | WAF OWASP SQLi rules, least privilege DB user (Phase 4) | ⬜ Planned |
| Attacker escalates via managed identity | VM identity | Identity has no permissions assigned yet | ✅ Mitigated |

## Risk Summary

| Risk Level | Count | Examples |
|------------|-------|---------|
| ✅ Mitigated | 13 | WAF rules, NSGs, no public DB, managed identity |
| ⬜ Planned | 9 | TLS, Entra ID auth, Key Vault, rate limiting |
| ❌ Unmitigated | 0 | |

## Residual Risks

All unmitigated items are tracked for Phase 4 and Phase 5:
- Phase 4: TLS certificates, Key Vault, application logging, header rewriting
- Phase 5: Entra ID authentication on /login and /admin endpoints

## MITRE ATT&CK Mapping (Cloud)

| Technique | ID | Mitigation |
|-----------|-----|------------|
| Valid Accounts | T1078 | Entra ID MFA (Phase 5) |
| Exploit Public-Facing Application | T1190 | WAF OWASP 3.2 Prevention |
| Data from Cloud Storage | T1530 | Private Endpoint, no public access |
| Network Service Discovery | T1046 | NSG deny-all, no port scanning possible |
| Exfiltration Over Web Service | T1567 | Firewall outbound inspection |
