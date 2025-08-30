# Kubernetes Infrastructure with Terraform

This Terraform configuration sets up a production-ready Kubernetes infrastructure on Google Cloud Platform (GCP) that supports ZenML and MLOps workloads.

## Architecture Overview

The infrastructure includes:

- **VPC with Custom Subnets**: Regional VPC with secondary IP ranges for pods and services
- **GKE Cluster**: Managed Kubernetes cluster with multiple node pools and private nodes
- **Security**: Firewall rules, IAM service accounts, and Workload Identity
- **Encryption**: Cloud KMS encryption for secrets and Application-layer Secrets Encryption (envelope encryption)
- **Networking**: Cloud NAT for outbound internet access from private nodes

## Prerequisites

1. **Google Cloud SDK (gcloud)** installed and authenticated
2. **Terraform >= 1.0** installed
3. **kubectl** installed for cluster management
4. **Helm** installed for package management
5. **A Google Cloud Project** with billing enabled

## Required GCP APIs and Permissions

Enable the following APIs in your GCP project:
```bash
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable cloudkms.googleapis.com
gcloud services enable clouddns.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable binaryauthorization.googleapis.com
```

Your GCP user/service account needs the following roles:
- Kubernetes Engine Admin
- Compute Network Admin
- Security Admin
- Service Account Admin
- Cloud KMS Admin
- Secret Manager Admin
- DNS Administrator

## Quick Start

1. **Clone and navigate to the infrastructure directory**:
   ```bash
   cd src/infra
   ```

2. **Set up Google Cloud authentication**:
   ```bash
   gcloud auth login
   gcloud config set project YOUR_PROJECT_ID
   gcloud auth application-default login
   ```

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Review and customize variables**:
   ```bash
   cp terraform.tfvars terraform.tfvars.local
   # Edit terraform.tfvars.local with your specific values
   # IMPORTANT: Update project_id with your actual GCP project ID
   ```

5. **Plan the deployment**:
   ```bash
   terraform plan -var-file="terraform.tfvars.local"
   ```

6. **Apply the configuration**:
   ```bash
   terraform apply -var-file="terraform.tfvars.local"
   ```

7. **Configure kubectl**:
   ```bash
   gcloud container clusters get-credentials zenml-mlops-dev --region us-central1 --project YOUR_PROJECT_ID
   ```

## Configuration

### Environment Variables

Key variables you should customize in `terraform.tfvars`:

```hcl
# Project Configuration
project_name = "your-project-name"
environment  = "dev|staging|prod"
project_id   = "your-gcp-project-id"
region       = "us-central1"

# Networking
vpc_cidr = "10.0.0.0/16"
subnet_cidrs = {
  primary   = "10.0.1.0/24"
  secondary = "10.0.2.0/24"
  pods      = "10.1.0.0/16"
  services  = "10.2.0.0/16"
}

# Master authorized networks (restrict this in production)
master_authorized_networks = [
  {
    cidr_block   = "YOUR.IP.ADDRESS/32"
    display_name = "Your office IP"
  }
]

# Node Pools
node_pools = {
  general = {
    node_count   = 2
    machine_type = "e2-medium"
    disk_size_gb = 50
  }
}
```

### Remote State (Recommended)

For production environments, configure remote state storage:

1. Create a GCS bucket for state storage:
   ```bash
   gsutil mb gs://your-terraform-state-bucket
   gsutil versioning set on gs://your-terraform-state-bucket
   ```

2. Uncomment and configure the backend in `main.tf`:
   ```hcl
   backend "gcs" {
     bucket = "your-terraform-state-bucket"
     prefix = "kubernetes/terraform.tfstate"
   }
   ```

## Post-Deployment Setup

### 1. Configure kubectl Access

```bash
# Configure kubectl to access your cluster
gcloud container clusters get-credentials $(terraform output -raw cluster_name) \
  --region $(terraform output -raw region) \
  --project $(terraform output -raw project_id)

# Verify cluster access
kubectl cluster-info
kubectl get nodes
```

### 2. Verify ZenML Prerequisites

```bash
# Check Secret Manager access
gcloud secrets list --filter="name~zenml" --project=$(terraform output -raw project_id)

# Test database connectivity
kubectl run mysql-test --image=mysql:8.0 --rm -it --restart=Never -- \
  mysql -h $(terraform output -raw mysql_instance_private_ip) \
  -u $(terraform output -raw zenml_database_username) \
  -p$(gcloud secrets versions access latest --secret="$(terraform output -raw zenml_database_password_secret_id)") \
  $(terraform output -raw zenml_database_name)
```

### 3. Install Google Cloud Load Balancer Controller (GKE Ingress)

GKE comes with built-in ingress controller, but you can also install additional controllers:

```bash
# Install NGINX Ingress Controller (alternative to GKE Ingress)
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.service.annotations."cloud\.google\.com/load-balancer-type"="External"
```

### 4. Set up ZenML Workload Identity

```bash
# Create ZenML namespace
kubectl create namespace zenml

# Create Kubernetes service account for ZenML
kubectl create serviceaccount zenml-server -n zenml

# Annotate the Kubernetes service account with the Google service account
kubectl annotate serviceaccount zenml-server \
  -n zenml \
  iam.gke.io/gcp-service-account=$(terraform output -raw zenml_service_account_email)

# Verify the setup
kubectl describe serviceaccount zenml-server -n zenml
```

## Security Considerations

1. **Network Security**:
   - Private GKE nodes with no external IP addresses
   - Cloud NAT for outbound internet access
   - Firewall rules with minimal required ports
   - Network policies enabled via Calico

2. **Access Control**:
   - GKE cluster endpoint access restricted by authorized networks
   - IAM service accounts with least-privilege principles
   - Workload Identity for secure pod-to-GCP service communication
   - ZenML service account with Secret Manager and Cloud SQL access

3. **Encryption**:
   - Application-layer Secrets Encryption with Cloud KMS
   - Persistent disk encryption enabled by default
   - Secrets stored in Google Secret Manager

## Cost Optimization

1. **Spot/Preemptible Instances**: Enable spot node pools for non-critical workloads
2. **Auto Scaling**: Configure Horizontal Pod Autoscaler and Cluster Autoscaler
3. **Resource Requests**: Set appropriate resource requests and limits
4. **Machine Types**: Use appropriate machine types for your workload (e2-medium for general use)
5. **Regional vs Zonal**: Use zonal clusters for development, regional for production

## Troubleshooting

### Common Issues

1. **Insufficient GCP Permissions**:
   - Ensure your account has all required IAM roles
   - Check Cloud Audit Logs for detailed error messages
   - Verify all required APIs are enabled

2. **Node Pools Not Starting**:
   - Check firewall rules allow required communication
   - Verify subnet configuration and IP ranges
   - Ensure service account has correct permissions

3. **Ingress/Load Balancer Issues**:
   - Check firewall rules for load balancer health checks
   - Ensure services have correct annotations

4. **Workload Identity Issues**:
   - Verify service account binding is correct
   - Check pod annotations for Workload Identity
   - Ensure Google service account has required permissions

### Useful Commands

```bash
# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# Check GKE cluster details
gcloud container clusters describe zenml-mlops-dev --region us-central1

# View Terraform outputs
terraform output

# Get cluster credentials
gcloud container clusters get-credentials zenml-mlops-dev --region us-central1

# Check node pool status
gcloud container node-pools list --cluster zenml-mlops-dev --region us-central1

# Destroy infrastructure (use with caution)
terraform destroy -var-file="terraform.tfvars.local"
```

## Module Structure

```
modules/
├── vpc/          # VPC, subnets, firewall rules, Cloud NAT
├── gke/          # GKE cluster, node pools, service accounts
└── security/     # IAM, Secret Manager, DNS
```

## Outputs

The Terraform configuration provides several outputs:

- **cluster_endpoint**: GKE cluster API endpoint
- **cluster_name**: GKE cluster name
- **configure_kubectl**: Command to configure kubectl
- **network_name**: VPC network name
- **node_pools**: Node pool information
- **ingress_ip_address**: Global IP for ingress
- **service_account_emails**: Service account emails for Workload Identity

## Next Steps

1. **Set up ArgoCD applications** for your MLOps pipelines
2. **Set up ingress** controllers for external access
3. **Implement GitOps** workflows with ArgoCD
4. **Configure backup strategies** for persistent volumes
5. **Set up CI/CD pipelines** using Google Cloud Build or GitHub Actions

## Support

For issues related to:
- **Terraform**: Check the official Terraform Google provider documentation
- **GKE**: Refer to Google Kubernetes Engine documentation
- **ArgoCD**: Check ArgoCD documentation and community
- **Google Cloud**: Use Google Cloud Support or Stack Overflow

## Contributing

1. Follow Terraform best practices
2. Update documentation for any changes
3. Test in development environment first
4. Use meaningful commit messages
5. Follow Google Cloud naming conventions
