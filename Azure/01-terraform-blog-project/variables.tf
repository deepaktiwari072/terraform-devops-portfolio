variable "environment" {
    description = "Env name (Dev, prod, staging)"
    type = string
    default = "dev"
}

variable "location" {
    description = "Azure region for resources"
    type = string
    default = "EAST US"
}

variable "project_name" {
    description = "Project name for resource naming"
    type = string
    default = "blog"
}

variable "tags" {
    description = "tags apply to all resources"
    type = map(string)
    default = {
      Environment  = "dev"
      Project = "Terraform Blog"
      ManagedBy = "Terraform"
      CreatedBy =   "Deepak Tiwari"
    }
}