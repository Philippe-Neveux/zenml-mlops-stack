# Google Artifact Registry Module Outputs

output "repository_id" {
  description = "The ID of the artifact registry repository"
  value       = google_artifact_registry_repository.zenml_artifact_registry.repository_id
}

output "repository_name" {
  description = "The full name of the artifact registry repository"
  value       = google_artifact_registry_repository.zenml_artifact_registry.name
}

output "repository_url" {
  description = "The URL of the artifact registry repository"
  value       = "${google_artifact_registry_repository.zenml_artifact_registry.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.zenml_artifact_registry.repository_id}"
}

output "location" {
  description = "The location of the artifact registry repository"
  value       = google_artifact_registry_repository.zenml_artifact_registry.location
}
