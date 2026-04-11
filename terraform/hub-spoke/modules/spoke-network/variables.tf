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

variable "appgw_subnet_cidr" {
  description = "CIDR for Application Gateway subnet"
  type        = string
}

variable "app_subnet_cidr" {
  description = "CIDR for web application subnet"
  type        = string
}

variable "data_subnet_cidr" {
  description = "CIDR for database Private Endpoint subnet"
  type        = string
}

variable "bastion_subnet_cidr" {
  description = "Bastion subnet CIDR - used in NSG rules"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
