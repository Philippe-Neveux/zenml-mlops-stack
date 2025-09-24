# Operations

This section covers the operational aspects of managing your ZenML MLOps stack in production, including monitoring, scaling, backup, and maintenance procedures.

## 🔧 Operations Overview

### Key Operational Areas
- **Monitoring** - Health checks, metrics, and alerting
- **Backup and recovery** - Data protection and disaster recovery
- **Scaling** - Resource management and auto-scaling

### Maintenance Tasks
- **Updates** - Application and infrastructure updates
- **Security** - Vulnerability management and patches
- **Performance** - Resource optimization and tuning

## 📊 Operational Dashboard

### Key Metrics to Monitor

| Metric Category | Key Indicators | Tools |
|----------------|----------------|-------|
| **Infrastructure** | CPU, Memory, Disk, Network | Google Cloud Monitoring |
| **Applications** | Response time, Error rate, Throughput | Application logs, Prometheus |
| **Database** | Connections, Query performance, Storage | Cloud SQL Insights |
| **Certificates** | Expiration dates, Renewal status | cert-manager metrics |
| **Storage** | Usage, Performance, Costs | Cloud Storage metrics |

## 🎯 Operational Workflows

### Daily Operations
```bash
# Health check routine
kubectl get nodes
kubectl get pods --all-namespaces
kubectl get applications -n argocd

# Check ingress and certificates
kubectl get ingress,certificates --all-namespaces

# Monitor resource usage
kubectl top nodes
kubectl top pods --all-namespaces
```

### Weekly Operations
```bash
# Review application logs
kubectl logs -n zenml deployment/zenml-server --tail=100

# Check database performance
gcloud sql operations list --instance=zenml-mysql

# Review security and updates
kubectl get pods --all-namespaces -o wide
```

### Monthly Operations
```bash
# Review costs and usage
gcloud billing budgets list

# Update applications and security patches
# (via GitOps commits and ArgoCD sync)

# Test backup and recovery procedures
# (validate backup integrity and restoration)
```

## 🔍 Monitoring Strategy

### Infrastructure Monitoring
- **Google Cloud Monitoring** for infrastructure metrics
- **GKE monitoring** for cluster health
- **Uptime checks** for service availability
- **Custom dashboards** for operational overview

### Application Monitoring
- **Health endpoints** for application status
- **Performance metrics** via application instrumentation
- **Log aggregation** via Google Cloud Logging
- **Error tracking** and alerting

### Business Metrics
- **ML pipeline executions** via ZenML
- **Experiment tracking** via MLflow
- **Model performance** and drift monitoring
- **User activity** and system usage

## ⚖️ Scaling Operations

### Auto-Scaling Features
- **GKE Autopilot** automatic node management
- **Horizontal Pod Autoscaler** for applications
- **Vertical Pod Autoscaler** for resource optimization
- **Cloud SQL automatic storage scaling**

### Manual Scaling
```bash
# Scale application replicas
kubectl scale deployment zenml-server -n zenml --replicas=3

# Update resource requests/limits
kubectl patch deployment zenml-server -n zenml -p \
'{"spec":{"template":{"spec":{"containers":[{"name":"zenml-server","resources":{"requests":{"cpu":"1000m","memory":"2Gi"}}}]}}}}'
```

## 🔄 Backup & Recovery

### Automated Backups
- **Database backups** via Cloud SQL automated backups
- **Configuration backups** via Git version control
- **State backups** via Terraform state versioning
- **Application data** via regular exports

### Recovery Procedures
- **Point-in-time recovery** for database issues
- **Infrastructure recreation** via Terraform
- **Application redeployment** via ArgoCD
- **Data restoration** from backup storage

## 🛠️ Maintenance Operations

### Application Updates
```bash
# Update ZenML version
helm upgrade zenml-server oci://public.ecr.aws/zenml/zenml \
  --version 0.85.0 \
  -f custom-values.yaml \
  -n zenml

# Update ArgoCD
kubectl apply -n argocd -f \
https://raw.githubusercontent.com/argoproj/argo-cd/v2.9.0/manifests/install.yaml
```

### Infrastructure Updates
```bash
# Update Terraform modules
cd src/infra
terraform init -upgrade
terraform plan
terraform apply

# Update GKE cluster version
gcloud container clusters upgrade zenml-cluster \
  --region us-central1 \
  --cluster-version 1.28.0
```

## 🚨 Incident Response

### Alert Categories
- **Critical** - Service unavailable, data loss risk
- **Warning** - Performance degradation, approaching limits  
- **Info** - Planned maintenance, configuration changes

### Response Procedures
1. **Assess impact** - Determine scope and severity
2. **Immediate response** - Implement workarounds if possible
3. **Root cause analysis** - Identify underlying issues
4. **Resolution** - Apply permanent fixes
5. **Post-incident review** - Document lessons learned

### Common Issues and Solutions
```bash
# Pod stuck in pending
kubectl describe pod <pod-name> -n <namespace>
kubectl get events -n <namespace>

# Certificate not renewing
kubectl describe certificate <cert-name> -n <namespace>
kubectl logs -n cert-manager deployment/cert-manager

# Database connection issues
kubectl logs -n zenml deployment/zenml-server
gcloud sql operations list --instance=zenml-mysql
```

## 📈 Performance Optimization

### Resource Right-Sizing
- Monitor actual resource usage vs. requests/limits
- Adjust based on workload patterns
- Use Vertical Pod Autoscaler recommendations
- Regular review of cost vs. performance

### Database Optimization
- Monitor slow queries and optimize
- Review connection pooling settings
- Scale read replicas for read-heavy workloads
- Implement caching where appropriate

### Storage Optimization
- Implement lifecycle policies for old data
- Use appropriate storage classes
- Monitor and clean up unused volumes
- Compress and archive historical data

## 📋 Operational Checklists

### Pre-Deployment Checklist
- [ ] Infrastructure validated with `terraform plan`
- [ ] Backup procedures tested and verified
- [ ] Monitoring and alerting configured
- [ ] Security scanning completed
- [ ] Performance baselines established

### Post-Deployment Checklist
- [ ] All services healthy and accessible
- [ ] Certificates issued and valid
- [ ] Monitoring data flowing correctly
- [ ] Backup jobs running successfully
- [ ] Documentation updated

### Monthly Review Checklist
- [ ] Review cost and usage reports
- [ ] Check security updates and patches
- [ ] Test backup and recovery procedures
- [ ] Review and optimize resource allocation
- [ ] Update operational documentation

---

!!! info "Operational Excellence"
    Successful operations require proactive monitoring, regular maintenance, and well-defined procedures for both routine and emergency situations.

!!! tip "Automation First"
    Automate repetitive operational tasks where possible to reduce human error and improve efficiency.