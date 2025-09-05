# Google Cloud Storage Module Outputs


output "bucket_name" {
  description = "Name of the created storage bucket"
  value       = google_storage_bucket.zenml_artifacts.name
}


output "bucket_url" {
  description = "URL of the created storage bucket"
  value       = google_storage_bucket.zenml_artifacts.url
}