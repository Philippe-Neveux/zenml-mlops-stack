# MySQL Module Outputs

output "mysql_instance_name" {
  description = "Name of the Cloud SQL MySQL instance"
  value       = google_sql_database_instance.zenml_mysql.name
}

output "mysql_instance_connection_name" {
  description = "Connection name of the Cloud SQL MySQL instance"
  value       = google_sql_database_instance.zenml_mysql.connection_name
}

output "mysql_instance_private_ip" {
  description = "Private IP address of the Cloud SQL MySQL instance"
  value       = google_sql_database_instance.zenml_mysql.private_ip_address
}

output "mysql_instance_public_ip" {
  description = "Public IP address of the Cloud SQL MySQL instance"
  value       = google_sql_database_instance.zenml_mysql.public_ip_address
}

output "mysql_instance_self_link" {
  description = "Self-link of the Cloud SQL MySQL instance"
  value       = google_sql_database_instance.zenml_mysql.self_link
}

output "zenml_database_name" {
  description = "Name of the ZenML database"
  value       = google_sql_database.zenml.name
}

output "zenml_database_username" {
  description = "Username for ZenML database access"
  value       = google_sql_user.zenml.name
}

output "zenml_database_password_secret_id" {
  description = "Secret Manager secret ID for ZenML database password"
  value       = google_secret_manager_secret.zenml_db_password.secret_id
}

output "mysql_root_password_secret_id" {
  description = "Secret Manager secret ID for MySQL root password"
  value       = google_secret_manager_secret.mysql_root_password.secret_id
}

output "zenml_db_connection_secret_id" {
  description = "Secret Manager secret ID for complete ZenML database connection info"
  value       = google_secret_manager_secret.zenml_db_connection.secret_id
}

output "zenml_database_url" {
  description = "Complete database URL for ZenML (sensitive)"
  value       = "mysql://${google_sql_user.zenml.name}:${random_password.zenml_db_password.result}@${google_sql_database_instance.zenml_mysql.private_ip_address}:3306/${google_sql_database.zenml.name}"
  sensitive   = true
}

output "zenml_database_connection_info" {
  description = "ZenML database connection information"
  value = {
    host     = google_sql_database_instance.zenml_mysql.private_ip_address
    port     = 3306
    database = google_sql_database.zenml.name
    username = google_sql_user.zenml.name
    instance_connection_name = google_sql_database_instance.zenml_mysql.connection_name
  }
  sensitive = false
}

output "zenml_database_connection_info_sensitive" {
  description = "ZenML database connection information including password"
  value = {
    host     = google_sql_database_instance.zenml_mysql.private_ip_address
    port     = 3306
    database = google_sql_database.zenml.name
    username = google_sql_user.zenml.name
    password = random_password.zenml_db_password.result
    url      = "mysql://${google_sql_user.zenml.name}:${random_password.zenml_db_password.result}@${google_sql_database_instance.zenml_mysql.private_ip_address}:3306/${google_sql_database.zenml.name}"
    instance_connection_name = google_sql_database_instance.zenml_mysql.connection_name
  }
  sensitive = true
}

# Additional outputs for ZenML Helm chart configuration
output "zenml_helm_database_config" {
  description = "Database configuration formatted for ZenML Helm chart values"
  value = {
    host     = google_sql_database_instance.zenml_mysql.private_ip_address
    port     = "3306"
    database = google_sql_database.zenml.name
    username = google_sql_user.zenml.name
    sslMode  = "PREFERRED"  # ZenML Helm chart expects this format
  }
  sensitive = false
}

output "zenml_database_secret_refs" {
  description = "Secret Manager references for ZenML Helm chart external secrets"
  value = {
    password_secret_name    = google_secret_manager_secret.zenml_db_password.secret_id
    connection_secret_name  = google_secret_manager_secret.zenml_db_connection.secret_id
  }
}

# Connectivity verification outputs
output "mysql_connectivity_info" {
  description = "Information for verifying MySQL connectivity from Kubernetes"
  value = {
    private_ip_address = google_sql_database_instance.zenml_mysql.private_ip_address
    network_name      = regex("projects/[^/]+/global/networks/(.+)", var.private_network_id)[0]
    firewall_rules    = length(var.gke_cluster_subnet_cidrs) > 0 ? [google_compute_firewall.mysql_access_from_gke[0].name] : []
    connection_test_command = "kubectl run mysql-test --image=mysql:8.0 --rm -it --restart=Never -- mysql -h ${google_sql_database_instance.zenml_mysql.private_ip_address} -u ${google_sql_user.zenml.name} -p${random_password.zenml_db_password.result} ${google_sql_database.zenml.name}"
  }
  sensitive = true
}

output "mysql_network_diagnostics" {
  description = "Network diagnostics information for troubleshooting connectivity"
  value = {
    mysql_private_ip = google_sql_database_instance.zenml_mysql.private_ip_address
    mysql_port      = 3306
    vpc_network     = var.private_network_id
    authorized_cidrs = var.gke_cluster_subnet_cidrs
    ssl_mode        = var.ssl_mode
  }
  sensitive = false
}
