# ZenML MLOps Stack on Google Cloud

A complete production-ready MLOps infrastructure deployment using Terraform, ArgoCD, and Kubernetes on Google Cloud Platform. This repository provides automated infrastructure provisioning and GitOps-based application deployment for a comprehensive ZenML stack.

## 🏗️ Architecture Overview

![Architecture Overview](assets/zenml_mlops_stacks_architecture.png)

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

## 🚀 Quick Start

Ready to get started? Follow these essential steps:

1. **Prerequisites**: Set up your Google Cloud environment and required tools
2. **Infrastructure**: Deploy the Terraform infrastructure on Google Cloud
3. **Applications**: Install ArgoCD and deploy the application stack
4. **Configuration**: Configure HTTPS ingress and certificates
5. **Access**: Access your ZenML and MLflow services

!!! tip "New to MLOps?"
    If you're new to MLOps or ZenML, start with our [Getting Started Guide](getting-started/index.md) for a comprehensive walkthrough.

## 🛠️ What's Included

### Infrastructure as Code
- **Terraform Modules**: Modular infrastructure components
- **Google Cloud Resources**: VPC, GKE, Cloud SQL, Storage, IAM
- **Security**: KMS encryption, Workload Identity, private networking
- **Cost Optimization**: Resource sizing and automated scaling

### GitOps Applications
- **ArgoCD Applications**: Declarative application deployment
- **Helm Charts**: Customized charts for ZenML and MLflow
- **Kubernetes Manifests**: Production-ready configurations
- **External Secrets**: Secure credential management

### Production Features
- **High Availability**: Multi-zone deployment options
- **Monitoring**: Health checks and observability
- **Backup & Recovery**: Automated database backups
- **Scaling**: Horizontal pod autoscaling and cluster autoscaling

## 🎯 Use Cases

This stack is perfect for:

- **ML Teams** wanting production-ready infrastructure
- **Data Scientists** needing experiment tracking and model registry
- **DevOps Engineers** implementing MLOps best practices
- **Organizations** adopting GitOps workflows
- **Startups to Enterprise** requiring scalable ML infrastructure

## 🔗 Quick Links

- [Prerequisites](getting-started/prerequisites.md) - Set up your environment
- [Quick Start](getting-started/quick-start.md) - Deploy in minutes
- [Architecture](reference/index.md) - Detailed system design
- [Troubleshooting](troubleshooting/index.md) - Common issues and solutions

## 🤝 Community

- **GitHub Issues**: Report bugs and request features
- **Documentation**: Improve guides and tutorials
- **Community Forums**: Join ZenML and ArgoCD discussions

---

!!! info "Ready to Deploy?"
    Head over to [Getting Started](getting-started/index.md) to begin your MLOps journey!