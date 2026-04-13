variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "environment" {
  type = string
}

variable "appgw_subnet_id" {
  description = "Subnet ID for Application Gateway"
  type        = string
}

variable "backend_vm_ip" {
  description = "Private IP of the Flask VM backend"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
