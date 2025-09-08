# MySQL Database Module for ZenML
# This module creates a Cloud SQL MySQL instance for ZenML metadata storage

# Random password for MySQL root user
resource "random_password" "mysql_root_password" {
  length  = 32
  special = true
}

# Random password for ZenML database user
resource "random_password" "zenml_db_password" {
  length  = 32
  special = true
}

# Random password for MLflow database user
resource "random_password" "mlflow_db_password" {
  length  = 32
  special = false
  upper   = true
  lower   = true
  numeric = true
}

# Cloud SQL MySQL Instance
resource "google_sql_database_instance" "zenml_mysql" {
  name             = "${var.project_name}-mysql"
  database_version = var.mysql_version
  region           = var.region
  project          = var.project_id

  # Deletion protection
  deletion_protection = var.deletion_protection

  settings {
    tier                  = var.mysql_tier
    availability_type     = var.availability_type
    disk_type             = var.disk_type
    disk_size             = var.disk_size
    disk_autoresize       = var.disk_autoresize
    disk_autoresize_limit = var.disk_autoresize_limit

    # IP configuration
    ip_configuration {
      ipv4_enabled                                  = var.public_ip_enabled
      private_network                               = var.private_network_id
      enable_private_path_for_google_cloud_services = true
      ssl_mode                                      = var.ssl_mode

      # Authorized networks - Only applies to public IP instances
      # For private IP instances, access is controlled by VPC peering and firewall rules
      dynamic "authorized_networks" {
        for_each = var.public_ip_enabled ? var.authorized_networks : []
        content {
          name  = authorized_networks.value.name
          value = authorized_networks.value.value
        }
      }
    }

    # Database flags for MySQL optimization
    dynamic "database_flags" {
      for_each = var.database_flags
      content {
        name  = database_flags.value.name
        value = database_flags.value.value
      }
    }

    # User labels
    user_labels = var.labels
  }

  # Lifecycle management
  lifecycle {
    prevent_destroy = false
  }

  # Ensure private service connection is established first
  depends_on = [var.private_service_connection]
}

# ZenML Database
resource "google_sql_database" "zenml" {
  name     = var.zenml_database_name
  instance = google_sql_database_instance.zenml_mysql.name
  project  = var.project_id

  charset   = "utf8mb4"
  collation = "utf8mb4_unicode_ci"
}

# MLflow Database
resource "google_sql_database" "mlflow" {
  name     = var.mlflow_database_name
  instance = google_sql_database_instance.zenml_mysql.name
  project  = var.project_id

  charset   = "utf8mb4"
  collation = "utf8mb4_unicode_ci"
}

# Root MySQL user
resource "google_sql_user" "root" {
  name     = "root"
  instance = google_sql_database_instance.zenml_mysql.name
  project  = var.project_id
  password = random_password.mysql_root_password.result
}

# ZenML Database User
resource "google_sql_user" "zenml" {
  name     = var.zenml_db_username
  instance = google_sql_database_instance.zenml_mysql.name
  project  = var.project_id
  password = random_password.zenml_db_password.result
}

# ZenML Database User for external access (from authorized IPs)
resource "google_sql_user" "zenml_external" {
  name     = var.zenml_db_username
  instance = google_sql_database_instance.zenml_mysql.name
  project  = var.project_id
  password = random_password.zenml_db_password.result
  host     = "%" # Allow connections from any host (restricted by authorized_networks)
}

# MLflow Database User
resource "google_sql_user" "mlflow" {
  name     = var.mlflow_db_username
  instance = google_sql_database_instance.zenml_mysql.name
  project  = var.project_id
  password = random_password.mlflow_db_password.result
}

# MLflow Database User for external access (from authorized IPs)
resource "google_sql_user" "mlflow_external" {
  name     = var.mlflow_db_username
  instance = google_sql_database_instance.zenml_mysql.name
  project  = var.project_id
  password = random_password.mlflow_db_password.result
  host     = "%" # Allow connections from any host (restricted by authorized_networks)
}

# Store database credentials in Secret Manager
resource "google_secret_manager_secret" "mysql_root_password" {
  secret_id = "${var.project_name}-mysql-root-password"
  project   = var.project_id

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  labels = var.labels
}

resource "google_secret_manager_secret_version" "mysql_root_password" {
  secret      = google_secret_manager_secret.mysql_root_password.id
  secret_data = random_password.mysql_root_password.result
}

resource "google_secret_manager_secret" "zenml_db_password" {
  secret_id = "${var.project_name}-zenml-db-password"
  project   = var.project_id

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  labels = var.labels
}

resource "google_secret_manager_secret_version" "zenml_db_password" {
  secret      = google_secret_manager_secret.zenml_db_password.id
  secret_data = random_password.zenml_db_password.result
}

# Store MLflow database credentials in Secret Manager
resource "google_secret_manager_secret" "mlflow_db_user" {
  secret_id = "${var.project_name}-mlflow-db-user"
  project   = var.project_id

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  labels = var.labels
}

resource "google_secret_manager_secret_version" "mlflow_db_user" {
  secret      = google_secret_manager_secret.mlflow_db_user.id
  secret_data = var.mlflow_db_username
}

resource "google_secret_manager_secret" "mlflow_db_password" {
  secret_id = "${var.project_name}-mlflow-db-password"
  project   = var.project_id

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  labels = var.labels
}

resource "google_secret_manager_secret_version" "mlflow_db_password" {
  secret      = google_secret_manager_secret.mlflow_db_password.id
  secret_data = random_password.mlflow_db_password.result
}

# Store complete ZenML database connection string
resource "google_secret_manager_secret" "zenml_db_connection" {
  secret_id = "${var.project_name}-zenml-db-connection"
  project   = var.project_id

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  labels = var.labels
}

resource "google_secret_manager_secret_version" "zenml_db_connection" {
  secret = google_secret_manager_secret.zenml_db_connection.id
  secret_data = jsonencode({
    host     = google_sql_database_instance.zenml_mysql.private_ip_address
    port     = 3306
    database = google_sql_database.zenml.name
    username = google_sql_user.zenml.name
    password = random_password.zenml_db_password.result
    url      = "mysql://${google_sql_user.zenml.name}:${random_password.zenml_db_password.result}@${google_sql_database_instance.zenml_mysql.private_ip_address}:3306/${google_sql_database.zenml.name}"
  })
}

# Store complete MLflow database connection string
resource "google_secret_manager_secret" "mlflow_db_connection" {
  secret_id = "${var.project_name}-mlflow-db-connection"
  project   = var.project_id

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  labels = var.labels
}

resource "google_secret_manager_secret_version" "mlflow_db_connection" {
  secret = google_secret_manager_secret.mlflow_db_connection.id
  secret_data = jsonencode({
    host     = google_sql_database_instance.zenml_mysql.private_ip_address
    port     = 3306
    database = google_sql_database.mlflow.name
    username = google_sql_user.mlflow.name
    password = random_password.mlflow_db_password.result
    url      = "mysql+pymysql://${google_sql_user.mlflow.name}:${random_password.mlflow_db_password.result}@${google_sql_database_instance.zenml_mysql.private_ip_address}:3306/${google_sql_database.mlflow.name}"
  })
}

# Note: For private IP Cloud SQL instances, network access is automatically
# managed through VPC peering and private service connections.
# Firewall rules are not typically needed for Cloud SQL private IP access
# as it's handled at the VPC peering level.