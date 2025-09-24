# Troubleshooting

Having issues with your ZenML MLOps stack? This section provides comprehensive troubleshooting guides and solutions for common problems.

## 🔍 Quick Diagnostics

### Health Check Commands

```bash
# Check overall cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# Check ArgoCD applications
kubectl get applications -n argocd

# Check ingress and certificates
kubectl get ingress,certificates --all-namespaces

# Check service endpoints
kubectl get svc --all-namespaces
```

## 🔧 Debug Tools

### Essential Commands

```bash
# Get detailed information about resources
kubectl describe <resource-type> <resource-name> -n <namespace>

# Check logs
kubectl logs <pod-name> -n <namespace> -f

# Check events
kubectl get events -n <namespace> --sort-by=.metadata.creationTimestamp

# Port forward for debugging
kubectl port-forward svc/<service-name> <local-port>:<service-port> -n <namespace>
```

### ArgoCD Debugging

```bash
# Check application status
kubectl describe application <app-name> -n argocd

# View ArgoCD logs
kubectl logs -n argocd deployment/argocd-application-controller
kubectl logs -n argocd deployment/argocd-server
```

### Certificate Debugging

```bash
# Check certificate status
kubectl get certificates --all-namespaces
kubectl describe certificate <cert-name> -n <namespace>

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager -f

# Check certificate requests and challenges
kubectl get certificaterequests,challenges --all-namespaces
```

## 🆘 Getting Help

### Before Asking for Help

1. **Check this documentation** - Most issues are covered here
2. **Gather information**:
   ```bash
   # Basic cluster info
   kubectl cluster-info
   kubectl get nodes
   kubectl get pods --all-namespaces
   
   # Application status
   kubectl get applications -n argocd
   kubectl get ingress --all-namespaces
   kubectl get certificates --all-namespaces
   ```

3. **Check logs** for error messages
4. **Search existing issues** on GitHub

### Getting Support

- **GitHub Issues**: [Report bugs and request features](https://github.com/Philippe-Neveux/zenml-mlops-stack/issues)
- **ZenML Community**: [ZenML Discord](https://zenml.io/slack-invite/)
- **ArgoCD Community**: [ArgoCD Slack](https://argoproj.github.io/community/join-slack)

### Providing Information

When reporting issues, include:

- **Environment details**: GCP region, Kubernetes version, etc.
- **Error messages**: Complete error logs
- **Steps to reproduce**: What you did before the issue occurred
- **Resource status**: Output of diagnostic commands above

---

!!! tip "Prevention is Better Than Cure"
    Many issues can be prevented by following our deployment guides carefully and ensuring all prerequisites are met.

!!! info "Still Stuck?"
    If you can't find a solution here, don't hesitate to open an issue on GitHub with detailed information about your problem.