# MLflow Deployment Guide

This directory contains the configuration for deploying MLflow as an Experiment Tracker and Model Registry in your Kubernetes cluster.

## Overview

MLflow is deployed using the community Helm chart with custom configurations for:
- Database backend (Cloud SQL MySQL)
- Artifact storage (Google Cloud Storage)
- HTTPS ingress with cert-manager
- Workload Identity integration
- Horizontal Pod Autoscaling

## Architecture

```
┌─────────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│   MLflow UI/API     │────│   MLflow Server  │────│   MySQL Database   │
│  (via Ingress)      │    │  (Kubernetes)    │    │   (Cloud SQL)      │
└─────────────────────┘    └──────────────────┘    └─────────────────────┘
                                      │
                                      ▼
                           ┌─────────────────────┐
                           │   GCS Bucket       │
                           │  (Artifacts)       │
                           └─────────────────────┘
```

## Files Structure

- `values.yaml` - Complete MLflow Helm chart configuration (all-in-one)
- `README.md` - Documentation and troubleshooting guide

## Prerequisites

1. **Infrastructure**: Ensure Terraform has been applied with MLflow modules
2. **External Secrets**: MLflow external secrets should be deployed first
3. **Ingress Controller**: NGINX ingress controller must be running
4. **Cert Manager**: For automatic HTTPS certificate management

## Configuration

### Database Connection

MLflow uses the shared Cloud SQL MySQL instance with:
- Database: `mlflow`
- User: `mlflow_user`
- Credentials: Retrieved via External Secrets from Secret Manager

### Artifact Storage

Artifacts are stored in Google Cloud Storage:
- Bucket: `zenml-mlflow-artifacts`
- Authentication: Via Workload Identity
- Access: Proxied through MLflow server for security

### Access URL

After deployment, MLflow will be available at:
- URL: `https://mlflow.zenml-470505.com`
- Certificate: Automatically managed by cert-manager

## Deployment Order

The deployment follows this sequence:

1. **Infrastructure (Sync Wave 1)**: Terraform creates GCP resources
2. **External Secrets (Sync Wave 2)**: Database credentials and configuration
3. **MLflow Server (Sync Wave 3)**: Main application deployment

## Resource Allocation

### Default Resources
- **CPU**: 200m (request) / 1000m (limit)
- **Memory**: 512Mi (request) / 2Gi (limit)
- **Replicas**: 1-2 (autoscaling based on CPU >70%)

### Storage
- **Database**: Shared Cloud SQL instance
- **Artifacts**: Unlimited GCS storage
- **Logs**: Container logs via Kubernetes

## Security Features

1. **Workload Identity**: Secure GCP authentication without storing keys
2. **External Secrets**: Database credentials managed via Secret Manager
3. **HTTPS Only**: TLS termination at ingress with automatic certificates
4. **Network Policies**: Optional isolation (can be enabled)
5. **RBAC**: Least privilege service account

## Monitoring & Observability

### Health Checks
- **Liveness Probe**: Ensures container is running
- **Readiness Probe**: Ensures service is ready to accept traffic
- **Database Check**: Validates database connectivity on startup

### Metrics
- Built-in MLflow metrics endpoint
- Kubernetes resource metrics
- Optional Prometheus integration

## Troubleshooting

### Common Issues

1. **Database Migration Failures**
   ```bash
   kubectl logs -n mlflow deployment/mlflow-server
   kubectl describe pod -n mlflow -l app.kubernetes.io/name=mlflow
   ```

2. **External Secret Not Found**
   ```bash
   kubectl get externalsecret -n mlflow
   kubectl describe externalsecret mlflow-database-secret -n mlflow
   ```

3. **GCS Access Issues**
   ```bash
   kubectl get serviceaccount mlflow -n mlflow -o yaml
   kubectl describe pod -n mlflow -l app.kubernetes.io/name=mlflow
   ```

4. **Ingress Certificate Issues**
   ```bash
   kubectl get certificate -n mlflow
   kubectl describe certificate mlflow-tls -n mlflow
   ```

### Debug Commands

```bash
# Check MLflow pod status
kubectl get pods -n mlflow

# View MLflow logs
kubectl logs -n mlflow deployment/mlflow-server -f

# Check external secret status
kubectl get externalsecret -n mlflow -o wide

# Test database connectivity
kubectl exec -n mlflow deployment/mlflow-server -- python -c "
import pymysql
import os
conn = pymysql.connect(
    host='10.175.0.3',
    user=os.environ.get('MYSQL_USER', 'mlflow_user'),
    password=os.environ.get('MYSQL_PASSWORD'),
    database='mlflow'
)
print('Database connection successful')
"

# Test GCS access
kubectl exec -n mlflow deployment/mlflow-server -- python -c "
from google.cloud import storage
client = storage.Client()
bucket = client.bucket('zenml-mlflow-artifacts')
print(f'Bucket exists: {bucket.exists()}')
"
```

## Customization

### Environment-Specific Changes

Edit `values.yaml` directly for your environment. Key sections to customize:

```yaml
# Update domain
ingress:
  hosts:
    - host: mlflow.your-domain.com

# Adjust resources
resources:
  limits:
    cpu: 2000m
    memory: 4Gi

# Scale settings
autoscaling:
  maxReplicas: 5

# Image version
image:
  tag: "2.22.2"
```

### Advanced Configuration

For advanced MLflow features, refer to:
- [MLflow Configuration Documentation](https://mlflow.org/docs/latest/tracking.html#tracking-server)
- [Community Helm Chart Values](https://github.com/community-charts/helm-charts/tree/main/charts/mlflow)

## Integration with ZenML

Once MLflow is deployed, you can configure ZenML to use it:

```python
from zenml.integrations.mlflow.experiment_trackers import MLFlowExperimentTracker

# Register MLflow experiment tracker
experiment_tracker = MLFlowExperimentTracker(
    tracking_uri="https://mlflow.zenml-470505.com",
    tracking_username=None,  # Not needed for this setup
    tracking_password=None,  # Not needed for this setup
)

# Register with ZenML
zenml experiment-tracker register mlflow_tracker \
    --flavor=mlflow \
    --tracking_uri=https://mlflow.zenml-470505.com
```

## Backup and Disaster Recovery

### Database Backup
- Automated backups via Cloud SQL (7-day retention)
- Point-in-time recovery available

### Artifacts Backup
- GCS versioning enabled
- Cross-region replication (optional)

### Configuration Backup
- All configurations stored in Git
- ArgoCD provides rollback capabilities

## Performance Tuning

### For High Load
```yaml
autoscaling:
  minReplicas: 2
  maxReplicas: 10

resources:
  requests:
    cpu: 500m
    memory: 1Gi
  limits:
    cpu: 2000m
    memory: 4Gi

extraArgs:
  workers: 4
```

### For Development
```yaml
autoscaling:
  enabled: false

replicas: 1

resources:
  requests:
    cpu: 100m
    memory: 256Mi
```

## Cost Optimization

1. **Right-size resources** based on actual usage
2. **Use preemptible nodes** for non-critical workloads
3. **Enable GCS lifecycle policies** for old artifacts
4. **Monitor database connections** to optimize connection pooling

## Support

For issues and questions:
1. Check the troubleshooting section above
2. Review MLflow and Helm chart documentation
3. Check ArgoCD application status
4. Review Kubernetes events and logs
