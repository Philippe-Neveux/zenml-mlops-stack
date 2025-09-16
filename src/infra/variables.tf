# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "zenml"
}

variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
  default     = "zenml-472221"
}

variable "region" {
  description = "Google Cloud region"
  type        = string
  default     = "australia-southeast1"
}

variable "zone" {
  description = "Google Cloud zone"
  type        = string
  default     = "australia-southeast1-b"
}

# Common Labels
variable "common_labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default = {
    project    = "zenml-mlops"
    owner      = "devops"
    managed-by = "terraform"
  }
}

variable "enable_https" {
  description = "Enable HTTPS with Let's Encrypt certificates"
  type        = bool
  default     = true
}

variable "admin_email" {
  description = "Email address for Let's Encrypt certificate notifications"
  type        = string
  default     = "pneveux.gcp3@gmail.com"
}

# ZenML Authentication Configuration
variable "zenml_default_username" {
  description = "Default username for ZenML server"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "zenml_default_password" {
  description = "Default password for ZenML server"
  type        = string
  default     = "admin123!"
  sensitive   = true
}
