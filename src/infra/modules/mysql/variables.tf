# MySQL Module Variables

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

# MySQL Instance Configuration
variable "mysql_version" {
  description = "MySQL version for Cloud SQL instance"
  type        = string
  default     = "MYSQL_8_0"
}

variable "mysql_tier" {
  description = "Machine type for Cloud SQL instance"
  type        = string
  default     = "db-n1-standard-2"
}

variable "availability_type" {
  description = "Availability type for the Cloud SQL instance (ZONAL or REGIONAL)"
  type        = string
  default     = "ZONAL"
}

variable "disk_type" {
  description = "Disk type for Cloud SQL instance (PD_SSD or PD_HDD)"
  type        = string
  default     = "PD_SSD"
}

variable "disk_size" {
  description = "Initial disk size in GB"
  type        = number
  default     = 20
}

variable "disk_autoresize" {
  description = "Enable automatic disk resize"
  type        = bool
  default     = true
}

variable "disk_autoresize_limit" {
  description = "Maximum disk size for autoresize (GB)"
  type        = number
  default     = 100
}

# Network Configuration
variable "private_network_id" {
  description = "ID of the private network for the Cloud SQL instance"
  type        = string
}

variable "gke_cluster_subnet_cidrs" {
  description = "List of CIDR blocks for GKE cluster subnets that need database access"
  type        = list(string)
  default     = []
}

variable "public_ip_enabled" {
  description = "Enable public IP for the Cloud SQL instance"
  type        = bool
  default     = false
}

variable "ssl_mode" {
  description = "SSL mode for database connections. Options: ALLOW_UNENCRYPTED_AND_ENCRYPTED, ENCRYPTED_ONLY, TRUSTED_CLIENT_CERTIFICATE_REQUIRED"
  type        = string
  default     = "ENCRYPTED_ONLY"

  validation {
    condition = contains([
      "ALLOW_UNENCRYPTED_AND_ENCRYPTED",
      "ENCRYPTED_ONLY",
      "TRUSTED_CLIENT_CERTIFICATE_REQUIRED"
    ], var.ssl_mode)
    error_message = "SSL mode must be one of: ALLOW_UNENCRYPTED_AND_ENCRYPTED, ENCRYPTED_ONLY, TRUSTED_CLIENT_CERTIFICATE_REQUIRED."
  }
}

variable "authorized_networks" {
  description = "List of authorized networks for public IP access"
  type = list(object({
    name  = string
    value = string
  }))
  default = [
    {
      name  = "admin-access"
      value = "27.252.155.42/32" # Your current public IP
    }
  ]
}
# Database Configuration
variable "zenml_database_name" {
  description = "Name of the ZenML database"
  type        = string
  default     = "zenml"
}

variable "zenml_db_username" {
  description = "Username for ZenML database user"
  type        = string
  default     = "zenml"
}

variable "database_flags" {
  description = "List of database flags for MySQL optimization"
  type = list(object({
    name  = string
    value = string
  }))
  default = [
    {
      name  = "max_connections"
      value = "1000"
    },
    {
      name  = "innodb_log_file_size"
      value = "268435456" # 256MB
    },
    {
      name  = "sql_mode"
      value = "TRADITIONAL"
    },
    {
      name  = "innodb_file_per_table"
      value = "on"
    },
    {
      name  = "innodb_flush_log_at_trx_commit"
      value = "1" # ACID compliance for ZenML metadata integrity
    },
    {
      name  = "slow_query_log"
      value = "on"
    },
    {
      name  = "long_query_time"
      value = "2" # Log queries taking longer than 2 seconds
    }
  ]
}

# Security and Lifecycle
variable "deletion_protection" {
  description = "Enable deletion protection for the Cloud SQL instance"
  type        = bool
  default     = true
}

variable "labels" {
  description = "A map of labels to assign to the resource"
  type        = map(string)
  default     = {}
}
