# ZenML MLOps Stack on Google Cloud

A complete production-ready MLOps infrastructure deployment using Terraform, ArgoCD, and Kubernetes on Google Cloud Platform. This repository provides automated infrastructure provisioning and GitOps-based application deployment for a comprehensive ZenML stack.

## 🏗️ Architecture Overview

This stack deploys a complete MLOps environment with the following components:

### Infrastructure Components
- **GKE Autopilot Cluster**: Managed Kubernetes with automatic scaling and security
- **VPC Networking**: Custom network with proper subnet configuration for security
- **Cloud SQL MySQL**: Managed database for ZenML metadata storage with private networking
- **Google Cloud Storage**: Artifact storage for ML models and datasets
- **Artifact Registry**: Container image registry for custom Docker images
- **Security**: IAM roles, service accounts, KMS encryption, and network security rules

### Application Stack (GitOps with ArgoCD)
- **ArgoCD**: GitOps continuous deployment for Kubernetes applications
- **NGINX Ingress Controller**: Production-ready ingress with LoadBalancer and HTTPS
- **cert-manager**: Automatic Let's Encrypt TLS certificate management
- **External Secrets Operator**: Secure secret management from Google Secret Manager
- **ZenML Server**: ML pipeline orchestration and model registry
- **MLflow Server**: ML experiment tracking and model serving

### Security & Networking
- **Automatic HTTPS**: Let's Encrypt certificates via cert-manager
- **Private GKE nodes**: Nodes without public IPs for enhanced security
- **Private database**: Cloud SQL accessible only from VPC
- **Secret management**: Integration with Google Secret Manager
- **Network security**: Firewall rules and IAM policies

## 📋 Prerequisites

Before starting the deployment, ensure you have the following:

### Required Tools
- **Google Cloud SDK**: `gcloud` CLI configured and authenticated
- **Terraform**: >= 1.0 for infrastructure provisioning
- **kubectl**: Kubernetes CLI for cluster management
- **Helm**: Package manager for Kubernetes (>= 3.0)
- **Git**: For cloning the repository and GitOps workflows

### Google Cloud Setup
1. **Google Cloud Project**: Create a new project or use existing one
2. **Billing Account**: Ensure billing is enabled on the project
3. **APIs**: The following APIs will be automatically enabled by Terraform:
   - Compute Engine API
   - Kubernetes Engine API
   - Cloud SQL Admin API
   - Secret Manager API
   - Cloud KMS API
   - Service Networking API
   - Cloud DNS API
   - Cloud Storage API
   - Artifact Registry API

### Authentication
```bash
# Authenticate with Google Cloud
gcloud auth login
gcloud auth application-default login

# Set your project
gcloud config set project YOUR_PROJECT_ID
```

## 🚀 Complete Deployment Guide

## 🚀 Complete Deployment Guide

### Step 1: Prepare Your Environment

1. **Clone the Repository**
   ```bash
   git clone https://github.com/Philippe-Neveux/zenml-mlops-stack.git
   cd zenml-mlops-stack
   ```

2. **Create GCS Bucket for Terraform State** (Replace `YOUR_PROJECT_ID`)
   ```bash
   # Create a bucket for Terraform state storage
   gsutil mb gs://tf-backends-YOUR_PROJECT_ID
   
   # Enable versioning for state backup
   gsutil versioning set on gs://tf-backends-YOUR_PROJECT_ID
   ```

3. **Configure Terraform Variables**
   
   Edit `src/infra/variables.tf` or create `src/infra/terraform.tfvars`:
   ```hcl
   # Required variables
   project_id   = "your-new-project-id"
   project_name = "zenml-mlops"
   region       = "us-central1"
   zone         = "us-central1-a"
   
   # Optional: For custom domain support
   # domain_name = "yourdomain.com"
   ```

4. **Update Terraform Backend Configuration**
   
   Edit `src/infra/main.tf` to update the backend bucket:
   ```hcl
   backend "gcs" {
     bucket = "tf-backends-YOUR_PROJECT_ID"  # Update this line
     prefix = "zenml-infra/terraform.tfstate"
   }
   ```

### Step 2: Deploy Infrastructure with Terraform

1. **Initialize and Deploy Infrastructure**
   ```bash
   # Plan your terraform deployment
   make tf-plan
   
   # Apply cloud infrastructure plan
   make tf-apply
   ```

   This will deploy:
   - VPC with public/private subnets
   - GKE Autopilot cluster
   - Cloud SQL MySQL instance
   - IAM service accounts and roles
   - Google Cloud Storage buckets
   - Artifact Registry
   - Security configurations

2. **Get Infrastructure Outputs**
   ```bash
   # Display all outputs
   cd src/infra
   terraform output
   
   # Get specific outputs
   terraform output cluster_name
   terraform output mysql_connection_name
   ```

3. **Connect to the GKE Cluster**
   ```bash
   # Get cluster credentials
   gcloud container clusters get-credentials $(terraform output -raw cluster_name) \
     --region $(terraform output -raw region) \
     --project $(terraform output -raw project_id)
   
   # Verify connection
   kubectl get nodes
   ```

### Step 3: Install ArgoCD

1. **Install ArgoCD in the Cluster**
   ```bash
    # Create ArgoCD namespace
    kubectl create namespace argocd
   
    # Install ArgoCD
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   
    # Wait for ArgoCD to be ready
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

    # Use the LoadBalancer of GCP
    kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
   ```

2. **Access ArgoCD UI**
   ```bash
   # Get the ip adress and the user/password to connect
    make argocd-access-info
   ```

### Step 4: Update Kubernetes manifest files

1. **Update project id in external secrets**
   ```yaml
    # src/k8s-cluster/external-secrets/secret-store.yaml
    apiVersion: external-secrets.io/v1
    kind: SecretStore
    metadata:
    name: gcp-secret-store
    namespace: zenml
    spec:
    provider:
        gcpsm:
        projectID: <put-your-porject-id-here> 
   ```

2. **Update cutom values for Zenml deployment**
   ```yaml
    # src/zenml/custom-values.yaml
    zenml:
        serverURL: https://zenml-server.<nginx-publc-ip-adress>.nip.io
        dashboardURL: https://zenml-server.<nginx-publc-ip-adress>.nip.io
        database:
            url: mysql://zenml@<mysql-private-ip-adress>:3306/zenml

    serviceAccount:
        annotations:
            iam.gke.io/gcp-service-account: zenml-zenml@<your-project-id>.iam.gserviceaccount.com
   ```

   You can retreive your nginx public ip adress by executing:
   ```bash
   kubectl get ingress -A
   ```

2. **Mlflow cutom values for Mlflow deployment**
   ```yaml
   # src/mlflow/values.yaml
   mysql:
      enabled: true
      host: "X.X.X.X" # Put your mysql private ip adress here, to get it: gcloud sql instances list
      port: 3306
      database: "mlflow"
   
   artifactRoot:
      gcs:
         enabled: true
         bucket: "<your-project-id>-mlflow-artifacts"
         path: ""  # Use root level of bucket
   ```

3. **Mlflow kubernetes manifest**
   ```yaml
   # src/k8s-cluster/mlflow/manifest.yaml
   apiVersion: v1
   kind: ServiceAccount
   metadata:
   name: mlflow
   namespace: mlflow
   annotations:
      iam.gke.io/gcp-service-account: zenml-mlflow@<your-project-id>.iam.gserviceaccount.com
   
   ---
   apiVersion: external-secrets.io/v1
   kind: SecretStore
   metadata:
   name: mlflow-secret-store
   namespace: mlflow
   labels:
      app.kubernetes.io/name: mlflow
      app.kubernetes.io/component: external-secrets
      app.kubernetes.io/part-of: zenml-mlops-stack
   spec:
   provider:
      gcpsm:
         projectID: <your-project-id>
   ```

### Step 4: Deploy Application Stack with ArgoCD

The ArgoCD applications are configured with sync waves to ensure proper deployment order:

1. **Wave 0**: External Secrets Operator
2. **Wave 1**: Secret Store configuration
3. **Wave 2**: cert-manager
4. **Wave 3**: NGINX Ingress, Cluster Issuers, External Secrets
5. **Wave 4**: ZenML RBAC, ZenML Server
6. **Wave 5**: MLflow Infrastructure and Server

**Deploy All Applications:**

```bash
# Apply all ArgoCD applications
make argocd-apps-deploy-all
```

### Step 5: Verify Deployment

1. **Check ArgoCD Applications Status**
   ```bash
   # View all applications
   kubectl get applications -n argocd
   
   # Check specific application
   kubectl describe application zenml-server -n argocd
   ```

2. **Verify Infrastructure Components**
   ```bash
   # Check all pods across namespaces
   kubectl get pods --all-namespaces
   
   # Check ingress status
   kubectl get ingress --all-namespaces
   
   # Check certificates
   kubectl get certificates --all-namespaces
   ```

3. **Get Access Information**
   ```bash
   # Get LoadBalancer IP
   kubectl get svc -n nginx-ingress nginx-ingress-nginx-ingress-controller
   
   # Check ZenML server status
   kubectl get pods -n zenml
   kubectl logs -n zenml deployment/zenml-server
   ```

### Step 6: Configure Access and DNS

1. **Using nip.io (Quick Testing)**
   ```bash
   # Get the external IP
   EXTERNAL_IP=$(kubectl get svc -n nginx-ingress nginx-ingress-nginx-ingress-controller \
     -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
   
   echo "ZenML URL: https://zenml-server.$EXTERNAL_IP.nip.io"
   echo "MLflow URL: https://mlflow.$EXTERNAL_IP.nip.io"
   ```

### Step 7: Access Your MLOps Stack

1. **ZenML Server**
   ```bash
   # Access ZenML server
   curl https://zenml-server.$EXTERNAL_IP.nip.io
   ```

2. **MLflow Server**
   ```bash
   # Access MLflow server
   curl https://mlflow.$EXTERNAL_IP.nip.io
   ```

### Step 8: CI/CD secrets
1. **Create Zenml URL Github Action secret**
   Create a new Github secrets with the name: ZENML_STORE_URL with the value `https://zenml-server.$EXTERNAL_IP.nip.io`

2. **Create Zenml service account**
   ```bash
   zenml service-account create github_action_api_key
   ```

## 🔧 Configuration Details

## 🔧 Configuration Details

### Terraform Modules

The infrastructure is organized into modular Terraform components:

- **`modules/vpc`**: Virtual Private Cloud with public/private subnets
- **`modules/gke`**: Google Kubernetes Engine Autopilot cluster
- **`modules/mysql`**: Cloud SQL MySQL instance with private networking
- **`modules/security`**: IAM roles, service accounts, and KMS keys
- **`modules/storage`**: Google Cloud Storage buckets for artifacts
- **`modules/artifact-registry`**: Container registry for Docker images

### ArgoCD Applications

Applications are deployed in synchronized waves for dependency management:

| Application | Wave | Description |
|-------------|------|-------------|
| external-secrets-operator | 0 | Manages secrets from Google Secret Manager |
| zenml-secret-store | 1 | Secret store configuration |
| cert-manager | 2 | TLS certificate management |
| nginx-ingress | 3 | Ingress controller and load balancer |
| cluster-issuers | 3 | Let's Encrypt certificate issuers |
| zenml-external-secrets | 3 | ZenML-specific secrets |
| zenml-rbac | 4 | RBAC configuration for ZenML |
| zenml-server | 4 | ZenML server deployment |
| mlflow-infrastructure | 5 | MLflow infrastructure components |
| mlflow-server | 5 | MLflow tracking server |

### Security Configuration

- **Private GKE Nodes**: Cluster nodes have no public IP addresses
- **Private Database**: Cloud SQL accessible only from VPC networks
- **Service Accounts**: Dedicated GCP service accounts with minimal permissions
- **Workload Identity**: Secure binding between Kubernetes and GCP service accounts
- **Secret Management**: Integration with Google Secret Manager via External Secrets Operator
- **Network Security**: Firewall rules restricting access to necessary ports only

## 🔍 Monitoring and Troubleshooting

### Monitoring Commands

```bash
# Check ArgoCD application status
kubectl get applications -n argocd

# Monitor pod status across all namespaces
kubectl get pods --all-namespaces

# Check ingress and certificates
kubectl get ingress,certificates --all-namespaces

# View ArgoCD application details
kubectl describe application zenml-server -n argocd

# Check service endpoints
kubectl get endpoints --all-namespaces
```

### Common Troubleshooting

1. **Certificate Issues**
   ```bash
   # Check certificate status
   kubectl describe certificate -n zenml
   
   # Check cert-manager logs
   kubectl logs -n cert-manager deployment/cert-manager
   
   # Check cluster issuer status
   kubectl describe clusterissuer letsencrypt-prod
   ```

2. **Ingress Issues**
   ```bash
   # Check NGINX ingress controller
   kubectl logs -n nginx-ingress deployment/nginx-ingress-nginx-ingress-controller
   
   # Check ingress resources
   kubectl describe ingress -n zenml
   
   # Check LoadBalancer service
   kubectl describe svc -n nginx-ingress nginx-ingress-nginx-ingress-controller
   ```

3. **Database Connectivity**
   ```bash
   # Test MySQL connectivity from a pod
   kubectl run mysql-test --image=mysql:8.0 --rm -it --restart=Never -- \
     mysql -h <MYSQL_IP> -u zenml -p
   
   # Check CloudSQL Proxy (if used)
   kubectl logs -n zenml deployment/cloudsql-proxy
   ```

4. **Secret Management**
   ```bash
   # Check external secrets status
   kubectl get externalsecrets --all-namespaces
   
   # Check secret store connection
   kubectl describe secretstore -n external-secrets-system
   
   # Check external secrets operator logs
   kubectl logs -n external-secrets-system deployment/external-secrets
   ```

## 🧰 Management Operations

### Updating Applications

Applications are managed through GitOps. To update:

1. **Update application manifests** in `src/argocd-apps/`
2. **Commit changes** to the Git repository
3. **ArgoCD will automatically sync** the changes (if auto-sync is enabled)

Manual sync:
```bash
# Sync specific application
argocd app sync zenml-server

# Sync all applications
argocd app sync --all
```

### Scaling Operations

```bash
# Scale ZenML server
kubectl scale deployment zenml-server -n zenml --replicas=3

# Check HPA status (if configured)
kubectl get hpa -n zenml

# View resource usage
kubectl top nodes
kubectl top pods --all-namespaces
```

### Backup and Recovery

```bash
# Backup ZenML database
kubectl exec -n zenml deployment/zenml-server -- \
  mysqldump -h <MYSQL_HOST> -u zenml -p zenml > zenml-backup.sql

# Backup ArgoCD configuration
kubectl get applications -n argocd -o yaml > argocd-apps-backup.yaml

# Backup secrets
kubectl get secrets --all-namespaces -o yaml > secrets-backup.yaml
```

## 🏗️ Infrastructure Details

## 🏗️ Infrastructure Details

### Network Architecture

```
Internet
    ↓
Google Cloud LoadBalancer (Static IP)
    ↓ (HTTPS/TLS Termination)
NGINX Ingress Controller
    ↓ (HTTP Backend)
┌─────────────────┬─────────────────┬─────────────────┐
│   ZenML Server  │  MLflow Server  │  ArgoCD UI      │
│   (port 8080)   │   (port 5000)   │   (port 8080)   │
└─────────────────┴─────────────────┴─────────────────┘
    ↓ (Private Network)
┌─────────────────┬─────────────────┐
│  Cloud SQL      │  Google Cloud   │
│  MySQL          │  Storage        │
└─────────────────┴─────────────────┘
```

### Resource Specifications

**GKE Autopilot Cluster:**
- **Node Pools**: Automatically managed by Google
- **Networking**: VPC-native with private nodes
- **Security**: Workload Identity enabled
- **Scaling**: Automatic based on resource requests

**Cloud SQL MySQL:**
- **Instance Type**: `db-n1-standard-2` (configurable)
- **Storage**: 20GB SSD (auto-expanding)
- **Backup**: Automated daily backups
- **Security**: Private IP only, SSL enforcement

**Networking:**
- **VPC**: Custom VPC with RFC 1918 IP ranges
- **Subnets**: Separate subnets for nodes, pods, and services
- **Firewall**: Restrictive rules for minimal attack surface

### Cost Estimation (Monthly)

| Component | Estimated Cost (USD) | Notes |
|-----------|---------------------|-------|
| GKE Autopilot | $74+ | Based on resource usage |
| Cloud SQL (db-n1-standard-2) | $100+ | Includes storage and backup |
| Cloud Load Balancer | $18+ | Forwarding rules and data processing |
| Cloud Storage | $5+ | Object storage for artifacts |
| Artifact Registry | $5+ | Container image storage |
| **Total** | **~$202+** | Varies based on usage |

*Note: Costs vary significantly based on actual resource usage, region, and sustained use discounts.*

## 🔄 GitOps Workflow

### Repository Structure for GitOps

```
src/
├── argocd-apps/           # ArgoCD Application definitions
│   ├── cert-manager.yaml
│   ├── external-secrets-operator.yaml
│   ├── nginx-ingress.yaml
│   ├── zenml-server.yaml
│   └── ...
├── k8s-cluster/           # Kubernetes manifests (if needed)
├── zenml/                 # ZenML Helm chart customizations
└── mlflow/                # MLflow Helm chart customizations
```

### GitOps Best Practices

1. **Environment Separation**: Use branches or directories for different environments
2. **Automated Sync**: Enable auto-sync for non-production environments
3. **Manual Sync**: Use manual sync for production deployments
4. **Health Checks**: Configure health checks for all applications
5. **Rollback Strategy**: Use ArgoCD's rollback capabilities for quick recovery

## 🚀 Advanced Configuration

### Custom Domain Setup

1. **Configure DNS Provider**
   ```bash
   # If using Google Cloud DNS (managed by Terraform)
   # Update variables.tf with your domain
   domain_name = "yourdomain.com"
   ```

2. **Manual DNS Configuration**
   ```bash
   # Get the LoadBalancer IP
   kubectl get svc -n nginx-ingress nginx-ingress-nginx-ingress-controller
   
   # Create DNS records:
   # A record: zenml.yourdomain.com → EXTERNAL_IP
   # A record: mlflow.yourdomain.com → EXTERNAL_IP
   # A record: argocd.yourdomain.com → EXTERNAL_IP
   ```

### SSL/TLS Certificate Configuration

Certificates are automatically managed by cert-manager and Let's Encrypt:

```yaml
# Example certificate resource (auto-created)
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: zenml-server-tls
  namespace: zenml
spec:
  secretName: zenml-server-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - zenml.yourdomain.com
```

### High Availability Configuration

For production environments, consider:

1. **Multi-Zone Deployment**
   ```hcl
   # In variables.tf
   zones = ["us-central1-a", "us-central1-b", "us-central1-c"]
   ```

2. **Database High Availability**
   ```hcl
   # In modules/mysql/variables.tf
   availability_type = "REGIONAL"
   ```

3. **Application Replicas**
   ```yaml
   # In ZenML values
   replicaCount: 3
   ```

## 📚 Additional Resources

### Documentation Links
- [ZenML Documentation](https://docs.zenml.io/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/docs)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

### Helpful Commands Reference

```bash
# Quick infrastructure status
make tf-output

# Connect to cluster
make connect-k8s-cluster

# Test MySQL connectivity
make test-mysql-connection

# View all pods
kubectl get pods --all-namespaces

# Port forward ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443

# View application logs
kubectl logs -f deployment/zenml-server -n zenml

# Check certificate status
kubectl get certificates --all-namespaces

# Sync ArgoCD applications
argocd app sync --all
```

## 🔒 Security Considerations

### Production Security Checklist

- [ ] **Network Security**: Verify firewall rules and private networking
- [ ] **IAM Permissions**: Review and minimize service account permissions
- [ ] **Secret Management**: Ensure all secrets are stored in Google Secret Manager
- [ ] **TLS Certificates**: Verify HTTPS is enforced on all endpoints
- [ ] **Database Security**: Confirm Cloud SQL is using private IPs and SSL
- [ ] **Container Security**: Use trusted base images and scan for vulnerabilities
- [ ] **Access Control**: Implement proper RBAC in Kubernetes and ArgoCD
- [ ] **Monitoring**: Set up logging and monitoring for security events

### Security Best Practices

1. **Regular Updates**: Keep all components updated with latest security patches
2. **Access Logging**: Enable audit logging for GKE and Cloud SQL
3. **Network Policies**: Implement Kubernetes Network Policies for micro-segmentation
4. **Image Scanning**: Use Container Analysis API for vulnerability scanning
5. **Backup Security**: Encrypt backups and test recovery procedures

## 🤝 Contributing

### Development Workflow

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/my-feature`
3. **Make changes and test**: Verify infrastructure and applications
4. **Commit changes**: `git commit -am 'Add new feature'`
5. **Push to branch**: `git push origin feature/my-feature`
6. **Create Pull Request**: Submit PR with detailed description

### Testing Changes

```bash
# Test Terraform changes
cd src/infra
terraform plan

# Test ArgoCD applications
kubectl apply --dry-run=client -f src/argocd-apps/

# Validate Kubernetes manifests
kubectl apply --dry-run=server -f src/k8s-cluster/
```

## 📝 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## 🆘 Support and Troubleshooting

### Getting Help

- **GitHub Issues**: Report bugs and request features
- **Documentation**: Check the `docs/` directory for detailed guides
- **Community**: Join ZenML and ArgoCD community forums

### Common Issues and Solutions

1. **ArgoCD Application Stuck in Progressing**
   ```bash
   kubectl describe application <app-name> -n argocd
   kubectl logs -n argocd deployment/argocd-application-controller
   ```

2. **TLS Certificate Not Issuing**
   ```bash
   kubectl describe certificaterequest -n <namespace>
   kubectl logs -n cert-manager deployment/cert-manager
   ```

3. **Database Connection Issues**
   ```bash
   # Check Cloud SQL instance status
   gcloud sql instances describe <instance-name>
   
   # Test from within cluster
   kubectl run mysql-test --image=mysql:8.0 --rm -it --restart=Never
   ```

4. **Ingress Not Accessible**
   ```bash
   kubectl describe ingress -n <namespace>
   kubectl get events --all-namespaces | grep -i error
   ```

For more detailed troubleshooting guides, see the `docs/` directory.

---

**Built with ❤️ by the MLOps Community**
