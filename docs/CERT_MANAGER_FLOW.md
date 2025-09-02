# cert-manager Certificate Flow

## 1. User Creates Ingress with TLS
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - myapp.example.com
    secretName: myapp-tls-secret
```

## 2. cert-manager Detects the Ingress
- Ingress controller watches all Ingress resources
- Sees `cert-manager.io/cluster-issuer` annotation
- Checks if `myapp-tls-secret` exists

## 3. Certificate Resource Created
cert-manager automatically creates:
```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: myapp-certificate
spec:
  secretName: myapp-tls-secret
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - myapp.example.com
```

## 4. ACME Challenge Process
1. **Order Creation**: cert-manager creates an ACME Order with Let's Encrypt
2. **Challenge Setup**: Creates HTTP-01 challenge
3. **Temporary Ingress**: Creates temporary route for `/.well-known/acme-challenge/`
4. **Let's Encrypt Validation**: LE checks if you control the domain
5. **Certificate Issuance**: LE issues the certificate if validation passes

## 5. Certificate Storage
- Certificate stored as Kubernetes Secret
- Secret contains: private key, certificate, CA bundle
- NGINX Ingress automatically uses the secret for TLS termination
