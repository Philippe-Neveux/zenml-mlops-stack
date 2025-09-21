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

output "zenml_default_username_secret_id" {
  description = "ID of the ZenML default username secret"
  value       = google_secret_manager_secret.zenml_default_username.secret_id
}

output "zenml_default_password_secret_id" {
  description = "ID of the ZenML default password secret"
  value       = google_secret_manager_secret.zenml_default_password.secret_id
}

output "internal_dns_zone_name" {
  description = "Name of the internal DNS zone"
  value       = google_dns_managed_zone.internal.name
}

output "internal_dns_zone_dns_name" {
  description = "DNS name of the internal DNS zone"
  value       = google_dns_managed_zone.internal.dns_name
}

# Custom IAM Role outputs
output "zenml_secrets_store_creator_role_id" {
  description = "ID of the ZenML Secrets Store Creator custom role"
  value       = google_project_iam_custom_role.zenml_secrets_store_creator.id
}

output "zenml_secrets_store_editor_role_id" {
  description = "ID of the ZenML Secrets Store Editor custom role"
  value       = google_project_iam_custom_role.zenml_secrets_store_editor.id
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

# MLflow Service Account outputs
output "mlflow_service_account_email" {
  description = "Email of the MLflow service account for database and storage access"
  value       = google_service_account.mlflow.email
}

output "mlflow_service_account_name" {
  description = "Name of the MLflow service account"
  value       = google_service_account.mlflow.name
}

output "mlflow_service_account_key_id" {
  description = "Unique ID of the MLflow service account"
  value       = google_service_account.mlflow.unique_id
}

# BentoML Service Account outputs
output "bentoml_service_account_email" {
  description = "Email of the BentoML service account for deployment"
  value       = google_service_account.bentoml.email
}

output "bentoml_service_account_name" {
  description = "Name of the BentoML service account"
  value       = google_service_account.bentoml.name
}

output "bentoml_service_account_key_id" {
  description = "Unique ID of the BentoML service account"
  value       = google_service_account.bentoml.unique_id
}