locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_labels = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}
# Calling VPC module for creating VPC and Subnet 
module "vpc" {
  source = "./modules/vpc"

  name_prefix   = local.name_prefix
  gcp_region    = var.gcp_region
  network_name  = var.network_name
  subnet_cidr   = var.subnet_cidr
  pods_cidr     = var.pods_cidr
  services_cidr = var.services_cidr
  depends_on    = [module.apis]
}

# Calling API module for enabling API's so that I will start creating services 

module "apis" {
  source = "./modules/apis"

  required_apis = var.required_apis
}

# calling Artifact  module so that I can push the image inside GCR

module "artifact_registry" {
  source = "./modules/artifact_registry"

  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region
  repository_id  = var.artifact_registry_repository_id

  description = "Docker repository for GKE GitOps application images."

  lables = local.common_labels

  depends_on = [module.apis]

}

# Calling NAT module to create NAT gateway and Cloud router 
module "nat" {
  source = "./modules/nat"

  name_prefix = local.name_prefix
  gcp_region  = var.gcp_region
  network_id  = module.vpc.network_id
  subnet_id   = module.vpc.subnet_id

  depends_on = [module.vpc]
}

#Calling GKE module to create GKE cluster 

module "gke" {
  source = "./modules/gke"

  gcp_project_id = var.gcp_project_id
  name_prefix    = local.name_prefix
  gcp_region     = var.gcp_region
  gcp_zone       = var.gcp_zone

  network_id          = module.vpc.network_id
  subnet_id           = module.vpc.subnet_id
  pods_range_name     = module.vpc.pods_range_name
  services_range_name = module.vpc.services_range_name

  master_ipv4_cidr_block = var.master_ipv4_cidr_block
  deletion_protection    = var.gke_deletion_protection

  depends_on = [module.apis, module.nat]
}

# Call node pool module for GKE

module "gke_node_pool" {
  source = "./modules/gke_node_pool"

  gcp_project_id   = var.gcp_project_id
  name_prefix      = local.name_prefix
  cluster_name     = module.gke.cluster_name
  cluster_location = module.gke.cluster_location

  machine_type   = var.node_machine_type
  min_node_count = var.node_min_count
  max_node_count = var.node_max_count
  disk_size_gb   = var.node_disk_size_gb
  labels         = local.common_labels
}

#Calling Github module 

module "github_wif" {
  source = "./modules/github_wif"

  gcp_project_id  = var.gcp_project_id
  name_prefix     = local.name_prefix
  github_owner    = var.github_owner
  github_repo     = var.github_repo
  github_branch   = var.github_branch
  terraform_roles = var.terraform_deployer_roles

  depends_on = [module.apis]
}