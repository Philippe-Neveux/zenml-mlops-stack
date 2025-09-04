# GitHub Workflow Setup for ArgoCD Deployment

This workflow automatically deploys all ArgoCD applications to your GKE cluster using Workload Identity Federation.

## 🔧 Required GitHub Secrets

You need to configure these secrets in your GitHub repository:

### 1. `WIF_PROVIDER`
The Workload Identity Federation provider resource name.

**Format:** `projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/providers/PROVIDER_ID`

**Example:** `projects/123456789/locations/global/workloadIdentityPools/github-pool/providers/github-provider`

### 2. `WIF_SERVICE_ACCOUNT`
The Google Service Account email that has permissions to manage your GKE cluster.

**Format:** `service-account-name@PROJECT_ID.iam.gserviceaccount.com`

**Example:** `github-actions@zenml-470505.iam.gserviceaccount.com`

## 🚀 How to Set Up Workload Identity Federation

### 1. Create a Workload Identity Pool:
```bash
gcloud iam workload-identity-pools create github-pool \
  --location="global" \
  --description="GitHub Actions pool" \
  --display-name="GitHub Actions Pool"
```

### 2. Create a Workload Identity Provider:
```bash
gcloud iam workload-identity-pools providers create-oidc github-provider \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --display-name="GitHub Actions Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
  --issuer-uri="https://token.actions.githubusercontent.com"
```

### 3. Create a Service Account:
```bash
gcloud iam service-accounts create github-actions \
  --description="Service account for GitHub Actions" \
  --display-name="GitHub Actions"
```

### 4. Grant Permissions to the Service Account:
```bash
# GKE cluster access
gcloud projects add-iam-policy-binding zenml-470505 \
  --member="serviceAccount:github-actions@zenml-470505.iam.gserviceaccount.com" \
  --role="roles/container.developer"

# Allow GitHub to impersonate the service account
gcloud iam service-accounts add-iam-policy-binding \
  github-actions@zenml-470505.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/attribute.repository/Philippe-Neveux/zenml-mlops-stack"
```

### 5. Get the Provider Resource Name:
```bash
gcloud iam workload-identity-pools providers describe github-provider \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --format="value(name)"
```

## 📝 Workflow Triggers

The workflow runs on:

1. **Push to main/argo-cd branches** when these paths change:
   - `src/argocd-apps/**`
   - `src/k8s-cluster/**` 
   - `src/zenml/**`
   - `.github/workflows/deploy-argocd-apps.yml`

2. **Manual trigger** with options to:
   - Deploy all applications
   - Deploy specific applications only

## 🌊 Deployment Waves

The workflow deploys applications in the correct order:

1. **Wave 0**: External Secrets Operator
2. **Wave 1**: cert-manager
3. **Wave 2**: cluster-issuers & zenml-external-secrets
4. **Wave 3**: nginx-ingress
5. **Wave 4**: zenml-server

## 🎮 Manual Deployment

You can trigger the workflow manually from GitHub Actions with:

- **Deploy All**: Deploys all applications in order
- **Specific Apps**: Deploy only selected applications (comma-separated):
  - `external-secrets`
  - `cert-manager`
  - `cluster-issuers`
  - `zenml-external-secrets`
  - `nginx-ingress`
  - `zenml-server`

## 🔍 Monitoring

The workflow provides:

- ✅ Health checks for each application
- 📊 Status verification
- 🌐 Application URLs
- 📱 Deployment notifications

## 🚨 Prerequisites

Before running the workflow:

1. ArgoCD must be installed and running
2. GCP secrets must be created (run `make gcp-create-zenml-secrets`)
3. Workload Identity Federation must be configured
4. GitHub secrets must be set

## 🔧 Local Testing

You can test the same commands locally:

```bash
# Deploy all applications
make argocd-apps-deploy-all

# Deploy individual applications
make argocd-app-external-secrets
make argocd-app-cert-manager
# ... etc
```
