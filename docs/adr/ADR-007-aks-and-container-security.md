# ADR-007: AKS and Container Security

## Status
Accepted

## Date
2026-04-17

## Context
The lab requires a containerised workload to demonstrate CWPP coverage
for Kubernetes. AKS is the standard Microsoft-managed Kubernetes service.
Falco provides open-source runtime security complementing Defender for
Containers.

## Decision
Deploy AKS cluster in snet-app-lab with:
- System node pool (1 node, D2as_v4)
- Azure CNI networking (pods get VNet IPs)
- Defender for Containers enabled
- Falco installed via Helm for runtime security
- Azure Container Registry for image storage
- Managed Identity for cluster authentication
- Private cluster endpoint (Phase 6)

## Rationale

### CWPP Coverage
Defender for Containers provides:
- Image vulnerability scanning via ACR
- Kubernetes audit log analysis
- Runtime threat detection
- Network anomaly detection

Falco adds:
- Kernel-level syscall monitoring
- Process execution detection
- File system access alerts
- Container escape detection

### MCSB Alignment
- NS-1: Network segmentation via Azure CNI
- LT-1: Threat detection via Defender for Containers
- PV-5: Vulnerability assessment via image scanning

## Cost
AKS control plane: Free
Node pool (1 x D2as_v4): ~$0.085/hour
Scale to 0 when not in use

## Consequences
- Flask app containerised and deployed to AKS
- Falco alerts fed to Sentinel in Phase 7
- Container image scanning on every push via pipeline
