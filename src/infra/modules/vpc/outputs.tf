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
