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

# Secret Manager secret for ZenML default username
resource "google_secret_manager_secret" "zenml_default_username" {
  secret_id = "${var.project_name}-default-username"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = var.labels
}

# Secret Manager secret version for ZenML default username
resource "google_secret_manager_secret_version" "zenml_default_username" {
  secret      = google_secret_manager_secret.zenml_default_username.id
  secret_data = var.zenml_default_username
}

# Secret Manager secret for ZenML default password
resource "google_secret_manager_secret" "zenml_default_password" {
  secret_id = "${var.project_name}-default-password"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = var.labels
}

# Secret Manager secret version for ZenML default password
resource "google_secret_manager_secret_version" "zenml_default_password" {
  secret      = google_secret_manager_secret.zenml_default_password.id
  secret_data = var.zenml_default_password
}

# Custom IAM Roles for ZenML Secret Manager access
resource "google_project_iam_custom_role" "zenml_secrets_store_creator" {
  role_id     = "ZenMLServerSecretsStoreCreator"
  title       = "ZenML Server Secrets Store Creator"
  description = "Allow the ZenML Server to create new secrets"
  stage       = "GA"
  project     = var.project_id

  permissions = [
    "secretmanager.secrets.create"
  ]
}

resource "google_project_iam_custom_role" "zenml_secrets_store_editor" {
  role_id     = "ZenMLServerSecretsStoreEditor"
  title       = "ZenML Server Secrets Store Editor"
  description = "Allow the ZenML Server to manage its secrets"
  stage       = "GA"
  project     = var.project_id

  permissions = [
    "secretmanager.secrets.get",
    "secretmanager.secrets.update",
    "secretmanager.versions.access",
    "secretmanager.versions.add",
    "secretmanager.secrets.delete"
  ]
}

# ZenML Service Account for Secret Manager access
resource "google_service_account" "zenml" {
  account_id   = "${var.project_name}-zenml"
  display_name = "ZenML Service Account"
  description  = "Service account for ZenML workloads to access secrets and services"
  project      = var.project_id
}

# IAM bindings for ZenML service account with custom roles
resource "google_project_iam_member" "zenml_secrets_store_creator" {
  project = var.project_id
  role    = google_project_iam_custom_role.zenml_secrets_store_creator.id
  member  = "serviceAccount:${google_service_account.zenml.email}"
}

resource "google_project_iam_member" "zenml_secrets_store_editor" {
  project = var.project_id
  role    = google_project_iam_custom_role.zenml_secrets_store_editor.id
  member  = "serviceAccount:${google_service_account.zenml.email}"

  condition {
    title       = "limit_access_zenml"
    description = "Limit access to secrets with prefix zenml-"
    expression  = "resource.name.startsWith(\"projects/${data.google_project.current.number}/secrets/zenml-\")"
  }
}

resource "google_project_iam_member" "zenml_cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.zenml.email}"
}

resource "google_project_iam_member" "zenml_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.zenml.email}"
}

# GKE cluster access for ZenML service account
resource "google_project_iam_member" "zenml_gke_viewer" {
  project = var.project_id
  role    = "roles/container.clusterViewer"
  member  = "serviceAccount:${google_service_account.zenml.email}"
}

# Artifact Registry write access for ZenML service account
resource "google_project_iam_member" "zenml_artifact_registry_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.zenml.email}"
}

# Container developer access for ZenML service account
resource "google_project_iam_member" "zenml_container_developer" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.zenml.email}"
}

resource "google_project_iam_member" "zenml_cloudrun_viewer" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.zenml.email}"
}

resource "google_project_iam_member" "zenml_act_as_service_account" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.zenml.email}"
}


resource "google_project_iam_member" "zenml_container_admin" {
  project = var.project_id
  role    = "roles/container.admin"
  member  = "serviceAccount:${google_service_account.zenml.email}"
}

# Workload Identity binding for ZenML server
resource "google_service_account_iam_member" "zenml_workload_identity" {
  service_account_id = google_service_account.zenml.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[zenml/zenml-server]"
}

# Workload Identity binding for ZenML orchestrator service account
resource "google_service_account_iam_member" "zenml_orchestrator_workload_identity" {
  service_account_id = google_service_account.zenml.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[zenml/zenml-service-account]"
}

# Workload Identity binding for ZenML database migration job
resource "google_service_account_iam_member" "zenml_db_migration_workload_identity" {
  service_account_id = google_service_account.zenml.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[zenml/zenml-server-db-migration]"
}


# MLflow Service Account for database and storage access
resource "google_service_account" "mlflow" {
  account_id   = "${var.project_name}-mlflow"
  display_name = "MLflow Service Account"
  description  = "Service account for MLflow workloads to access database and storage"
  project      = var.project_id
}

# BentoML Service Account for deployment
resource "google_service_account" "bentoml" {
  account_id   = "bentoml-deployer"
  display_name = "BentoML Deployer"
  description  = "Service account for BentoML deployment"
  project      = var.project_id
}

# MLflow Service Account IAM bindings
resource "google_project_iam_member" "mlflow_cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.mlflow.email}"
}

resource "google_project_iam_member" "mlflow_storage_object_admin" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.mlflow.email}"
}


# Allow MLflow to access its own secrets in Secret Manager
resource "google_project_iam_member" "mlflow_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.mlflow.email}"

  condition {
    title       = "limit_access_mlflow"
    description = "Limit access to secrets with prefix mlflow-"
    expression  = "resource.name.startsWith(\"projects/${data.google_project.current.number}/secrets/${var.project_name}-mlflow-\")"
  }
}

# Workload Identity binding for MLflow service account
resource "google_service_account_iam_member" "mlflow_workload_identity" {
  service_account_id = google_service_account.mlflow.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[mlflow/mlflow]"
}

# BentoML Service Account IAM bindings
resource "google_project_iam_member" "bentoml_artifact_registry_admin" {
  project = var.project_id
  role    = "roles/artifactregistry.admin"
  member  = "serviceAccount:${google_service_account.bentoml.email}"
}

resource "google_project_iam_member" "bentoml_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.bentoml.email}"
}

resource "google_project_iam_member" "bentoml_service_account_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.bentoml.email}"
}

