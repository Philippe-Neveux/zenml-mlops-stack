# VPC Module - Main Configuration for GCP

# VPC Network
resource "google_compute_network" "main" {
  name                    = "${var.project_name}-vpc"
  auto_create_subnetworks = false
  project                 = var.project_id

  # Enable deletion protection in production
  delete_default_routes_on_create = false
}

# Primary Subnet for GKE nodes
resource "google_compute_subnetwork" "gke_nodes_subnet" {
  name          = "${var.project_name}-gke-nodes-subnet"
  ip_cidr_range = var.subnet_cidrs["gke-nodes-subnet"]
  region        = var.region
  network       = google_compute_network.main.id
  project       = var.project_id

  # Enable private Google access for nodes without external IPs
  private_ip_google_access = true

  # Secondary IP ranges for pods and services
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.subnet_cidrs["pods"]
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.subnet_cidrs["services"]
  }
}

# Secondary subnet for additional workloads
resource "google_compute_subnetwork" "non_gke_workloads_subnet" {
  name          = "${var.project_name}-non-gke-workloads-subnet"
  ip_cidr_range = var.subnet_cidrs["non-gke-workloads-subnet"]
  region        = var.region
  network       = google_compute_network.main.id
  project       = var.project_id

  private_ip_google_access = true
}

# Router for NAT Gateway
resource "google_compute_router" "main" {
  name    = "${var.project_name}-router"
  region  = var.region
  network = google_compute_network.main.id
  project = var.project_id

  bgp {
    asn = 64514
  }
}

# NAT Gateway for outbound internet access from private nodes
resource "google_compute_router_nat" "main" {
  name                               = "${var.project_name}-nat"
  router                             = google_compute_router.main.name
  region                             = var.region
  project                            = var.project_id
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Firewall rule to allow internal communication
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.project_name}-allow-internal"
  network = google_compute_network.main.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [
    var.vpc_cidr,
    var.subnet_cidrs["pods"],
    var.subnet_cidrs["services"]
  ]

  priority = 1000
}

# Firewall rule to allow SSH (for debugging)
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.project_name}-allow-ssh"
  network = google_compute_network.main.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [
    "35.235.240.0/20" # Google Cloud Console IP range
  ]
  target_tags = ["ssh"]

  priority = 1000
}

# Firewall rule for health checks
resource "google_compute_firewall" "allow_health_checks" {
  name    = "${var.project_name}-allow-health-checks"
  network = google_compute_network.main.name
  project = var.project_id

  allow {
    protocol = "tcp"
  }

  source_ranges = [
    "130.211.0.0/22", # Google Load Balancer health checks
    "35.191.0.0/16"   # Google Load Balancer health checks
  ]

  target_tags = ["gke-node"]
  priority    = 1000
}

# Global IP address for ingress
resource "google_compute_global_address" "ingress" {
  name    = "${var.project_name}-ingress-ip"
  project = var.project_id
}

# Private IP allocation for managed services (Cloud SQL)
resource "google_compute_global_address" "private_service_access" {
  name          = "${var.project_name}-private-service-access"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.main.id
  project       = var.project_id
}

# Private service access connection for Cloud SQL
resource "google_service_networking_connection" "private_service_access" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_access.name]
}
