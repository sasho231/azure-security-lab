# ADR-006: Defender for Cloud CSPM and CWPP

## Status
Accepted

## Date
2026-04-14

## Context
The lab requires cloud security posture management (CSPM) and cloud
workload protection (CWPP) across all deployed resources. Microsoft
Defender for Cloud provides both capabilities natively in Azure.

## Decision
Enable Defender for Cloud across the subscription with:
- Defender CSPM free tier (posture management, Secure Score)
- Defender for Servers Plan 1 on VM (CWPP)
- Defender for App Service (CWPP)
- Defender for Storage on all storage accounts (CWPP)
- Defender for Key Vault (CWPP)
- Defender for Containers on AKS (Phase 5)
- MCSB as default regulatory compliance standard

## Rationale

### CNAPP Coverage
Each Defender plan covers a specific workload type giving complete
CNAPP coverage across all lab resources.

### MCSB Alignment
Defender for Cloud natively maps findings to MCSB controls.
Secure Score provides a quantified measure of security posture.

### Cost
Free tier CSPM provides Secure Score and basic recommendations at no cost.
Paid Defender plans (~$5-15/resource/month) enabled selectively.

## Consequences
- Secure Score visible immediately after enabling
- Recommendations appear within 24 hours
- All findings must be remediated via IaC not portal
- Feeds into Sentinel in Phase 7
