# ZenML MLOps Stack on Google Cloud

A production-ready Terraform infrastructure for deploying ZenML on Google Kubernetes Engine (GKE) with HTTPS ingress support.

## Features

### Infrastructure
- **GKE Autopilot Cluster**: Managed Kubernetes with automatic scaling and security
- **VPC Networking**: Custom network with proper subnet configuration
- **Cloud SQL MySQL**: Managed database for ZenML metadata storage
- **Security**: IAM roles, service accounts, and network security rules

### HTTPS & Ingress (NEW)
- **NGINX Ingress Controller**: Production-ready ingress with LoadBalancer
- **Automatic HTTPS**: Let's Encrypt certificates via cert-manager
- **Custom Domains**: Support for your own domain with Google Cloud DNS
- **nip.io Support**: Testing without DNS setup using `zenml.YOUR_IP.nip.io`
- **Static IP**: Pre-allocated external IP address

## Quick Start

### 1. Prerequisites

- Google Cloud account with billing enabled
- `terraform` >= 1.0
- `gcloud` CLI configured
- `kubectl` for Kubernetes management

### 2. Configure Variables

Edit `src/infra/variables.tf` or create a `terraform.tfvars` file:

```hcl
project_id   = "your-project-id"
project_name = "zenml"
region       = "us-central1"

# Optional: For custom domain
domain_name = "yourdomain.com"
admin_email = "admin@yourdomain.com"
```

### 3. Deploy Infrastructure

```bash
cd src/infra
terraform init
terraform apply
```

### 4. Access Information

```bash
# Get your ZenML access URL
terraform output zenml_access_info

# Configure kubectl
terraform output quick_commands
```

## Architecture

```
Internet
    ↓
Google Cloud LoadBalancer (Static IP)
    ↓
NGINX Ingress Controller
    ↓
┌─────────────────┬─────────────────┐
│   ZenML Server  │  Other Services │
│   (port 8080)   │   (port 3000)   │
└─────────────────┴─────────────────┘
    ↓
Cloud SQL MySQL (Private Network)
```

## Components

### Core Infrastructure
- **VPC**: Custom network with public/private subnets
- **GKE Autopilot**: Managed Kubernetes cluster
- **Cloud SQL**: MySQL database for ZenML metadata
- **IAM**: Service accounts and security policies

### Ingress & HTTPS
- **NGINX Ingress**: Routes external traffic to services
- **cert-manager**: Automatic TLS certificate management
- **Let's Encrypt**: Free SSL/TLS certificates
- **Cloud DNS**: Domain management (optional)

## Usage Examples

### Using nip.io (No DNS Setup)

Perfect for testing:

```bash
# Get your IP
IP=$(terraform output -raw nginx_ingress_ip)

# Access ZenML
curl https://zenml.$IP.nip.io
```

### Using Custom Domain

1. **With Terraform DNS management**:
   ```hcl
   domain_name = "example.com"
   ```

2. **Manual DNS setup**:
   ```bash
   # Point your domain to the LoadBalancer IP
   IP=$(terraform output -raw nginx_ingress_ip)
   # Create A record: zenml.example.com -> $IP
   ```

### Deploy ZenML with Ingress

```bash
# Deploy ZenML
helm install zenml zenml/zenml-server --namespace zenml --create-namespace

# Apply ingress configuration
kubectl apply -f zenml-ingress-example.yaml
```

## Documentation

- [HTTPS Ingress Setup Guide](docs/HTTPS_INGRESS_SETUP.md) - Complete setup instructions
- [MySQL Connectivity](docs/MYSQL_CONNECTIVITY.md) - Database connection guide
- [ZenML Deployment Info](docs/ZENML_DEPLOYMENT_INFO.md) - ZenML-specific configuration

## Security Features

- **Private GKE nodes**: Nodes don't have public IPs
- **Private Cloud SQL**: Database only accessible from VPC
- **Network security**: Firewall rules and IAM policies
- **TLS termination**: HTTPS encryption at the LoadBalancer
- **Let's Encrypt**: Automatic certificate renewal

## Cost Optimization

- **GKE Autopilot**: Pay only for running pods
- **Single LoadBalancer**: One IP for all services
- **Regional resources**: Avoid cross-region charges
- **Free certificates**: Let's Encrypt (no certificate costs)

## Monitoring & Observability

```bash
# Check ingress status
kubectl get ingress -A

# Monitor certificate status
kubectl get certificates -A

# View NGINX logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

## Troubleshooting

### Common Issues

1. **Certificate not ready**: Check cert-manager logs and DNS propagation
2. **Ingress not accessible**: Verify LoadBalancer service and firewall rules
3. **Domain not resolving**: Check DNS records and propagation

### Useful Commands

```bash
# Get all infrastructure info
terraform output

# Check cluster connectivity
kubectl cluster-info

# Verify ingress controller
kubectl get pods -n ingress-nginx

# Check certificate status
kubectl get certificates -A
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the infrastructure
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
- Check the [troubleshooting guide](docs/HTTPS_INGRESS_SETUP.md#troubleshooting)
- Review Terraform and kubectl logs
- Open an issue with detailed error information
