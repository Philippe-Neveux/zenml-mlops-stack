# MLflow Infrastructure

This directory contains all Kubernetes manifests for deploying MLflow in the ZenML MLOps stack.

## Components

### Infrastructure Resources
- **Namespace**: `mlflow` - Dedicated namespace for MLflow components
- **ServiceAccount**: `mlflow` - Kubernetes service account with Workload Identity annotation
- **RBAC**: Role and RoleBinding for secret access within the namespace

### External Secrets
- **SecretStore**: `mlflow-secret-store` - Connects to GCP Secret Manager using Workload Identity
- **ExternalSecret**: `mlflow-database-secret` - Pulls database credentials from Secret Manager

## Deployment

The MLflow infrastructure is deployed via ArgoCD using the `mlflow` application which:

1. **Sync Wave 3**: Deploys after external-secrets-operator and cert-manager
2. **Auto-sync**: Automatically syncs changes from the Git repository
3. **Namespace Creation**: Creates the `mlflow` namespace automatically

## Dependencies

### Terraform Infrastructure
The following resources must be deployed via Terraform first:
- MLflow database (`mlflow`) on existing MySQL instance
- MLflow GCS bucket (`zenml-mlflow-artifacts`)
- MLflow GCP service account (`zenml-mlflow`)
- Secret Manager secrets:
  - `zenml-mlflow-db-user`
  - `zenml-mlflow-db-password`
  - `zenml-mlflow-db-connection`

### Prerequisites
- External Secrets Operator (deployed in sync wave 0)
- Cert Manager (deployed in sync wave 2)

## Secrets

The ExternalSecret creates a Kubernetes secret `mlflow-database-secret` with the following keys:
- `username` - Database username
- `password` - Database password
- `host` - Database host
- `port` - Database port
- `database` - Database name
- `driver` - Database driver (pymysql)
- `connection-url` - Complete database connection URL

## Service Account

The MLflow service account has Workload Identity configured to use the GCP service account `zenml-mlflow@zenml-470505.iam.gserviceaccount.com` which provides:
- Cloud SQL Client access
- Storage Object Admin (for MLflow artifacts bucket)
- Secret Manager access (limited to MLflow secrets)

## Next Steps

After this infrastructure is deployed, the next step is to deploy the MLflow Helm chart which will:
1. Use the `mlflow-database-secret` for database connectivity
2. Use the service account for GCP authentication
3. Store artifacts in the `zenml-mlflow-artifacts` GCS bucket
