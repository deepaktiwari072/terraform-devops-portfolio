variable "environment" {
  description = "Enviroment name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "vnet_address_space" {
  description = "address space for vnet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "tags" {
  description = "resource tags"
  type        = map(string)
  default = {
  }
}