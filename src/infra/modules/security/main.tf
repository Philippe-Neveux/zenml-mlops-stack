# Security Module - Main Configuration for GCP

# Data source for current project
data "google_project" "current" {
  project_id = var.project_id
}

# Firewall rule for LoadBalancer ingress
resource "google_compute_firewall" "allow_lb_ingress" {
  name    = "${var.project_name}-allow-lb-ingress"
  network = var.network_name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["gke-node"]

  description = "Allow ingress traffic from load balancers"
  priority    = 1000
}

# Firewall rule for NodePort services
resource "google_compute_firewall" "allow_nodeport" {
  name    = "${var.project_name}-allow-nodeport"
  network = var.network_name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["30000-32767"]
  }

  source_ranges = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  target_tags   = ["gke-node"]

  description = "Allow NodePort services from private networks"
  priority    = 1000
}

# Service Account for Workload Identity (example for ArgoCD)
resource "google_service_account" "argocd" {
  account_id   = "${var.project_name}-argocd"
  display_name = "ArgoCD Service Account"
  description  = "Service account for ArgoCD workloads"
  project      = var.project_id
}

# IAM binding for ArgoCD service account
resource "google_project_iam_member" "argocd_compute_viewer" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.argocd.email}"
}

resource "google_project_iam_member" "argocd_container_developer" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.argocd.email}"
}

# IAM binding for Workload Identity
resource "google_service_account_iam_member" "argocd_workload_identity" {
  service_account_id = google_service_account.argocd.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[argocd/argocd-application-controller]"
}

# Cloud DNS zone for internal services (optional)
resource "google_dns_managed_zone" "internal" {
  name        = "${var.project_name}-internal"
  dns_name    = "${var.project_name}.internal."
  description = "Internal DNS zone for ${var.project_name}"
  project     = var.project_id

  visibility = "private"

  private_visibility_config {
    networks {
      network_url = "projects/${var.project_id}/global/networks/${var.network_name}"
    }
  }

  labels = var.labels
}

# Cloud KMS key ring for additional encryption needs
resource "google_kms_key_ring" "security" {
  name     = "${var.project_name}-security-keyring"
  location = var.region
  project  = var.project_id
}

# Cloud KMS key for application secrets
resource "google_kms_crypto_key" "app_secrets" {
  name            = "${var.project_name}-app-secrets"
  key_ring        = google_kms_key_ring.security.id
  rotation_period = "2592000s" # 30 days

  lifecycle {
    prevent_destroy = true
  }
}

# Secret Manager secret for storing sensitive configuration
resource "google_secret_manager_secret" "app_config" {
  secret_id = "${var.project_name}-app-config"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = var.labels
}

# IAM policy for Secret Manager
resource "google_secret_manager_secret_iam_member" "app_config_accessor" {
  secret_id = google_secret_manager_secret.app_config.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.argocd.email}"
}
