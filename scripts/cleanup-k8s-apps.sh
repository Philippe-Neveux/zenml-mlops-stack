#!/bin/bash
# Cleanup Kubernetes applications deployed via Helm
# This removes Helm releases but keeps the namespaces (managed by Terraform)

set -e

echo "🧹 Cleaning up Kubernetes applications..."

# Ensure kubectl is configured
gcloud container clusters get-credentials zenml --region australia-southeast1 --project zenml-470505

# Remove ClusterIssuers first
echo "📜 Removing ClusterIssuers..."
kubectl delete clusterissuer letsencrypt-prod letsencrypt-staging --ignore-not-found=true

# Uninstall Helm releases
echo "📦 Removing cert-manager..."
helm uninstall cert-manager -n cert-manager --ignore-not-found

echo "🌐 Removing NGINX Ingress Controller..."
helm uninstall ingress-nginx -n ingress-nginx --ignore-not-found

# Wait for resources to be cleaned up
echo "⏳ Waiting for cleanup to complete..."
sleep 30

echo "✅ Kubernetes applications cleanup complete!"
echo ""
echo "ℹ️  Note: Namespaces are managed by Terraform and will remain."
echo "   To remove namespaces, run: terraform destroy"
