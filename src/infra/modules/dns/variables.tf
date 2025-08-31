# DNS Module Variables

variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
}

variable "domain_name" {
  description = "Domain name to manage"
  type        = string
}

variable "zenml_ip_address" {
  description = "IP address for ZenML services"
  type        = string
}

variable "ttl" {
  description = "TTL for DNS records"
  type        = number
  default     = 300
}
