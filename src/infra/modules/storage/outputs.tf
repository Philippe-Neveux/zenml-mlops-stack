# Google Cloud Storage Module Outputs

# ZenML Storage Outputs
output "bucket_name" {
  description = "Name of the created storage bucket"
  value       = google_storage_bucket.zenml_artifacts.name
}

output "bucket_url" {
  description = "URL of the created storage bucket"
  value       = google_storage_bucket.zenml_artifacts.url
}

output "zenml_bucket_name" {
  description = "Name of the ZenML artifacts storage bucket"
  value       = google_storage_bucket.zenml_artifacts.name
}

output "zenml_bucket_url" {
  description = "URL of the ZenML artifacts storage bucket"
  value       = google_storage_bucket.zenml_artifacts.url
}

# MLflow Storage Outputs
output "mlflow_bucket_name" {
  description = "Name of the MLflow artifacts storage bucket"
  value       = google_storage_bucket.mlflow_artifacts.name
}

output "mlflow_bucket_url" {
  description = "URL of the MLflow artifacts storage bucket"
  value       = google_storage_bucket.mlflow_artifacts.url
}

output "mlflow_bucket_gs_uri" {
  description = "GS URI of the MLflow artifacts storage bucket"
  value       = "gs://${google_storage_bucket.mlflow_artifacts.name}"
}