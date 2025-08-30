# ZenML Deployment Information

## 📋 **Google Cloud Secret Manager Configuration**

Your infrastructure provides all the required information for ZenML's Google Cloud Secret Manager integration:

### ✅ **1. Google Cloud Project ID**
```
Project ID: zenml-470505
```

### ✅ **2. Service Account for Secret Manager Access**

I've created a dedicated ZenML service account with the following details:

**Service Account Details:**
- **Account ID**: `zenml-zenml` (format: `{project_name}-zenml`)
- **Display Name**: "ZenML Service Account"
- **Email**: `zenml-zenml@zenml-470505.iam.gserviceaccount.com`

**Permissions Granted:**
- 🔐 **`roles/secretmanager.secretAccessor`** - Access to Secret Manager secrets
- 🗄️ **`roles/cloudsql.client`** - Connect to Cloud SQL databases
- 📦 **`roles/storage.admin`** - Full access to Cloud Storage (for artifacts)
- 🔗 **Workload Identity** - Bind to Kubernetes service account `zenml/zenml-server`

## 🗄️ **Database Secrets Created**

Your MySQL module automatically creates these secrets in Secret Manager:

| Secret Name | Description | Usage |
|-------------|-------------|-------|
| `zenml-mysql-root-password` | MySQL root password | Database administration |
| `zenml-zenml-db-password` | ZenML database user password | ZenML application access |
| `zenml-zenml-db-connection` | Complete connection info | ZenML database configuration |

## 🚀 **ZenML Configuration**

Use this information when deploying ZenML:

### **Secret Manager Configuration**
```yaml
# ZenML Secret Manager configuration
secrets_store:
  type: gcp
  config:
    project_id: "zenml-470505"
    # Either use service account email or Workload Identity
    service_account_email: "zenml-zenml@zenml-470505.iam.gserviceaccount.com"
```

### **Database Configuration**
```yaml
# ZenML Database configuration
database:
  type: mysql
  config:
    # Get these from terraform outputs
    host: "<mysql_private_ip>"  # From: terraform output mysql_instance_private_ip
    port: 3306
    database: "zenml"
    username: "zenml"
    # Password stored in Secret Manager: zenml-zenml-db-password
    password_secret: "zenml-zenml-db-password"
```

### **Helm Chart Values Example**
```yaml
# values.yaml for ZenML Helm chart
zenml:
  # Database configuration
  database:
    host: "<mysql_private_ip>"
    port: "3306"
    database: "zenml"
    username: "zenml"
    sslMode: "PREFERRED"
    
  # Use External Secrets to inject database password
  existingSecret:
    name: "zenml-db-secret"
    passwordKey: "password"

# Service Account for Workload Identity
serviceAccount:
  create: false  # Use existing service account
  name: "zenml-server"
  annotations:
    iam.gke.io/gcp-service-account: "zenml-zenml@zenml-470505.iam.gserviceaccount.com"

# External Secrets Operator configuration
externalSecrets:
  enabled: true
  secretStore:
    name: "gcp-secret-store"
    kind: "SecretStore"
  secrets:
    - name: "zenml-db-secret"
      secretKey: "password"
      remoteRef:
        key: "zenml-zenml-db-password"
```

## 🔧 **Getting the Required Information**

### **Terraform Outputs**
Run these commands to get the specific values:

```bash
# Get project information
terraform output project_id

# Get service account details
terraform output -json security | jq '.zenml_service_account_email'

# Get database connection details
terraform output -json mysql | jq '.zenml_database_connection_info'

# Get all secret names
terraform output -json mysql | jq '.zenml_database_password_secret_id'
```

### **Google Cloud Commands**
```bash
# Verify service account exists
gcloud iam service-accounts describe zenml-zenml@zenml-470505.iam.gserviceaccount.com

# List Secret Manager secrets
gcloud secrets list --filter="name~zenml"

# Get database password (for testing)
gcloud secrets versions access latest --secret="zenml-zenml-db-password"
```

## 🎯 **External Secrets Operator Setup**

To automatically inject secrets into Kubernetes, set up External Secrets Operator:

```yaml
# secretstore.yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: gcp-secret-store
  namespace: zenml
spec:
  provider:
    gcpsm:
      projectId: "zenml-470505"
      auth:
        workloadIdentity:
          clusterLocation: "australia-southeast1"
          clusterName: "zenml"
          serviceAccountRef:
            name: "zenml-server"

---
# external-secret.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: zenml-db-secret
  namespace: zenml
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: gcp-secret-store
    kind: SecretStore
  target:
    name: zenml-db-secret
    creationPolicy: Owner
  data:
  - secretKey: password
    remoteRef:
      key: "zenml-zenml-db-password"
```

## ✅ **Summary**

**You have ALL the required information for ZenML deployment:**

1. ✅ **Project ID**: `zenml-470505`
2. ✅ **Service Account**: `zenml-zenml@zenml-470505.iam.gserviceaccount.com`
3. ✅ **Secret Manager Access**: Configured with proper IAM roles
4. ✅ **Database Secrets**: Automatically created and stored
5. ✅ **Workload Identity**: Ready for Kubernetes integration

Your infrastructure is **fully prepared** for ZenML deployment! 🚀
