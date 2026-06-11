variable "name_prefix" {
    description = "Common prefix used when naming cloud router and cloud nat resources"
    type = string
}

variable "gcp_region" {
    description = "Region where colud router and NAT gateway will get created"
    type = string
}

variable "network_id" {
    description = "ID of the VPC network where cloud Router will be attached"
    type = string
}

variable "subnet_id" {
    description = "Subnet ID which you are going to attach and which will be used for GKE cluster"
    type = string
}