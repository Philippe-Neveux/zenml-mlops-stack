# VPC Module Variables

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

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidrs" {
  description = "CIDR blocks for subnets"
  type        = map(string)
  default = {
    gke-nodes-subnet         = "10.0.1.0/24"
    non-gke-workloads-subnet = "10.0.2.0/24"
    pods                     = "10.1.0.0/16"
    services                 = "10.2.0.0/16"
  }
}

variable "enable_private_nodes" {
  description = "Enable private nodes (no external IP)"
  type        = bool
  default     = true
}

variable "labels" {
  description = "A map of labels to assign to the resource"
  type        = map(string)
  default     = {}
}
