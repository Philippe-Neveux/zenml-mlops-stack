# Kubernetes Applications Deployment

This directory contains YAML manifests for deploying the core Kubernetes applications needed for the ZenML infrastructure.

## 📁 Directory Structure

```
src/k8s-cluster/
├── ingress-nginx/          # NGINX Ingress Controller
│   ├── 00-rbac.yaml        # RBAC configurations
│   ├── 01-controller.yaml  # Main controller deployment
│   ├── 02-service.yaml     # LoadBalancer service (needs IP update)
│   └── 03-admission-webhook.yaml  # Admission webhook
├── cert-manager/           # Certificate management
│   ├── 00-namespace.yaml   # Namespace and installation guide
│   └── 01-cluster-issuers.yaml  # Let's Encrypt issuers
└── zenml/                  # ZenML application examples
    ├── 01-server.yaml      # ZenML server deployment
    └── 02-ingress.yaml     # Ingress configuration
```

## 🚀 Deployment Steps

### 1. Prerequisites

Ensure you have:
- Terraform infrastructure deployed (`terraform apply` completed)
- kubectl configured to access your cluster
- Your static IP address from Terraform output

```bash
# Get your static IP
cd src/infra
terraform output -raw nginx_ingress_ip

# Configure kubectl
gcloud container clusters get-credentials zenml --region australia-southeast1 --project zenml-470505
```

### 2. Update Configuration Files

Before deploying, update the following files with your specific values:

#### **ingress-nginx/02-service.yaml**
```bash
# Replace REPLACE_WITH_YOUR_STATIC_IP with your actual IP
STATIC_IP=$(cd src/infra && terraform output -raw nginx_ingress_ip)
sed -i "s/REPLACE_WITH_YOUR_STATIC_IP/$STATIC_IP/g" src/k8s-cluster/ingress-nginx/02-service.yaml
```

#### **cert-manager/01-cluster-issuers.yaml**
```bash
# Replace admin@example.com with your email
sed -i "s/admin@example.com/your-email@domain.com/g" src/k8s-cluster/cert-manager/01-cluster-issuers.yaml
```

#### **zenml/02-ingress.yaml**
```bash
# Replace YOUR_DOMAIN.com with your actual domain or IP.nip.io
DOMAIN=$(cd src/infra && terraform output -raw example_hostname)
sed -i "s/YOUR_DOMAIN.com/$DOMAIN/g" src/k8s-cluster/zenml/02-ingress.yaml
```

### 3. Deploy NGINX Ingress Controller

```bash
# Deploy NGINX Ingress Controller
kubectl apply -f src/k8s-cluster/ingress-nginx/

# Wait for deployment to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Verify LoadBalancer service gets the external IP
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

### 4. Deploy cert-manager

```bash
# Install cert-manager with CRDs
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml

# Wait for cert-manager to be ready
kubectl wait --namespace cert-manager \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=cert-manager \
  --timeout=120s

# Deploy ClusterIssuers
kubectl apply -f src/k8s-cluster/cert-manager/01-cluster-issuers.yaml

# Verify ClusterIssuers are ready
kubectl get clusterissuers
```

### 5. Deploy ZenML (Optional)

```bash
# Deploy ZenML server (update the configuration first!)
kubectl apply -f src/k8s-cluster/zenml/

# Wait for deployment
kubectl wait --namespace zenml \
  --for=condition=ready pod \
  --selector=app=zenml-server \
  --timeout=120s

# Check ingress and certificates
kubectl get ingress -n zenml
kubectl get certificates -n zenml
```

## 🔧 Configuration Options

### Static IP Configuration

The LoadBalancer service in `ingress-nginx/02-service.yaml` is configured to use your static IP:

```yaml
spec:
  type: LoadBalancer
  loadBalancerIP: YOUR_STATIC_IP  # This gets replaced
  externalTrafficPolicy: Local
```

### SSL/TLS Certificates

ClusterIssuers are configured for both staging and production:

- **letsencrypt-staging**: For testing (untrusted certificates)
- **letsencrypt-prod**: For production (trusted certificates)

Start with staging, then switch to production:

```yaml
metadata:
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-staging"  # Test first
    # cert-manager.io/cluster-issuer: "letsencrypt-prod"   # Then use this
```

### Domain Configuration

The ingress configurations support:

1. **Custom domain**: `zenml.yourdomain.com`
2. **nip.io wildcard**: `zenml.YOUR_IP.nip.io` (no DNS setup needed)

## 🔍 Verification Commands

```bash
# Check all pods are running
kubectl get pods -A

# Check ingress controller
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

# Check cert-manager
kubectl get pods -n cert-manager
kubectl get clusterissuers

# Check ZenML
kubectl get pods -n zenml
kubectl get ingress -n zenml
kubectl get certificates -n zenml

# Check certificate details
kubectl describe certificate zenml-tls -n zenml
```

## 🛠️ Troubleshooting

### LoadBalancer IP Issues

```bash
# Check if external IP is assigned
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Check events for issues
kubectl describe svc -n ingress-nginx ingress-nginx-controller
```

### Certificate Issues

```bash
# Check certificate status
kubectl get certificates -A
kubectl describe certificate zenml-tls -n zenml

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager -f

# Check challenges
kubectl get challenges -A
```

### DNS Issues

```bash
# Test DNS resolution
nslookup zenml.yourdomain.com

# Check if domain points to correct IP
dig +short zenml.yourdomain.com
```

## 🔄 Updates and Maintenance

### Updating NGINX Ingress

```bash
# Update to newer version
kubectl set image deployment/ingress-nginx-controller \
  controller=registry.k8s.io/ingress-nginx/controller:v1.9.0 \
  -n ingress-nginx
```

### Updating cert-manager

```bash
# Update cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.0/cert-manager.yaml
```

### Certificate Renewal

Certificates auto-renew, but you can force renewal:

```bash
# Delete certificate to force renewal
kubectl delete certificate zenml-tls -n zenml

# cert-manager will automatically create a new one
```

## 📞 Support

- Check logs: `kubectl logs -n <namespace> <pod-name>`
- Check events: `kubectl get events -n <namespace> --sort-by=.metadata.creationTimestamp`
- Check resource status: `kubectl describe <resource-type> <resource-name> -n <namespace>`
