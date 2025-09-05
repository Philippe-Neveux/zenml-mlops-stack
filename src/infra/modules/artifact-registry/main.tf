# Google Artifact Registry Module - Main Configuration

# Google Artifact Registry repository for Docker images
resource "google_artifact_registry_repository" "zenml_artifact_registry" {
  location      = var.region
  project       = var.project_id
  repository_id = "zenml-artifact-registry"
  description   = "ZenML Artifact Registry for storing Docker images and ML artifacts"
  format        = "DOCKER"

  # Labels
  labels = merge(var.labels, {
    component = "artifact-registry"
    purpose   = "zenml-artifacts"
  })

}

# IAM binding for the ZenML service account to push/pull images
resource "google_artifact_registry_repository_iam_member" "zenml_artifact_registry_admin" {
  project    = var.project_id
  location   = google_artifact_registry_repository.zenml_artifact_registry.location
  repository = google_artifact_registry_repository.zenml_artifact_registry.name
  role       = "roles/artifactregistry.repoAdmin"
  member     = "serviceAccount:${var.zenml_service_account_email}"
}

# Additional IAM binding for read access to allow other services to pull images
resource "google_artifact_registry_repository_iam_member" "zenml_artifact_registry_reader" {
  project    = var.project_id
  location   = google_artifact_registry_repository.zenml_artifact_registry.location
  repository = google_artifact_registry_repository.zenml_artifact_registry.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${var.zenml_service_account_email}"
}
