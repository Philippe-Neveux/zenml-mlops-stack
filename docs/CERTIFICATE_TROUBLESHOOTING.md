# Check Certificate Status and Troubleshooting Guide

## Check which issuer you're using

```bash
# List all certificates
kubectl get certificates -A

# Check certificate details
kubectl describe certificate zenml-tls -n zenml

# Check certificate issuer
kubectl get certificate zenml-tls -n zenml -o yaml | grep issuer
```

## Troubleshooting Commands

### Check cert-manager logs
```bash
kubectl logs -n cert-manager deployment/cert-manager -f
```

### Check certificate requests
```bash
# List certificate requests
kubectl get certificaterequests -n zenml

# Check specific request
kubectl describe certificaterequest CERT_REQUEST_NAME -n zenml
```

### Check certificate challenges
```bash
# List challenges (during validation)
kubectl get challenges -A

# Check specific challenge
kubectl describe challenge CHALLENGE_NAME -n zenml
```

### Force certificate renewal
```bash
# Delete the certificate to force renewal
kubectl delete certificate zenml-tls -n zenml

# Check if new certificate is being issued
kubectl get certificaterequests -n zenml -w
```

## Certificate Status Examples

### ✅ Working Certificate (Production)
```yaml
status:
  conditions:
  - type: Ready
    status: "True"
    reason: Ready
    message: Certificate is up to date and has not expired
  notAfter: "2025-11-29T10:30:45Z"
```

### ⚠️ Staging Certificate (Testing)
```yaml
status:
  conditions:
  - type: Ready
    status: "True" 
    reason: Ready
    message: Certificate is up to date and has not expired
  # Note: Browser will show "Not Secure" but certificate works
```

### ❌ Failed Certificate
```yaml
status:
  conditions:
  - type: Ready
    status: "False"
    reason: Failed
    message: "Failed to finalize order: acme: error: 400..."
```

## Common Issues and Solutions

### 1. DNS Not Resolving
```bash
# Test DNS resolution
nslookup zenml.yourdomain.com
dig +short zenml.yourdomain.com

# Should return your ingress IP
```

### 2. Rate Limit Hit
```bash
# Check for rate limit errors in cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager | grep -i "rate limit"

# Solution: Wait or use staging issuer
```

### 3. Domain Validation Failed
```bash
# Check challenge details
kubectl get challenges -A
kubectl describe challenge CHALLENGE_NAME -n zenml

# Common causes:
# - DNS not pointing to correct IP
# - Firewall blocking port 80
# - Ingress not routing /.well-known/acme-challenge correctly
```

### 4. Certificate Not Appearing in Browser
```bash
# Check if certificate is actually ready
kubectl get certificate zenml-tls -n zenml

# Check ingress is using the certificate
kubectl describe ingress zenml-server -n zenml
```

## Migration from Staging to Production

### 1. Verify staging works
```bash
# Access your site (ignore browser warning)
curl -k https://zenml.yourdomain.com

# Should return your application
```

### 2. Update ingress to use production issuer
```yaml
metadata:
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"  # Changed from staging
spec:
  tls:
  - hosts: [zenml.yourdomain.com]
    secretName: zenml-tls  # Use different secret name than staging
```

### 3. Apply and wait
```bash
kubectl apply -f your-ingress.yaml

# Watch certificate creation
kubectl get certificates -n zenml -w
```

### 4. Verify production certificate
```bash
# Should show green padlock in browser
# Or check with curl:
curl -I https://zenml.yourdomain.com
```
