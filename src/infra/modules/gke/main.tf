# GKE Autopilot Module - Main Configuration

# Data source for available zones
data "google_container_engine_versions" "default" {
  location       = var.region
  version_prefix = var.cluster_version
  project        = var.project_id
}

# GKE Autopilot Cluster
resource "google_container_cluster" "main" {
  name     = var.project_name
  location = var.region
  project  = var.project_id

  # Network configuration
  network    = var.network_name
  subnetwork = var.subnet_name

  # Enable Autopilot mode
  enable_autopilot = true

  # Use the latest available version if not specified
  min_master_version = data.google_container_engine_versions.default.latest_master_version

  # Autopilot clusters don't support default node pools
  # remove_default_node_pool and initial_node_count are not needed

  # Private cluster configuration (simplified for Autopilot)
  private_cluster_config {
    enable_private_nodes    = var.enable_private_nodes
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  # Master authorized networks
  dynamic "master_authorized_networks_config" {
    for_each = length(var.master_authorized_networks) > 0 ? [1] : []
    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_networks
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }

  # IP allocation policy for secondary ranges
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Workload Identity (enabled by default in Autopilot)
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Binary Authorization
  dynamic "binary_authorization" {
    for_each = var.enable_binary_authorization ? [1] : []
    content {
      evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
    }
  }

  # Resource labels
  resource_labels = var.labels

  # Maintenance policy
  maintenance_policy {
    recurring_window {
      start_time = "2023-01-01T09:00:00Z"
      end_time   = "2023-01-01T17:00:00Z"
      recurrence = "FREQ=WEEKLY;BYDAY=SA,SU"
    }
  }

  # Release channel for automatic updates
  release_channel {
    channel = var.release_channel
  }
}
