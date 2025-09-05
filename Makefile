tf-init:
	echo "Initializing Terraform..."
	cd src/infra && terraform init

tf-validate: tf-init
	echo "Validating Terraform configuration..."
	cd src/infra && terraform validate

tf-plan: tf-init tf-validate
	echo "Planning Terraform changes..."
	cd src/infra && terraform plan -out tfplan

tf-apply: tf-plan
	echo "Applying Terraform changes..."
	cd src/infra && terraform apply tfplan

#######
# MySQL
test-mysql-connection:
	echo "Connecting to MySQL..."
	./scripts/test-mysql-connectivity.sh

# Kubernetes
connect-k8s-cluster:
	echo "Connecting to Kubernetes cluster..."
	gcloud container clusters get-credentials zenml --region australia-southeast1 --project zenml-470505

helm-update:
	helm repo update

NGINX_INGRESS_CONTROLLER_VERSION := 4.13.2

# !!! No more used because its handled by argocd !!!
helm-install-nginx-ingress: helm-update
	@echo "Installing ingress-nginx resources with helm..."
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm install nginx-ingress ingress-nginx/ingress-nginx \
		--namespace nginx-ingress \
		--create-namespace \
		--version $(NGINX_INGRESS_CONTROLLER_VERSION)
	@echo "ingress-nginx resources deployed !!!"

CERT_MANAGER_VERSION := v1.18.2

# !!! No more used because its handled by argocd !!!
helm-install-cert-manager: helm-update
	@echo "Installing cert-manager resources..."
	helm repo add jetstack https://charts.jetstack.io
	helm install cert-manager jetstack/cert-manager \
		--namespace cert-manager \
		--create-namespace \
		--set installCRDs=true \
		--set global.leaderElection.namespace=cert-manager \
		--version $(CERT_MANAGER_VERSION)
	@echo "cert-manager resources deployed !!!"


# !!! No more used because its handled by argocd !!!
kube-apply:	connect-k8s-cluster helm-install-cert-manager helm-install-nginx-ingress
	@echo "Waiting for cert-manager pods to be ready..."
	kubectl wait --namespace cert-manager --for=condition=ready pod --selector=app.kubernetes.io/name=cert-manager --timeout=120s
	kubectl wait --namespace cert-manager --for=condition=ready pod --selector=app.kubernetes.io/name=cainjector --timeout=120s
	kubectl wait --namespace cert-manager --for=condition=ready pod --selector=app.kubernetes.io/name=webhook --timeout=120s

	@echo "Waiting for cert-manager webhook to be fully ready and CA bundle injection..."
	@sleep 60
	@echo "Deploying ClusterIssuers..."
	kubectl apply -f src/k8s-cluster/cert-manager/cluster-issuers.yaml

kube-cleanup:
	kubectl delete -f src/k8s-cluster/


###############
# ZenML
ZENML_VERSION := 0.84.3

zenml-get-helm-chart:
	@echo "Getting ZenML Helm chart..."
	cd src/ && helm pull oci://public.ecr.aws/zenml/zenml --version $(ZENML_VERSION) --untar

zenml-deploy:
	cd src/zenml && helm -n zenml install zenml-server . \
		--create-namespace \
		--values custom-values.yaml

zenml-login:
	@echo "Logging into ZenML..."
	uv run zenml login https://zenml.34.40.173.65.nip.io

###############
# Run pipelines
run-process: zenml-login
	@echo "Running training pipeline..."
	uv run src/zenml_mlops_stack/main.py

run-training: zenml-login
	@echo "Running training pipeline..."
	uv run src/zenml_mlops_stack/train.py


###############
# ArgoCD setup
argocd-install: connect-k8s-cluster
	@echo "Installing ArgoCD..."
	kubectl create namespace argocd
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

argocd-cli:
	@echo "Installing ArgoCD CLI..."
	brew install argocd

argocd-setup-lb: connect-k8s-cluster
	@echo "Setting up ArgoCD LoadBalancer..."
	kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
	sleep 60
	kubectl get svc argocd-server -n argocd -o=jsonpath='{.status.loadBalancer.ingress[0].ip}'

argocd-get-password:
	@echo "ArgoCD admin password:"
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

argocd-get-external-ip:
	@echo "ArgoCD External IP:"
	@kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

argocd-access-info:
	@echo "=== ArgoCD Access Information ==="
	@echo "External IP: $$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
	@echo "URL: https://$$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
	@echo "Username: admin"
	@echo "Password: $$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
	@echo "=================================="

argocd-login-cli:
	@echo "Logging into ArgoCD CLI..."
	@ARGOCD_SERVER=$$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}') && \
	ARGOCD_PASSWORD=$$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d) && \
	argocd login $$ARGOCD_SERVER --username admin --password $$ARGOCD_PASSWORD --insecure

##############################
# ArgoCD Applications

argocd-app-external-secrets: connect-k8s-cluster
	@echo "Deploying external-secrets-operator via ArgoCD..."
	kubectl apply -f src/argocd-apps/external-secrets-operator.yaml

argocd-app-nginx-ingress: connect-k8s-cluster
	@echo "Deploying nginx-ingress via ArgoCD..."
	kubectl apply -f src/argocd-apps/nginx-ingress.yaml

argocd-app-cert-manager: connect-k8s-cluster
	@echo "Deploying cert-manager via ArgoCD..."
	kubectl apply -f src/argocd-apps/cert-manager.yaml

argocd-app-cluster-issuers: connect-k8s-cluster
	@echo "Deploying cluster-issuers via ArgoCD..."
	kubectl apply -f src/argocd-apps/cluster-issuers.yaml

argocd-app-zenml-secret-store: connect-k8s-cluster
	@echo "Deploying zenml-secret-store via ArgoCD..."
	kubectl apply -f src/argocd-apps/zenml-secret-store.yaml

argocd-app-zenml-external-secrets: connect-k8s-cluster
	@echo "Deploying zenml-external-secrets via ArgoCD..."
	kubectl apply -f src/argocd-apps/zenml-external-secrets.yaml

argocd-app-zenml-server: connect-k8s-cluster
	@echo "Deploying zenml-server via ArgoCD..."
	kubectl apply -f src/argocd-apps/zenml-server.yaml

argocd-apps-deploy-all: argocd-app-external-secrets argocd-app-zenml-secret-store argocd-app-cert-manager argocd-app-cluster-issuers argocd-app-zenml-external-secrets argocd-app-nginx-ingress argocd-app-zenml-server
	@echo "All ArgoCD applications deployed with proper sync wave ordering!"

check-gcp-secrets:
	@echo "🔍 Checking GCP Secret Manager secrets..."
	gcloud secrets list | grep zenml || echo "No zenml secrets found in GCP Secret Manager"
