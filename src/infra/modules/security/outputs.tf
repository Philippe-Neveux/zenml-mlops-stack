# Security Module Outputs

output "argocd_service_account_email" {
  description = "Email of the ArgoCD service account"
  value       = google_service_account.argocd.email
}

output "argocd_service_account_name" {
  description = "Name of the ArgoCD service account"
  value       = google_service_account.argocd.name
}

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

output "binary_authorization_policy_id" {
  description = "ID of the binary authorization policy"
  value       = var.enable_binary_authorization ? google_binary_authorization_policy.main[0].id : null
}
