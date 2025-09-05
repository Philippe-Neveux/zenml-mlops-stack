# Google Artifact Registry Module Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
}

variable "region" {
  description = "Google Cloud region for the artifact registry"
  type        = string
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

variable "zenml_service_account_email" {
  description = "Email of the ZenML service account for IAM bindings"
  type        = string
}

variable "image_retention_days" {
  description = "Number of days to retain images before cleanup"
  type        = number
  default     = 30
}

variable "minimum_versions_to_keep" {
  description = "Minimum number of image versions to keep regardless of age"
  type        = number
  default     = 5
}
