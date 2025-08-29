# GKE Autopilot Module

This module creates a Google Kubernetes Engine (GKE) Autopilot cluster optimized for MLOps workloads.

## What is GKE Autopilot?

GKE Autopilot is Google's fully managed Kubernetes service that:
- **Automatically manages nodes**: No need to configure, manage, or scale node pools
- **Built-in security**: Hardened nodes with automatic security updates
- **Cost optimization**: Pay only for the CPU, memory, and storage your pods use
- **Simplified operations**: Google manages the underlying infrastructure
- **Best practices by default**: Security, networking, and scalability are pre-configured

## Key Features

### Automatic Node Management
- Google automatically provisions and manages nodes based on your workload requirements
- Nodes are automatically upgraded and patched
- No need to configure node pools, machine types, or scaling parameters

### Enhanced Security
- Workload Identity enabled by default for secure pod-to-GCP service authentication
- Shielded GKE nodes with secure boot and integrity monitoring
- Private nodes by default (configurable)
- Network policies and binary authorization support

### MLOps Optimizations
- Seamless integration with Google Cloud ML services
- Automatic scaling for training and inference workloads
- Built-in support for GPUs (when available)
- Integration with Artifact Registry and Container Registry

## Configuration

### Required Variables
- `project_name`: Name of the project
- `project_id`: Google Cloud Project ID
- `region`: Google Cloud region
- `network_name`: VPC network name
- `subnet_name`: Subnet name

### Optional Variables
- `cluster_version`: Kubernetes version prefix (default: "1.28")
- `enable_private_nodes`: Enable private nodes (default: true)
- `enable_private_endpoint`: Enable private endpoint (default: false)
- `master_ipv4_cidr_block`: CIDR for master network (default: "172.16.0.0/28")
- `master_authorized_networks`: Authorized networks for cluster access
- `enable_binary_authorization`: Enable binary authorization (default: false)
- `release_channel`: Update channel - RAPID, REGULAR, or STABLE (default: "REGULAR")
- `labels`: Resource labels

## Usage

```hcl
module "gke" {
  source = "./modules/gke"

  project_name = "my-mlops-project"
  project_id   = "my-gcp-project-id"
  region       = "us-central1"
  
  network_name = module.vpc.network_name
  subnet_name  = module.vpc.subnet_name
  
  enable_private_nodes    = true
  enable_private_endpoint = false
  release_channel         = "REGULAR"
  
  labels = {
    environment = "production"
    team        = "mlops"
  }
}
```

## Outputs

- `cluster_name`: Name of the GKE cluster
- `cluster_endpoint`: Cluster endpoint for kubectl access
- `cluster_ca_certificate`: CA certificate for cluster authentication
- `workload_identity_pool`: Workload Identity pool for service authentication
- `autopilot_enabled`: Confirmation that Autopilot is enabled

## Migration from Standard GKE

When migrating from a standard GKE cluster to Autopilot:

1. **Node Pools**: Removed - Autopilot manages nodes automatically
2. **Service Accounts**: Removed - Autopilot uses Google-managed service accounts
3. **Addons**: Simplified - Many addons are enabled by default in Autopilot
4. **Network Policy**: Built-in - Network segmentation is managed by Google
5. **Workload Identity**: Always enabled - No need for conditional configuration

## Autopilot Limitations

- Limited customization of node configuration
- Some Kubernetes features may be restricted for security
- Certain DaemonSets and privileged containers may not be supported
- Node-level access is not available

## Cost Benefits

With Autopilot, you pay only for:
- CPU and memory resources requested by your pods
- Storage attached to your workloads
- Network egress

This typically results in 20-50% cost savings compared to standard GKE clusters.

## Best Practices for MLOps

1. **Resource Requests**: Always specify CPU and memory requests for ML workloads
2. **Storage**: Use persistent volumes for model artifacts and datasets
3. **Workload Identity**: Leverage for secure access to GCP ML services
4. **Horizontal Pod Autoscaling**: Configure HPA for inference services
5. **Binary Authorization**: Enable for production environments to ensure container security
