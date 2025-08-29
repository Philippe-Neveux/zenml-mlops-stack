#!/bin/bash

# Post-deployment setup script for GKE cluster
# This script installs essential components after Terraform deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

print_status $BLUE "🚀 Post-Deployment GKE Setup"
print_status $BLUE "============================="

# Check required tools
print_status $YELLOW "🔍 Checking required tools..."

if ! command_exists kubectl; then
    print_status $RED "❌ kubectl is not installed. Please install kubectl first."
    exit 1
fi

if ! command_exists helm; then
    print_status $RED "❌ Helm is not installed. Please install Helm first."
    exit 1
fi

if ! command_exists gcloud; then
    print_status $RED "❌ Google Cloud SDK is not installed. Please install gcloud first."
    exit 1
fi

print_status $GREEN "✅ All required tools are installed"

# Get cluster information from Terraform output
if [ ! -f "terraform.tfstate" ] && [ ! -f ".terraform/terraform.tfstate" ]; then
    print_status $RED "❌ Terraform state not found. Please run terraform apply first."
    exit 1
fi

print_status $YELLOW "🔄 Getting cluster information..."
CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "")
REGION=$(terraform output -json | jq -r '.region.value // "us-central1"' 2>/dev/null || echo "us-central1")
PROJECT_ID=$(terraform output -json | jq -r '.project_id.value // ""' 2>/dev/null || echo "")

if [ -z "$CLUSTER_NAME" ]; then
    print_status $RED "❌ Could not get cluster name from Terraform output"
    exit 1
fi

if [ -z "$PROJECT_ID" ]; then
    PROJECT_ID=$(gcloud config get-value project)
    if [ -z "$PROJECT_ID" ]; then
        print_status $RED "❌ Could not determine GCP project ID"
        exit 1
    fi
fi

print_status $GREEN "✅ Cluster: $CLUSTER_NAME, Region: $REGION, Project: $PROJECT_ID"

# Configure kubectl
print_status $YELLOW "🔄 Configuring kubectl..."
if gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION" --project "$PROJECT_ID"; then
    print_status $GREEN "✅ kubectl configured successfully"
else
    print_status $RED "❌ Failed to configure kubectl"
    exit 1
fi

# Test cluster connectivity
print_status $YELLOW "🔄 Testing cluster connectivity..."
if kubectl get nodes > /dev/null 2>&1; then
    print_status $GREEN "✅ Successfully connected to cluster"
    kubectl get nodes
else
    print_status $RED "❌ Failed to connect to cluster"
    exit 1
fi

# Install ArgoCD
print_status $YELLOW "🔄 Installing ArgoCD..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

if kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml; then
    print_status $GREEN "✅ ArgoCD installed successfully"
else
    print_status $RED "❌ Failed to install ArgoCD"
    exit 1
fi

print_status $YELLOW "🔄 Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Install NGINX Ingress Controller (alternative to GKE Ingress)
print_status $YELLOW "🔄 Installing NGINX Ingress Controller..."

# Add ingress-nginx charts repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install NGINX Ingress Controller
if helm install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx \
    --create-namespace \
    --set controller.service.type=LoadBalancer \
    --set controller.service.annotations."cloud\.google\.com/load-balancer-type"="External"; then
    print_status $GREEN "✅ NGINX Ingress Controller installed successfully"
else
    print_status $YELLOW "⚠️  NGINX Ingress Controller installation may have failed, but continuing..."
fi

# Configure Workload Identity for ArgoCD (if service account exists)
ARGOCD_SA_EMAIL=$(terraform output -raw argocd_service_account_email 2>/dev/null || echo "")
if [ -n "$ARGOCD_SA_EMAIL" ]; then
    print_status $YELLOW "🔄 Configuring Workload Identity for ArgoCD..."
    
    # Create Kubernetes service account
    kubectl create serviceaccount argocd-application-controller -n argocd --dry-run=client -o yaml | kubectl apply -f -
    
    # Annotate the Kubernetes service account
    kubectl annotate serviceaccount argocd-application-controller \
        -n argocd \
        iam.gke.io/gcp-service-account="$ARGOCD_SA_EMAIL" \
        --overwrite
    
    print_status $GREEN "✅ Workload Identity configured for ArgoCD"
else
    print_status $YELLOW "⚠️  ArgoCD service account not found in Terraform output"
fi

# Get ArgoCD admin password
print_status $YELLOW "🔄 Getting ArgoCD admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null || echo "")

# Get ingress IP address
INGRESS_IP=$(terraform output -raw ingress_ip_address 2>/dev/null || echo "")

print_status $GREEN "🎉 Setup completed successfully!"
print_status $BLUE "================================================"
print_status $GREEN "✅ GKE cluster is ready for use"
print_status $YELLOW "📋 Summary:"
print_status $YELLOW "   • Cluster Name: $CLUSTER_NAME"
print_status $YELLOW "   • Region: $REGION"
print_status $YELLOW "   • Project: $PROJECT_ID"
print_status $YELLOW "   • ArgoCD installed in 'argocd' namespace"
print_status $YELLOW "   • NGINX Ingress Controller installed"
if [ -n "$INGRESS_IP" ]; then
    print_status $YELLOW "   • Ingress IP: $INGRESS_IP"
fi
print_status $BLUE "================================================"

if [ -n "$ARGOCD_PASSWORD" ]; then
    print_status $YELLOW "🔑 ArgoCD Access:"
    print_status $YELLOW "   Username: admin"
    print_status $YELLOW "   Password: $ARGOCD_PASSWORD"
    print_status $YELLOW "   Access via port-forward: kubectl port-forward svc/argocd-server -n argocd 8080:443"
    print_status $YELLOW "   Then visit: https://localhost:8080"
fi

print_status $YELLOW "🔧 Useful commands:"
print_status $YELLOW "   • Check nodes: kubectl get nodes"
print_status $YELLOW "   • Check pods: kubectl get pods --all-namespaces"
print_status $YELLOW "   • ArgoCD UI: kubectl port-forward svc/argocd-server -n argocd 8080:443"
print_status $YELLOW "   • Get services: kubectl get svc --all-namespaces"
print_status $YELLOW "   • Check ingress: kubectl get ingress --all-namespaces"
print_status $YELLOW "   • View cluster info: gcloud container clusters describe $CLUSTER_NAME --region $REGION"

print_status $GREEN "Ready for MLOps workloads! 🚀"
