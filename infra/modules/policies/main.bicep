// ============================================================
// Custom Azure Policy Initiative
// Maps to Microsoft Cloud Security Benchmark (MCSB) controls
// Assigned at management group level for inheritance
// ============================================================

targetScope = 'managementGroup'

// ============================================================
// Policy Definition 1: Require tags on resource groups
// WAF Operational Excellence + CAF governance
// ============================================================

resource policyRequireTags 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'lab-require-resource-group-tags'
  properties: {
    displayName: 'Require tags on resource groups'
    description: 'Enforces required tags on all resource groups for cost attribution and governance'
    policyType: 'Custom'
    mode: 'All'
    metadata: {
      category: 'Tags'
      mcsb: 'GV-1'
    }
    parameters: {
      tagName: {
        type: 'String'
        metadata: {
          displayName: 'Required tag name'
        }
      }
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.Resources/resourceGroups'
          }
          {
            field: '[concat(\'tags[\', parameters(\'tagName\'), \']\')]'
            exists: false
          }
        ]
      }
      then: {
        effect: 'Deny'
      }
    }
  }
}

// ============================================================
// Policy Definition 2: Deny public blob access on storage
// MCSB: DP-2 protect sensitive data
// ============================================================

resource policyDenyPublicBlob 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'lab-deny-storage-public-access'
  properties: {
    displayName: 'Deny public blob access on storage accounts'
    description: 'Prevents storage accounts from allowing public blob access. MCSB DP-2.'
    policyType: 'Custom'
    mode: 'All'
    metadata: {
      category: 'Storage'
      mcsb: 'DP-2'
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.Storage/storageAccounts'
          }
          {
            field: 'Microsoft.Storage/storageAccounts/allowBlobPublicAccess'
            equals: true
          }
        ]
      }
      then: {
        effect: 'Deny'
      }
    }
  }
}

// ============================================================
// Policy Definition 3: Require HTTPS on storage accounts
// MCSB: DP-3 encrypt data in transit
// ============================================================

resource policyRequireHttps 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'lab-require-storage-https'
  properties: {
    displayName: 'Require HTTPS on storage accounts'
    description: 'Ensures storage accounts only accept encrypted HTTPS traffic. MCSB DP-3.'
    policyType: 'Custom'
    mode: 'All'
    metadata: {
      category: 'Storage'
      mcsb: 'DP-3'
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.Storage/storageAccounts'
          }
          {
            field: 'Microsoft.Storage/storageAccounts/supportsHttpsTrafficOnly'
            equals: false
          }
        ]
      }
      then: {
        effect: 'Deny'
      }
    }
  }
}

// ============================================================
// Policy Definition 4: Deny public IP on VMs
// MCSB: NS-1 network segmentation
// Zero Trust: no direct internet exposure
// ============================================================

resource policyDenyVmPublicIp 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'lab-deny-vm-public-ip'
  properties: {
    displayName: 'Deny public IP addresses on virtual machines'
    description: 'Prevents VMs from having public IPs. All access via Bastion. MCSB NS-1.'
    policyType: 'Custom'
    mode: 'All'
    metadata: {
      category: 'Network'
      mcsb: 'NS-1'
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.Network/networkInterfaces'
          }
          {
            count: {
              field: 'Microsoft.Network/networkInterfaces/ipconfigurations[*]'
              where: {
                field: 'Microsoft.Network/networkInterfaces/ipconfigurations[*].publicIpAddress.id'
                exists: true
              }
            }
            greater: 0
          }
        ]
      }
      then: {
        effect: 'Deny'
      }
    }
  }
}

// ============================================================
// Policy Initiative (Policy Set)
// Groups all custom policies into one assignable initiative
// Assigned at mg-lab-workloads management group
// ============================================================

resource policyInitiative 'Microsoft.Authorization/policySetDefinitions@2021-06-01' = {
  name: 'lab-security-baseline'
  properties: {
    displayName: 'Lab Security Baseline'
    description: 'Custom MCSB-aligned security baseline for the Azure Security Lab'
    policyType: 'Custom'
    metadata: {
      category: 'Security'
      version: '1.0.0'
    }
    parameters: {
      tagName: {
        type: 'String'
        defaultValue: 'Environment'
        metadata: {
          displayName: 'Required tag name'
        }
      }
    }
    policyDefinitions: [
      {
        policyDefinitionId: policyRequireTags.id
        parameters: {
          tagName: {
            value: '[parameters(\'tagName\')]'
          }
        }
      }
      {
        policyDefinitionId: policyDenyPublicBlob.id
        parameters: {}
      }
      {
        policyDefinitionId: policyRequireHttps.id
        parameters: {}
      }
      {
        policyDefinitionId: policyDenyVmPublicIp.id
        parameters: {}
      }
    ]
  }
}

// ============================================================
// Policy Assignment
// Assigns initiative to mg-lab-workloads MG
// All child subscriptions inherit these controls
// ============================================================

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'lab-sec-baseline'
  properties: {
    displayName: 'Lab Security Baseline Assignment'
    policyDefinitionId: policyInitiative.id
    description: 'Assigns MCSB-aligned security baseline to lab workloads'
    enforcementMode: 'Default'
    parameters: {
      tagName: {
        value: 'Environment'
      }
    }
  }
}

// Outputs
output policyInitiativeId string = policyInitiative.id
output policyAssignmentId string = policyAssignment.id
