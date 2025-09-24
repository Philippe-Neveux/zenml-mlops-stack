# Quick Start

Get your ZenML MLOps stack running in just 15 minutes! This guide uses default configurations and nip.io domains for easy testing.

## 🚀 Deploy Infrastructure

### Step 1: Prepare Your Environment

```bash
# Clone the repository
git clone https://github.com/Philippe-Neveux/zenml-mlops-stack.git
cd zenml-mlops-stack

# Set your project ID
export PROJECT_ID="your-project-id"
gcloud config set project $PROJECT_ID
```

### Step 2: Configure Terraform Backend

```bash
# Create GCS bucket for Terraform state
gsutil mb gs://tf-backends-$PROJECT_ID
gsutil versioning set on gs://tf-backends-$PROJECT_ID

# Update backend configuration
sed -i "s/YOUR_PROJECT_ID/$PROJECT_ID/g" src/infra/main.tf
```

### Step 3: Configure Variables

```bash
# Create terraform.tfvars with minimal config
cat > src/infra/terraform.tfvars << EOF
project_id   = "$PROJECT_ID"
project_name = "zenml-mlops"
region       = "us-central1"
zone         = "us-central1-a"
EOF
```

### Step 4: Deploy Infrastructure

```bash
cd src/infra

# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply infrastructure (takes ~10 minutes)
terraform apply -auto-approve
```

## 🔧 Configure Kubernetes

### Step 1: Connect to GKE Cluster

```bash
# Get cluster credentials
gcloud container clusters get-credentials zenml-mlops-us-central1 \
  --region us-central1 --project $PROJECT_ID

# Verify connection
kubectl get nodes
```

### Step 2: Install ArgoCD

```bash
# Create ArgoCD namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Expose ArgoCD with LoadBalancer
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```

### Step 3: Get Access Information

```bash
# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d; echo

# Get ArgoCD external IP (wait for it to be assigned)
kubectl get svc argocd-server -n argocd

# Get NGINX ingress IP for applications
kubectl get svc -n nginx-ingress nginx-ingress-controller 2>/dev/null || echo "Will be available after app deployment"
```

## 📱 Deploy Applications

### Step 1: Update Configuration Files

```bash
# Get the static IP from Terraform
export NGINX_IP=$(cd src/infra && terraform output -raw nginx_ingress_ip)

# Update external secrets with your project ID
sed -i "s/<put-your-porject-id-here>/$PROJECT_ID/g" \
  src/k8s-cluster/external-secrets/secret-store.yaml

# Update ZenML values with IP and project
sed -i "s/<nginx-publc-ip-adress>/$NGINX_IP/g" src/zenml/custom-values.yaml
sed -i "s/<your-project-id>/$PROJECT_ID/g" src/zenml/custom-values.yaml

# Get MySQL private IP
export MYSQL_IP=$(cd src/infra && terraform output -raw mysql_instance_private_ip)
sed -i "s/<mysql-private-ip-adress>/$MYSQL_IP/g" src/zenml/custom-values.yaml

# Update MLflow configuration
sed -i "s/<your-project-id>/$PROJECT_ID/g" src/mlflow/values.yaml
sed -i "s/X.X.X.X/$MYSQL_IP/g" src/mlflow/values.yaml
```

### Step 2: Deploy All Applications

```bash
# Deploy all ArgoCD applications
kubectl apply -f src/argocd-apps/

# Wait for applications to sync
kubectl get applications -n argocd -w
```

## 🌐 Access Your Services

### Get Service URLs

```bash
echo "=== ZenML & MLflow Access URLs ==="
echo "ZenML Server: https://zenml-server.$NGINX_IP.nip.io"
echo "MLflow Server: https://mlflow.$NGINX_IP.nip.io"
echo ""
echo "=== ArgoCD Access ==="
echo "ArgoCD UI: http://$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
echo "Username: admin"
echo "Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
```

### Verify Deployments

```bash
# Check all pods are running
kubectl get pods --all-namespaces

# Check ingress status
kubectl get ingress --all-namespaces

# Check certificates (should be Ready)
kubectl get certificates --all-namespaces
```

## 🎯 Test Your Setup

### ZenML Connection Test

```bash
# Test ZenML server connectivity
curl -k https://zenml-server.$NGINX_IP.nip.io/health

# Expected response: {"status": "OK"}
```

### MLflow Connection Test

```bash
# Test MLflow server connectivity
curl -k https://mlflow.$NGINX_IP.nip.io

# Should return MLflow UI HTML
```

## 📊 What's Next?

Your ZenML MLOps stack is now ready! Here's what you can do:

### 1. Set Up ZenML Client

```bash
# Install ZenML
pip install zenml[server]

# Connect to your ZenML server
zenml connect --url https://zenml-server.$NGINX_IP.nip.io

# Create a default user
zenml user create default --password password123
```

### 2. Configure MLflow Integration

```bash
# Register MLflow experiment tracker
zenml experiment-tracker register mlflow_tracker \
  --flavor=mlflow \
  --tracking_uri=https://mlflow.$NGINX_IP.nip.io
```

### 3. Set Up CI/CD

For GitHub Actions integration:

1. Add repository secrets:
   - `ZENML_STORE_URL`: `https://zenml-server.$NGINX_IP.nip.io`
   - `ZENML_API_KEY`: (create service account key with ZenML CLI)

```bash
# Create service account for CI/CD
zenml service-account create github_action_api_key
# Copy the displayed API key to GitHub secrets
```

## 🔍 Monitoring

Monitor your deployment:

```bash
# Check ArgoCD application status
kubectl get applications -n argocd

# Monitor pods
kubectl get pods --all-namespaces

# Check ingress and certificates
kubectl get ingress,certificates --all-namespaces
```

## 🧹 Cleanup (Optional)

To remove everything:

```bash
# Delete Kubernetes resources
kubectl delete -f src/argocd-apps/
kubectl delete namespace argocd

# Destroy Terraform infrastructure
cd src/infra
terraform destroy -auto-approve

# Delete GCS bucket
gsutil rm -r gs://tf-backends-$PROJECT_ID
```

---

!!! success "Congratulations!"
    Your ZenML MLOps stack is now running! You can access ZenML and MLflow through their respective URLs.

!!! tip "Production Setup"
    For production deployment with custom domains and enhanced security, see the [Complete Deployment Guide](deployment.md).

!!! question "Issues?"
    If you encounter problems, check the [troubleshooting guide](../troubleshooting/common-issues.md).