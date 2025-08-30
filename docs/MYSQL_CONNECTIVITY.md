# MySQL Database Connectivity Guide

## 🌐 **Network Architecture Overview**

Your MySQL database is configured for optimal connectivity with your Kubernetes cluster:

```
┌─────────────────────────────────────────────────────────────┐
│                        VPC Network                          │
│  ┌─────────────────┐    ┌─────────────────────────────────┐  │
│  │   GKE Cluster   │    │        Cloud SQL MySQL         │  │
│  │                 │    │                                 │  │
│  │ ┌─────────────┐ │    │  ┌─────────────────────────────┐ │  │
│  │ │    Nodes    │◄┼────┼──┤    Private IP: 10.x.x.x    │ │  │
│  │ │             │ │    │  │    Port: 3306               │ │  │
│  │ └─────────────┘ │    │  │    SSL: Required            │ │  │
│  │ ┌─────────────┐ │    │  └─────────────────────────────┘ │  │
│  │ │    Pods     │◄┼────┼──────────────────────────────────┤  │
│  │ │             │ │    │                                 │  │
│  │ └─────────────┘ │    └─────────────────────────────────┘  │
│  └─────────────────┘                                        │
└─────────────────────────────────────────────────────────────┘
```

## ✅ **Connectivity Requirements Met**

### 1. **Private Network Access**
- ✅ MySQL instance deployed in the same VPC as your GKE cluster
- ✅ Private Service Access connection established
- ✅ No public IP exposure (secure by default)

### 2. **Firewall Rules**
- ✅ Automatic firewall rules for GKE subnet access
- ✅ Port 3306 specifically allowed from cluster subnets

### 3. **SSL Security**
- ✅ SSL connections enforced by default with `ENCRYPTED_ONLY` mode
- ✅ Encrypted data in transit and at rest
- ✅ Google-managed certificates

## 🔧 **Configuration Details**

### **Network CIDR Ranges Authorized**
Your MySQL database automatically allows access from:
- **GKE Nodes Subnet**: Your primary cluster subnet
- **Pods Range**: Secondary IP range for pod IPs
- **Services Range**: Secondary IP range for service IPs

## 🧪 **Testing Connectivity**

### **Quick Test Commands**

1. **Network Connectivity**:
```bash
kubectl run test-mysql-network --image=busybox --rm -it --restart=Never -- ping MYSQL_PRIVATE_IP
```

2. **Port Connectivity**:
```bash
kubectl run test-mysql-port --image=busybox --rm -it --restart=Never -- telnet MYSQL_PRIVATE_IP 3306
```

3. **Database Connection**:
```bash
# Get password from Secret Manager
PASSWORD=$(gcloud secrets versions access latest --secret="PROJECT-zenml-db-password")

# Test connection
kubectl run test-mysql-auth --image=mysql:8.0 --rm -it --restart=Never -- \
  mysql -h MYSQL_PRIVATE_IP -u zenml -p$PASSWORD zenml
```

### **Automated Testing**
Run the provided connectivity test script:
```bash
chmod +x scripts/test-mysql-connectivity.sh
./scripts/test-mysql-connectivity.sh
```

## 🚀 **ZenML Integration**

### **Connection Configuration**
Your ZenML deployment can use these connection details:

```yaml
# ZenML Helm values.yaml
zenml:
  database:
    host: "MYSQL_PRIVATE_IP"          # From terraform output
    port: "3306"
    database: "zenml"
    username: "zenml"
    sslMode: "PREFERRED"
    
  # Use External Secrets to inject password
  existingSecret:
    name: "zenml-db-password"
    key: "password"
```

### **External Secrets Configuration**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: gcpsm-secret-store
spec:
  provider:
    gcpsm:
      projectId: "YOUR_PROJECT_ID"

---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: zenml-db-password
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: gcpsm-secret-store
    kind: SecretStore
  target:
    name: zenml-db-password
    creationPolicy: Owner
  data:
  - secretKey: password
    remoteRef:
      key: "PROJECT-zenml-db-password"
```

## 🔍 **Troubleshooting**

### **Common Issues & Solutions**

1. **Connection Timeout**
   - ✅ Verify GKE cluster and MySQL are in the same VPC
   - ✅ Check firewall rules allow port 3306
   - ✅ Confirm Private Service Access is established

2. **Access Denied**
   - ✅ Verify username and password from Secret Manager
   - ✅ Check SSL configuration matches requirements
   - ✅ Ensure database user has proper permissions

3. **SSL/TLS Issues**
   - ✅ ZenML should use `sslMode: "PREFERRED"`
   - ✅ Google Cloud SQL enforces SSL with `ENCRYPTED_ONLY` mode
   - ✅ No client certificates needed for standard connections

### **Verification Commands**

```bash
# Check terraform outputs
terraform output mysql

# List firewall rules
gcloud compute firewall-rules list --filter="name~mysql"

# Verify Private Service Access
gcloud services vpc-peerings list --network=VPC_NAME

# Check Secret Manager secrets
gcloud secrets list --filter="name~mysql OR name~zenml"
```

## 📊 **Monitoring & Maintenance**

### **Connection Monitoring**
- Monitor MySQL connections in Cloud SQL console
- Set up alerts for connection failures
- Track query performance and slow queries

### **Security Best Practices**
- ✅ Rotate database passwords regularly
- ✅ Monitor access logs
- ✅ Keep MySQL version updated
- ✅ Review firewall rules periodically

### **Backup Verification**
- ✅ Automated daily backups enabled
- ✅ Point-in-time recovery available (7 days)
- ✅ Test backup restoration procedures

## 🎯 **Ready for Production**

Your MySQL configuration is production-ready with:
- 🔒 **Security**: Private IP, SSL required, Secret Manager integration
- 🔄 **Reliability**: Automated backups, point-in-time recovery
- ⚡ **Performance**: Optimized database flags, proper instance sizing
- 🌐 **Connectivity**: Comprehensive firewall rules for GKE access
- 📊 **Observability**: Connection diagnostics and monitoring outputs

The database is fully prepared for ZenML deployment and will provide reliable, secure metadata storage for your MLOps pipeline!
