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
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
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

# Enable required APIs
module "project_services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 18.0"

  project_id                  = var.project_id

  activate_apis = [
    "compute.googleapis.com",
    "iam.googleapis.com",
    "container.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudkms.googleapis.com",
    "sqladmin.googleapis.com",
    "servicenetworking.googleapis.com"
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

  network_name                = module.vpc.network_name

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
