# ============================================================
# OPA/Conftest Security Policies
# Custom security rules for the Azure Security Lab
# These enforce organisation-specific standards beyond
# what Checkov and tfsec cover out of the box
# ============================================================

package main

import future.keywords.if
import future.keywords.contains

# ============================================================
# RULE 1: All resources must have required tags
# WAF Operational Excellence: every resource must be
# identifiable, auditable and cost-attributable
# ============================================================

required_tags := {"Environment", "Project", "ManagedBy"}

deny contains msg if {
  input.resource_type == "azurerm_resource_group"
  existing_tags := {tag | input.config.tags[tag]}
  missing := required_tags - existing_tags
  count(missing) > 0
  msg := sprintf(
    "Resource group '%s' is missing required tags: %v",
    [input.address, missing]
  )
}

# ============================================================
# RULE 2: Storage accounts must have public access disabled
# MCSB DP-2: protect sensitive data
# ============================================================

deny contains msg if {
  input.resource_type == "azurerm_storage_account"
  input.config.allow_blob_public_access == true
  msg := sprintf(
    "Storage account '%s' has public blob access enabled. MCSB DP-2 requires this to be disabled.",
    [input.address]
  )
}

# ============================================================
# RULE 3: Virtual machines must use managed disks
# MCSB DP-3: encrypt data at rest
# ============================================================

deny contains msg if {
  input.resource_type == "azurerm_linux_virtual_machine"
  input.config.os_disk[_].storage_account_type == "Standard_LRS"
  msg := sprintf(
    "VM '%s' uses Standard_LRS disk. Use Premium_LRS for better performance and encryption support.",
    [input.address]
  )
}

# ============================================================
# RULE 4: Network security groups must have explicit deny-all
# Zero Trust: deny everything, allow explicitly
# ============================================================

deny contains msg if {
  input.resource_type == "azurerm_network_security_group"
  rules := input.config.security_rule
  deny_rules := [r | r := rules[_]; r.access == "Deny"; r.priority == 4096]
  count(deny_rules) == 0
  msg := sprintf(
    "NSG '%s' is missing a deny-all rule at priority 4096. Zero Trust requires explicit deny-all.",
    [input.address]
  )
}

# ============================================================
# RULE 5: No SSH from internet (priority check)
# MCSB NS-1: restrict inbound access
# ============================================================

deny contains msg if {
  input.resource_type == "azurerm_network_security_group"
  rule := input.config.security_rule[_]
  rule.destination_port_range == "22"
  rule.source_address_prefix == "*"
  rule.access == "Allow"
  rule.direction == "Inbound"
  msg := sprintf(
    "NSG '%s' allows SSH from any source. MCSB NS-1 requires restricting SSH to specific sources only.",
    [input.address]
  )
}
