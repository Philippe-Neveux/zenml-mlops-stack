# DNS Module

This module manages DNS records in Google Cloud DNS for the ZenML infrastructure.

## Features

- Creates a Cloud DNS managed zone for your domain
- Sets up DNS records for ZenML services
- Configures wildcard records for additional services
- Enables DNSSEC for security

## Records Created

- `zenml.yourdomain.com` - Points to the ingress IP
- `yourdomain.com` - Root domain points to ingress IP
- `*.yourdomain.com` - Wildcard for additional services

## Usage

This module is automatically included when `domain_name` is provided in the main configuration.

## DNS Setup

After applying this module, you'll need to update your domain registrar to use Google Cloud DNS name servers:

```bash
# Get the name servers
terraform output -json | jq -r '.dns_name_servers.value[]'

# Update your domain registrar to use these name servers
```

## Requirements

- A registered domain name
- Access to update your domain's name servers at the registrar

## Note

If you don't have a domain, leave `domain_name` empty and use nip.io for testing:
- `zenml.YOUR_IP.nip.io`
