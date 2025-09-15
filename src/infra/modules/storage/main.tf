# Google Cloud Storage Module - Main Configuration

# Google Cloud Storage bucket for ZenML artifacts
resource "google_storage_bucket" "zenml_artifacts" {
  name     = "${var.project_id}-zenml-artifacts"
  location = var.region
  project  = var.project_id

  # Uniform bucket-level access
  uniform_bucket_level_access = true

  # Versioning configuration
  versioning {
    enabled = false
  }

  # Lifecycle management
  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    content {
      condition {
        age = lifecycle_rule.value.age
      }
      action {
        type = lifecycle_rule.value.action
      }
    }
  }

  # Labels
  labels = merge(var.labels, {
    component = "storage"
    purpose   = "zenml-artifacts"
  })

  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = true
  }

  # Public access prevention
  public_access_prevention = "enforced"

}

# Google Cloud Storage bucket for MLflow artifacts
resource "google_storage_bucket" "mlflow_artifacts" {
  name     = "${var.project_id}-mlflow-artifacts"
  location = var.region
  project  = var.project_id

  # Uniform bucket-level access
  uniform_bucket_level_access = true

  # Versioning configuration
  versioning {
    enabled = false
  }

  # Lifecycle management
  dynamic "lifecycle_rule" {
    for_each = var.mlflow_lifecycle_rules
    content {
      condition {
        age = lifecycle_rule.value.age
      }
      action {
        type = lifecycle_rule.value.action
      }
    }
  }

  # Labels
  labels = merge(var.labels, {
    component = "storage"
    purpose   = "mlflow-artifacts"
  })

  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = true
  }

  # Public access prevention
  public_access_prevention = "enforced"
}

# IAM binding for the existing ZenML service account to access the bucket
resource "google_storage_bucket_iam_member" "zenml_storage_admin" {
  bucket = google_storage_bucket.zenml_artifacts.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.zenml_service_account_email}"
}

resource "google_storage_bucket_iam_member" "zenml_storage_user" {
  bucket = google_storage_bucket.zenml_artifacts.name
  role   = "roles/storage.objectUser"
  member = "serviceAccount:${var.zenml_service_account_email}"
}

# IAM binding for MLflow service account to access the MLflow bucket
resource "google_storage_bucket_iam_member" "mlflow_storage_admin" {
  bucket = google_storage_bucket.mlflow_artifacts.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.mlflow_service_account_email}"
}

resource "google_storage_bucket_iam_member" "mlflow_storage_user" {
  bucket = google_storage_bucket.mlflow_artifacts.name
  role   = "roles/storage.objectUser"
  member = "serviceAccount:${var.mlflow_service_account_email}"
}
