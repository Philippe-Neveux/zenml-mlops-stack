# Getting Started

Welcome to the ZenML MLOps Stack! This section will guide you through the complete setup process, from preparing your environment to accessing your deployed services.

## 📋 Overview

The deployment process consists of these key steps:

1. **[Prerequisites](prerequisites.md)** - Set up your Google Cloud environment and install required tools
2. **[Quick Start](quick-start.md)** - Deploy your complete MLOps stack

## 🎯 Deployment Options

### Quick Start (30 minutes)
Perfect for evaluation and testing:
- Minimal configuration required
- Uses default settings
- nip.io domains for easy access
- Single-zone deployment

### Production Customization
The Quick Start guide includes options for production features:
- Custom domain configuration (optional)
- HTTPS with automatic certificates
- Production-grade security settings
- Built-in monitoring and backup

## 🔧 What You'll Deploy

By the end of this guide, you'll have:

- ✅ **GKE Autopilot Cluster** - Fully managed Kubernetes
- ✅ **Cloud SQL MySQL** - Managed database for metadata
- ✅ **ZenML Server** - ML pipeline orchestration
- ✅ **MLflow Server** - Experiment tracking and model registry
- ✅ **ArgoCD** - GitOps continuous deployment
- ✅ **HTTPS Access** - Secure access with automatic certificates

## 🚀 Ready to Start?

Ready to get started?

[Quick Start Guide](quick-start.md){ .md-button .md-button--primary }

---

!!! tip "First Time?"
    If this is your first time deploying infrastructure on Google Cloud, we recommend starting with the [Prerequisites](prerequisites.md) to ensure your environment is properly configured.