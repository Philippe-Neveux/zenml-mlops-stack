# Main Terraform configuration for Kubernetes infrastructure
terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }

  backend "gcs" {
    bucket = "tf-backends"
    prefix = "zenml-infra/terraform.tfstate"
  }
}

# Configure Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Data sources for Kubernetes providers
data "google_client_config" "default" {}

data "google_container_cluster" "cluster" {
  name     = module.gke.cluster_name
  location = var.region
  project  = var.project_id

  depends_on = [module.gke]
}

# Configure Kubernetes provider
provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.cluster.master_auth[0].cluster_ca_certificate)
}

# Enable required APIs
module "project_services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 18.0"

  project_id = var.project_id

  activate_apis = [
    "compute.googleapis.com",
    "iam.googleapis.com",
    "container.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudkms.googleapis.com",
    "sqladmin.googleapis.com",
    "servicenetworking.googleapis.com",
    "dns.googleapis.com",
    "storage.googleapis.com"
  ]
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name = var.project_name
  project_id   = var.project_id
  region       = var.region

  labels = var.common_labels

  depends_on = [module.project_services]
}

# GKE Module
module "gke" {
  source = "./modules/gke"

  project_name = var.project_name
  project_id   = var.project_id
  region       = var.region
  zones        = ["${var.zone}"]

  network_name        = module.vpc.network_name
  subnet_name         = module.vpc.subnet_name
  pods_range_name     = module.vpc.pods_range_name
  services_range_name = module.vpc.services_range_name

  labels = var.common_labels

  depends_on = [module.vpc, module.project_services]
}

# Security Module
module "security" {
  source = "./modules/security"

  project_name = var.project_name
  project_id   = var.project_id
  region       = var.region

  network_name = module.vpc.network_name

  labels = var.common_labels

  depends_on = [module.vpc, module.project_services, module.gke]
}

# MySQL Database Module
module "mysql" {
  source = "./modules/mysql"

  project_name = var.project_name
  project_id   = var.project_id
  region       = var.region

  private_network_id = module.vpc.network_id

  # Network access configuration for GKE connectivity
  gke_cluster_subnet_cidrs = [
    module.vpc.gke_nodes_subnet_cidr,
    module.vpc.pods_cidr,
    module.vpc.services_cidr
  ]

  labels = var.common_labels

  depends_on = [module.vpc, module.project_services]
}

# Storage Module for ZenML Artifacts
module "storage" {
  source = "./modules/storage"

  project_name = var.project_name
  project_id   = var.project_id
  region       = var.region

  # Use the existing ZenML service account from the security module
  zenml_service_account_email = module.security.zenml_service_account_email

  labels = var.common_labels

  depends_on = [module.project_services, module.security]
}
