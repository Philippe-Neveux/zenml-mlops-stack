# VPC Module Outputs

output "network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.main.name
}

output "network_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.main.id
}

output "network_self_link" {
  description = "Self link of the VPC network"
  value       = google_compute_network.main.self_link
}

output "subnet_name" {
  description = "Name of the primary subnet"
  value       = google_compute_subnetwork.gke_nodes_subnet.name
}

output "subnet_id" {
  description = "ID of the primary subnet"
  value       = google_compute_subnetwork.gke_nodes_subnet.id
}

output "subnet_self_link" {
  description = "Self link of the primary subnet"
  value       = google_compute_subnetwork.gke_nodes_subnet.self_link
}

output "secondary_subnet_name" {
  description = "Name of the secondary subnet"
  value       = google_compute_subnetwork.non_gke_workloads_subnet.name
}

output "secondary_subnet_id" {
  description = "ID of the secondary subnet"
  value       = google_compute_subnetwork.non_gke_workloads_subnet.id
}

output "pods_range_name" {
  description = "Name of the pods secondary IP range"
  value       = google_compute_subnetwork.gke_nodes_subnet.secondary_ip_range[0].range_name
}

output "services_range_name" {
  description = "Name of the services secondary IP range"
  value       = google_compute_subnetwork.gke_nodes_subnet.secondary_ip_range[1].range_name
}

output "router_name" {
  description = "Name of the Cloud Router"
  value       = google_compute_router.main.name
}

output "nat_name" {
  description = "Name of the Cloud NAT"
  value       = google_compute_router_nat.main.name
}

output "ingress_ip_address" {
  description = "Global IP address for ingress"
  value       = google_compute_global_address.ingress.address
}

output "ingress_ip_name" {
  description = "Name of the global IP address for ingress"
  value       = google_compute_global_address.ingress.name
}

output "private_service_access_address" {
  description = "Private service access IP address range"
  value       = google_compute_global_address.private_service_access.address
}

output "private_service_access_name" {
  description = "Name of the private service access range"
  value       = google_compute_global_address.private_service_access.name
}

# CIDR block outputs for networking
output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = var.vpc_cidr
}

output "gke_nodes_subnet_cidr" {
  description = "CIDR block of the GKE nodes subnet"
  value       = google_compute_subnetwork.gke_nodes_subnet.ip_cidr_range
}

output "pods_cidr" {
  description = "CIDR block for pods secondary range"
  value       = google_compute_subnetwork.gke_nodes_subnet.secondary_ip_range[0].ip_cidr_range
}

output "services_cidr" {
  description = "CIDR block for services secondary range"
  value       = google_compute_subnetwork.gke_nodes_subnet.secondary_ip_range[1].ip_cidr_range
}

output "subnet_cidrs" {
  description = "Map of all subnet CIDR blocks"
  value = {
    gke_nodes_subnet = google_compute_subnetwork.gke_nodes_subnet.ip_cidr_range
    pods            = google_compute_subnetwork.gke_nodes_subnet.secondary_ip_range[0].ip_cidr_range
    services        = google_compute_subnetwork.gke_nodes_subnet.secondary_ip_range[1].ip_cidr_range
    non_gke_workloads = google_compute_subnetwork.non_gke_workloads_subnet.ip_cidr_range
  }
}
