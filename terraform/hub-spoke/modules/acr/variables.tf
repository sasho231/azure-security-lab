variable "acr_name" {
  description = "Name of the Container Registry (globally unique, alphanumeric)"
  type        = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "aks_kubelet_identity_principal_id" {
  description = "AKS kubelet managed identity for ACR pull"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
