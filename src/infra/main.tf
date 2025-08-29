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


# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name = var.project_name
  project_id   = var.project_id
  region       = var.region

  labels = var.common_labels
}

# GKE Module
module "gke" {
  source = "./modules/gke"

  project_name = var.project_name
  project_id   = var.project_id
  region       = var.region
  zones        = ["${var.zone}"]

  network_name = module.vpc.network_name
  subnet_name  = module.vpc.subnet_name

  labels = var.common_labels

  depends_on = [module.vpc]
}

# Security Module
module "security" {
  source = "./modules/security"

  project_name = var.project_name
  project_id   = var.project_id
  region       = var.region

  network_name                = module.vpc.network_name

  labels = var.common_labels

  depends_on = [module.vpc]
}
