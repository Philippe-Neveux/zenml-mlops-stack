# MySQL Module for ZenML

This module creates a Google Cloud SQL MySQL instance optimized for ZenML metadata storage.

## Features

- **Cloud SQL MySQL Instance**: Fully managed MySQL database
- **Private IP**: Secure connection within VPC
- **Automated Backups**: Point-in-time recovery enabled
- **Secret Management**: Database credentials stored in Secret Manager
- **ZenML Optimized**: Pre-configured for ZenML requirements

## Resources Created

- `google_sql_database_instance.zenml_mysql` - Cloud SQL MySQL instance
- `google_sql_database.zenml` - ZenML database
- `google_sql_user.root` - MySQL root user
- `google_sql_user.zenml` - ZenML application user
- `google_secret_manager_secret.*` - Database credentials in Secret Manager
- `random_password.*` - Secure random passwords

## Usage

```hcl
module "mysql" {
  source = "./modules/mysql"

  project_name = var.project_name
  project_id   = var.project_id
  region       = var.region

  private_network_id = module.vpc.network_id
  
  labels = var.common_labels

  depends_on = [module.project_services]
}
```

## Configuration

### Instance Sizing
- **Default Tier**: `db-n1-standard-2` (2 vCPUs, 7.5GB RAM)
- **Disk**: 20GB SSD with auto-resize up to 100GB
- **Availability**: ZONAL (can be changed to REGIONAL for HA)

### Security
- **Private IP Only**: Instance is not accessible from the internet
- **VPC Integration**: Connects securely to your GKE cluster
- **SSL Enforced**: ENCRYPTED_ONLY mode for secure connections
- **Encrypted**: Data encryption at rest and in transit
- **Secret Manager**: All credentials stored securely

### Backup & Recovery
- **Automated Backups**: Daily backups at 03:00 UTC
- **Point-in-Time Recovery**: 7-day transaction log retention
- **Backup Retention**: 7 automated backups retained

### Database Configuration
- **Database**: `zenml` (UTF8MB4 with Unicode collation)
- **Users**: `root` and `zenml` with secure random passwords
- **Optimization**: Connection limits, query logging, and ACID compliance tuned for ZenML
- **SSL Mode**: ENCRYPTED_ONLY for secure connections

## Outputs

| Output | Description |
|--------|-------------|
| `mysql_instance_name` | Cloud SQL instance name |
| `mysql_instance_private_ip` | Private IP address |
| `zenml_database_url` | Complete database connection URL |
| `zenml_database_connection_info` | Connection details for applications |
| `zenml_helm_database_config` | Database config formatted for ZenML Helm chart |
| `zenml_database_secret_refs` | Secret Manager references for external secrets |
| `*_secret_id` | Secret Manager secret IDs for credentials |

## ZenML Integration

The database is configured specifically for ZenML:

```bash
# Database URL format for ZenML
mysql://zenml:password@private-ip:3306/zenml
```

Connection details are automatically stored in Secret Manager and can be retrieved by ZenML deployments.

## Requirements

- Google Cloud SQL API enabled
- VPC with private service access configured
- Secret Manager API enabled

## Security Notes

- Database is only accessible via private IP within the VPC
- All passwords are randomly generated and stored in Secret Manager
- Deletion protection is enabled by default
- Regular automated backups with point-in-time recovery
