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

output "argocd_service_account_email" {
  description = "Email of the ArgoCD service account"
  value       = module.security.argocd_service_account_email
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

# ArgoCD Access Information
output "argocd_access_info" {
  description = "Information for accessing ArgoCD"
  value = {
    cluster_name           = module.gke.cluster_name
    cluster_endpoint       = module.gke.cluster_endpoint
    kubectl_config_command = "gcloud container clusters get-credentials ${module.gke.cluster_name} --region ${var.region} --project ${var.project_id}"
    ingress_ip             = module.vpc.ingress_ip_address
    service_account        = module.security.argocd_service_account_email
  }
  sensitive = true
}
