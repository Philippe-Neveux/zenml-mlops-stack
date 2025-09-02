# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "zenml"
}

variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
  default     = "zenml-470505"
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
  default     = "admin@example.com"
}
