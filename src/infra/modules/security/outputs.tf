# Security Module Outputs

output "kms_key_ring_id" {
  description = "ID of the KMS key ring"
  value       = google_kms_key_ring.security.id
}

output "app_secrets_key_id" {
  description = "ID of the application secrets KMS key"
  value       = google_kms_crypto_key.app_secrets.id
}

output "app_config_secret_id" {
  description = "ID of the application config secret"
  value       = google_secret_manager_secret.app_config.secret_id
}

output "internal_dns_zone_name" {
  description = "Name of the internal DNS zone"
  value       = google_dns_managed_zone.internal.name
}

output "internal_dns_zone_dns_name" {
  description = "DNS name of the internal DNS zone"
  value       = google_dns_managed_zone.internal.dns_name
}

# ZenML Service Account outputs
output "zenml_service_account_email" {
  description = "Email of the ZenML service account for Secret Manager access"
  value       = google_service_account.zenml.email
}

output "zenml_service_account_name" {
  description = "Name of the ZenML service account"
  value       = google_service_account.zenml.name
}

output "zenml_service_account_key_id" {
  description = "Unique ID of the ZenML service account"
  value       = google_service_account.zenml.unique_id
}