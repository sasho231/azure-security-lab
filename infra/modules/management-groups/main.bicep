targetScope = 'tenant'

// ============================================================
// Parameters
// ============================================================

@description('Top level lab management group name')
param topLevelMgName string = 'mg-lab'

@description('Display name for top level MG')
param topLevelMgDisplayName string = 'Lab'

@description('Prefix for all child management groups')
param prefix string = 'mg-lab'

// ============================================================
// Management Group Hierarchy
// CAF-aligned: platform (connectivity + identity) + workloads
// ADR-001: docs/adr/ADR-001-management-group-structure.md
// ============================================================

// Top level
resource mgLab 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: topLevelMgName
  properties: {
    displayName: topLevelMgDisplayName
  }
}

// Platform
resource mgPlatform 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: '${prefix}-platform'
  properties: {
    displayName: 'Platform'
    details: {
      parent: {
        id: mgLab.id
      }
    }
  }
}

// Platform - Connectivity
resource mgConnectivity 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: '${prefix}-connectivity'
  properties: {
    displayName: 'Connectivity'
    details: {
      parent: {
        id: mgPlatform.id
      }
    }
  }
}

// Platform - Identity
resource mgIdentity 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: '${prefix}-identity'
  properties: {
    displayName: 'Identity'
    details: {
      parent: {
        id: mgPlatform.id
      }
    }
  }
}

// Workloads
resource mgWorkloads 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: '${prefix}-workloads'
  properties: {
    displayName: 'Workloads'
    details: {
      parent: {
        id: mgLab.id
      }
    }
  }
}

// Workloads - Lab
resource mgLabWorkloads 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: '${prefix}-lab-workloads'
  properties: {
    displayName: 'Lab Workloads'
    details: {
      parent: {
        id: mgWorkloads.id
      }
    }
  }
}

// ============================================================
// Outputs
// ============================================================

output mgLabId string = mgLab.id
output mgPlatformId string = mgPlatform.id
output mgConnectivityId string = mgConnectivity.id
output mgIdentityId string = mgIdentity.id
output mgWorkloadsId string = mgWorkloads.id
output mgLabWorkloadsId string = mgLabWorkloads.id
