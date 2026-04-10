variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "environment" {
  type = string
}

variable "spoke_vnet_cidr" {
  type = string
}

variable "workload_subnet_cidr" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
