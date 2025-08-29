# GKE Autopilot Module Outputs

output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.main.name
}

output "cluster_id" {
  description = "ID of the GKE cluster"
  value       = google_container_cluster.main.id
}

output "cluster_location" {
  description = "Location of the GKE cluster"
  value       = google_container_cluster.main.location
}

output "cluster_endpoint" {
  description = "Endpoint for GKE control plane"
  value       = google_container_cluster.main.endpoint
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate (base64 encoded)"
  value       = google_container_cluster.main.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_master_version" {
  description = "Current master version"
  value       = google_container_cluster.main.master_version
}

output "cluster_min_master_version" {
  description = "Minimum master version"
  value       = google_container_cluster.main.min_master_version
}

output "cluster_services_ipv4_cidr" {
  description = "CIDR block for services"
  value       = google_container_cluster.main.services_ipv4_cidr
}

output "cluster_ipv4_cidr_block" {
  description = "CIDR block for cluster pods"
  value       = google_container_cluster.main.cluster_ipv4_cidr
}

output "workload_identity_pool" {
  description = "Workload identity pool (enabled by default in Autopilot)"
  value       = "${var.project_id}.svc.id.goog"
}

output "autopilot_enabled" {
  description = "Whether Autopilot is enabled"
  value       = true
}

output "release_channel" {
  description = "Release channel for the cluster"
  value       = var.release_channel
}
