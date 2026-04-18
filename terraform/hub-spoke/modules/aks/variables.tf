variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "environment" {
  type = string
}

variable "app_subnet_id" {
  description = "Subnet ID for AKS nodes"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace for Defender for Containers"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.32.10"
}

variable "tags" {
  type    = map(string)
  default = {}
}
