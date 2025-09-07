# Google Cloud Storage Module Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
}

variable "region" {
  description = "Google Cloud region for the storage bucket"
  type        = string
}


variable "lifecycle_rules" {
  description = "List of lifecycle rules for the bucket"
  type = list(object({
    age    = number
    action = string
  }))
  default = [
    {
      age    = 30
      action = "Delete"
    }
  ]
}

variable "mlflow_lifecycle_rules" {
  description = "List of lifecycle rules for the MLflow bucket"
  type = list(object({
    age    = number
    action = string
  }))
  default = [
    {
      age    = 90 # Keep MLflow artifacts longer than ZenML artifacts
      action = "Delete"
    }
  ]
}


variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

variable "zenml_service_account_email" {
  description = "Email of the existing ZenML service account that will access the storage bucket"
  type        = string
}

variable "mlflow_service_account_email" {
  description = "Email of the MLflow service account that will access the MLflow storage bucket"
  type        = string
}

variable "depends_on_modules" {
  description = "List of modules this module depends on"
  type        = list(any)
  default     = []
}