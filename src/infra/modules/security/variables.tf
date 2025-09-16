# Security Module Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
}

variable "region" {
  description = "Google Cloud region"
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "enable_binary_authorization" {
  description = "Enable binary authorization"
  type        = bool
  default     = false
}

variable "labels" {
  description = "A map of labels to assign to the resource"
  type        = map(string)
  default     = {}
}

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
