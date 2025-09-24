# Prerequisites

Before starting the deployment, ensure you have the following tools and configurations in place.

## 🛠️ Required Tools

### Google Cloud SDK
The `gcloud` CLI is essential for managing Google Cloud resources.

```bash
# Install Google Cloud SDK (if not already installed)
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Verify installation
gcloud version
```

### Terraform
Infrastructure as Code tool for provisioning Google Cloud resources.

```bash
# Install Terraform (macOS with Homebrew)
brew install terraform

# Install Terraform (Linux)
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verify installation
terraform version
```

### kubectl
Kubernetes command-line tool for cluster management.

```bash
# Install kubectl
gcloud components install kubectl

# Or with Homebrew (macOS)
brew install kubectl

# Verify installation
kubectl version --client
```

### Helm
Package manager for Kubernetes applications.

```bash
# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Or with Homebrew (macOS)
brew install helm

# Verify installation
helm version
```

## ☁️ Google Cloud Setup

### 1. Create or Select a Project

```bash
# Create a new project (optional)
gcloud projects create YOUR-PROJECT-ID --name="ZenML MLOps Stack"

# Set the project
gcloud config set project YOUR-PROJECT-ID

# Verify project selection
gcloud config get-value project
```

### 2. Enable Billing

Ensure billing is enabled on your project:

1. Go to the [Google Cloud Console](https://console.cloud.google.com)
2. Navigate to **Billing** → **Link a billing account**
3. Select or create a billing account

### 3. Enable Required APIs

The following APIs will be automatically enabled by Terraform, but you can enable them manually if needed:

```bash
# Enable required APIs
gcloud services enable \
  container.googleapis.com \
  compute.googleapis.com \
  cloudsql.googleapis.com \
  secretmanager.googleapis.com \
  cloudkms.googleapis.com \
  servicenetworking.googleapis.com \
  dns.googleapis.com \
  storage.googleapis.com \
  artifactregistry.googleapis.com
```

## 🔐 Authentication

### Application Default Credentials

```bash
# Authenticate with Google Cloud
gcloud auth login

# Set up Application Default Credentials (ADC)
gcloud auth application-default login

# Verify authentication
gcloud auth list
```

## 📁 Project Setup

### 1. Clone the Repository

```bash
git clone https://github.com/Philippe-Neveux/zenml-mlops-stack.git
cd zenml-mlops-stack
```

### 2. Create Terraform Backend Storage

For production deployments, use remote state storage:

```bash
# Create a bucket for Terraform state (replace YOUR_PROJECT_ID)
gsutil mb gs://tf-backends-YOUR_PROJECT_ID

# Enable versioning for state backup
gsutil versioning set on gs://tf-backends-YOUR_PROJECT_ID
```

### 3. Configure Variables

Copy and customize the Terraform variables:

```bash
# Copy example variables
cp src/infra/terraform.tfvars.example src/infra/terraform.tfvars

# Edit with your values
nano src/infra/terraform.tfvars
```

Required variables:
```hcl
# Project Configuration
project_id   = "your-project-id"
project_name = "zenml-mlops"
region       = "us-central1"
zone         = "us-central1-a"

# Optional: Custom domain
# domain_name = "yourdomain.com"
```

## 🧪 Verify Setup

Test your setup before proceeding:

```bash
# Verify Terraform
terraform version

# Verify Google Cloud access
gcloud projects describe $(gcloud config get-value project)

# Verify kubectl
kubectl version --client

# Verify Helm
helm version
```

## 💡 Recommended IAM Permissions

Your Google Cloud user or service account needs these roles:

- **Kubernetes Engine Admin** - Manage GKE clusters
- **Compute Network Admin** - Manage VPC and networking
- **Cloud SQL Admin** - Manage database instances
- **Security Admin** - Manage IAM and security
- **Service Account Admin** - Manage service accounts
- **Secret Manager Admin** - Manage secrets
- **Storage Admin** - Manage Cloud Storage
- **DNS Administrator** - Manage DNS (if using custom domains)

## ⚠️ Important Notes

!!! warning "Project Permissions"
    Ensure you have `Owner` or `Editor` permissions on the Google Cloud project, as the deployment creates various resources and IAM bindings.

!!! info "Billing"
    This deployment will create billable resources. See the cost estimation in the [reference section](../reference/index.md) for details.

!!! tip "Region Selection"
    Choose a region close to your users for better performance. Popular choices are:
    - `us-central1` (Iowa)
    - `us-east1` (South Carolina)
    - `europe-west1` (Belgium)
    - `asia-southeast1` (Singapore)

## 🎉 Next Steps

Once you have all prerequisites installed and configured:

- [Quick Start](quick-start.md) - For complete deployment setup

---

!!! question "Need Help?"
    If you encounter issues with the prerequisites, check our [troubleshooting guide](../troubleshooting/index.md) or open an issue on GitHub.