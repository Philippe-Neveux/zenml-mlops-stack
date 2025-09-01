# HTTPS Ingress Setup Guide

This guide explains how to expose ZenML services to the internet with HTTPS using the infrastructure you've deployed.

## Overview

Your infrastructure now includes:
- **NGINX Ingress Controller**: Routes external traffic to Kubernetes services
- **cert-manager**: Automatically manages TLS certificates from Let's Encrypt
- **Static IP**: Pre-allocated external IP for your LoadBalancer
- **DNS (optional)**: Google Cloud DNS management for custom domains

## Quick Start

### 1. Deploy the Infrastructure

```bash
cd src/infra
terraform init
terraform plan
terraform apply
```

### 2. Get Your Access Information

```bash
# Get the ingress IP address
terraform output nginx_ingress_ip

# Get the example hostname
terraform output example_hostname

# Get all ZenML access info
terraform output zenml_access_info
```

### 3. Configure kubectl

```bash
# Configure kubectl to access your cluster
gcloud container clusters get-credentials zenml --region australia-southeast1 --project zenml-470505
```

### 4. Verify Ingress Controller

```bash
# Check that NGINX Ingress is running
kubectl get pods -n ingress-nginx

# Check the LoadBalancer service
kubectl get svc -n ingress-nginx
```

## Exposing ZenML Services

### Option 1: Using nip.io (No DNS Setup Required)

Perfect for testing and development:

1. Use the IP from `terraform output nginx_ingress_ip`
2. Access your services at: `zenml.YOUR_IP.nip.io`
3. Example: `zenml.34.102.136.180.nip.io`

### Option 2: Using Your Own Domain

1. Set up DNS:
   ```bash
   # If using the DNS module, get the name servers
   terraform output dns_name_servers
   
   # Update your domain registrar to use these name servers
   ```

2. Or manually point your domain:
   ```bash
   # Point your domain A record to:
   terraform output nginx_ingress_ip
   ```

## Deploying ZenML with Ingress

### 1. Deploy ZenML

First, deploy ZenML to your cluster using Helm or kubectl. Here's an example with Helm:

```bash
# Add ZenML Helm repository
helm repo add zenml https://zenml-io.github.io/zenml-helm-chart
helm repo update

# Deploy ZenML
helm install zenml zenml/zenml-server \
  --namespace zenml \
  --create-namespace \
  --set zenml.image.tag=latest
```

### 2. Create Ingress Resource

Use the provided example and customize it:

```bash
# Copy the example
cp zenml-ingress-example.yaml zenml-ingress.yaml

# Edit the file to match your setup:
# - Replace 'yourdomain.com' with your actual domain or use nip.io
# - Update service names and ports to match your ZenML deployment
```

Example for nip.io:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: zenml-server
  namespace: zenml
  annotations:
    kubernetes.io/ingress.class: "nginx"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - zenml.34.102.136.180.nip.io  # Replace with your actual IP
    secretName: zenml-tls
  rules:
  - host: zenml.34.102.136.180.nip.io  # Replace with your actual IP
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: zenml-server
            port:
              number: 8080
```

### 3. Apply the Ingress

```bash
kubectl apply -f zenml-ingress.yaml
```

### 4. Verify Certificate

```bash
# Check certificate status
kubectl get certificates -n zenml

# Check certificate details
kubectl describe certificate zenml-tls -n zenml

# Check ingress status
kubectl get ingress -n zenml
```

## Accessing Your Services

After deployment, you can access ZenML at:

- **HTTP**: `http://YOUR_IP`
- **HTTPS**: `https://zenml.YOUR_DOMAIN.com` or `https://zenml.YOUR_IP.nip.io`

## Troubleshooting

### Certificate Issues

```bash
# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager

# Check certificate request status
kubectl get certificaterequests -n zenml

# Force certificate renewal
kubectl delete certificate zenml-tls -n zenml
```

### Ingress Issues

```bash
# Check NGINX Ingress logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# Check ingress events
kubectl describe ingress zenml-server -n zenml
```

### DNS Issues

```bash
# Test DNS resolution
nslookup zenml.yourdomain.com

# Check if IP is correct
dig +short zenml.yourdomain.com
```

## Security Considerations

1. **Use Production Certificate Issuer**: Switch from `letsencrypt-staging` to `letsencrypt-prod` for production
2. **Network Policies**: Consider implementing Kubernetes Network Policies
3. **TLS Configuration**: NGINX Ingress enforces TLS 1.2+ by default
4. **Rate Limiting**: Configure rate limiting in NGINX Ingress if needed

## Adding More Services

To expose additional services (like monitoring, dashboards, etc.):

1. Create additional Ingress resources
2. Use subdomains: `monitoring.yourdomain.com`, `grafana.yourdomain.com`
3. Leverage the wildcard DNS record for automatic resolution

## Cost Optimization

- The LoadBalancer uses a single static IP for all services
- cert-manager automatically renews certificates (free with Let's Encrypt)
- DNS queries are minimal cost in Google Cloud DNS
