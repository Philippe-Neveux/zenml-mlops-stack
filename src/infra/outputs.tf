# VPC Outputs
output "network_name" {
  description = "Name of the VPC network"
  value       = module.vpc.network_name
}

output "network_id" {
  description = "ID of the VPC network"
  value       = module.vpc.network_id
}

output "subnet_name" {
  description = "Name of the primary subnet"
  value       = module.vpc.subnet_name
}

output "subnet_id" {
  description = "ID of the primary subnet"
  value       = module.vpc.subnet_id
}

output "ingress_ip_address" {
  description = "Global IP address for ingress"
  value       = module.vpc.ingress_ip_address
}

# GKE Cluster Outputs
output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = module.gke.cluster_name
}

output "cluster_id" {
  description = "ID of the GKE cluster"
  value       = module.gke.cluster_id
}

output "cluster_location" {
  description = "Location of the GKE cluster"
  value       = module.gke.cluster_location
}

output "cluster_endpoint" {
  description = "Endpoint for GKE control plane"
  value       = module.gke.cluster_endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate (base64 encoded)"
  value       = module.gke.cluster_ca_certificate
  sensitive   = true
}

output "cluster_master_version" {
  description = "Current master version"
  value       = module.gke.cluster_master_version
}

# Autopilot and Workload Identity Outputs
output "autopilot_enabled" {
  description = "Whether GKE Autopilot is enabled"
  value       = module.gke.autopilot_enabled
}

output "workload_identity_pool" {
  description = "Workload identity pool for secure pod-to-GCP authentication"
  value       = module.gke.workload_identity_pool
}

# Security Outputs
output "app_config_secret_id" {
  description = "ID of the application config secret"
  value       = module.security.app_config_secret_id
}

# Kubectl Configuration
output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "gcloud container clusters get-credentials ${module.gke.cluster_name} --region ${var.region} --project ${var.project_id}"
}

# MySQL Database Outputs
output "mysql_instance_name" {
  description = "Name of the Cloud SQL MySQL instance"
  value       = module.mysql.mysql_instance_name
}

output "mysql_instance_connection_name" {
  description = "Connection name of the Cloud SQL MySQL instance"
  value       = module.mysql.mysql_instance_connection_name
}

output "mysql_instance_private_ip" {
  description = "Private IP address of the Cloud SQL MySQL instance"
  value       = module.mysql.mysql_instance_private_ip
}

output "zenml_database_name" {
  description = "Name of the ZenML database"
  value       = module.mysql.zenml_database_name
}

output "zenml_database_username" {
  description = "Username for ZenML database access"
  value       = module.mysql.zenml_database_username
}

output "zenml_database_connection_info" {
  description = "ZenML database connection information"
  value       = module.mysql.zenml_database_connection_info
}

output "zenml_database_url" {
  description = "Complete database URL for ZenML configuration"
  value       = module.mysql.zenml_database_url
  sensitive   = true
}

output "zenml_database_secret_ids" {
  description = "Secret Manager secret IDs for database credentials"
  value = {
    password_secret_id    = module.mysql.zenml_database_password_secret_id
    connection_secret_id  = module.mysql.zenml_db_connection_secret_id
    root_password_secret_id = module.mysql.mysql_root_password_secret_id
  }
}

# Project Information
output "project_id" {
  description = "Google Cloud Project ID"
  value       = var.project_id
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

output "region" {
  description = "Google Cloud region"
  value       = var.region
}

# ZenML Service Account Outputs
output "zenml_service_account_email" {
  description = "Email of the ZenML service account for Secret Manager access"
  value       = module.security.zenml_service_account_email
}

output "zenml_service_account_name" {
  description = "Name of the ZenML service account"
  value       = module.security.zenml_service_account_name
}

# ZenML Custom IAM Roles Outputs
output "zenml_secrets_store_creator_role_id" {
  description = "ID of the ZenML Secrets Store Creator custom role"
  value       = module.security.zenml_secrets_store_creator_role_id
}

output "zenml_secrets_store_editor_role_id" {
  description = "ID of the ZenML Secrets Store Editor custom role"
  value       = module.security.zenml_secrets_store_editor_role_id
}

# ZenML Deployment Configuration
output "zenml_helm_database_config" {
  description = "Database configuration formatted for ZenML Helm chart values"
  value       = module.mysql.zenml_helm_database_config
}

output "zenml_secret_manager_config" {
  description = "Secret Manager configuration for ZenML"
  value = {
    project_id            = var.project_id
    service_account_email = module.security.zenml_service_account_email
    region               = var.region
  }
}

# ZenML Complete Deployment Information
output "zenml_deployment_info" {
  description = "Complete information needed for ZenML deployment"
  value = {
    # Project Information
    project_id   = var.project_id
    project_name = var.project_name
    region       = var.region
    
    # Database Configuration
    database = {
      host     = module.mysql.mysql_instance_private_ip
      port     = "3306"
      database = module.mysql.zenml_database_name
      username = module.mysql.zenml_database_username
      ssl_mode = "PREFERRED"
    }
    
    # Secret Manager
    secret_manager = {
      project_id            = var.project_id
      service_account_email = module.security.zenml_service_account_email
      password_secret_name  = module.mysql.zenml_database_password_secret_id
      connection_secret_name = module.mysql.zenml_db_connection_secret_id
    }
    
    # Kubernetes Configuration
    kubernetes = {
      cluster_name     = module.gke.cluster_name
      cluster_endpoint = module.gke.cluster_endpoint
      region          = var.region
      service_account = module.security.zenml_service_account_email
    }
  }
  sensitive = true
}

# Network Connectivity Information
output "mysql_network_diagnostics" {
  description = "Network diagnostics information for troubleshooting MySQL connectivity"
  value       = module.mysql.mysql_network_diagnostics
}

output "vpc_subnet_cidrs" {
  description = "VPC subnet CIDR blocks for network configuration"
  value       = module.vpc.subnet_cidrs
}

# Quick Access Commands
output "quick_commands" {
  description = "Quick commands for accessing and managing the infrastructure"
  value = {
    configure_kubectl    = "gcloud container clusters get-credentials ${module.gke.cluster_name} --region ${var.region} --project ${var.project_id}"
    get_mysql_password   = "gcloud secrets versions access latest --secret='${module.mysql.zenml_database_password_secret_id}' --project='${var.project_id}'"
    test_mysql_connection = "kubectl run mysql-test --image=mysql:8.0 --rm -it --restart=Never -- mysql -h ${module.mysql.mysql_instance_private_ip} -u ${module.mysql.zenml_database_username} -p${module.mysql.zenml_database_name}"
    list_secrets         = "gcloud secrets list --filter='name~zenml' --project='${var.project_id}'"
  }
}

