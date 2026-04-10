# Backend configuration
# Stores Terraform state in Azure Storage Account
# This allows both local development and GitHub Actions
# to share the same state file
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstate10323"
    container_name       = "tfstate"
    key                  = "phase2-hub-spoke.tfstate"
    use_azuread_auth     = true
  }
}
