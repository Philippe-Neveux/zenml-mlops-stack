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

kube-apply:	connect-k8s-cluster
	@echo "Checking for terminating namespaces..."
	@echo "Deploying cert-manager..."
	kubectl apply -f src/k8s-cluster/cert-manager/01_namespace.yaml
	kubectl apply -f src/k8s-cluster/cert-manager/02_cert-manager.yaml
	@echo "Waiting for cert-manager pods to be ready..."
	kubectl wait --namespace cert-manager --for=condition=ready pod --selector=app.kubernetes.io/name=cert-manager --timeout=120s
	kubectl wait --namespace cert-manager --for=condition=ready pod --selector=app.kubernetes.io/name=webhook --timeout=120s
	
	@echo "Waiting for cert-manager webhook to be fully ready..."
	@sleep 30
	@echo "Deploying ClusterIssuers..."
	kubectl apply -f src/k8s-cluster/cert-manager/03_cluster-issuers.yaml || (echo "ClusterIssuer creation failed, trying without webhook validation..." && kubectl label namespace cert-manager cert-manager.io/disable-validation=true --overwrite && sleep 5 && kubectl apply -f src/k8s-cluster/cert-manager/03_cluster-issuers.yaml && kubectl label namespace cert-manager cert-manager.io/disable-validation-)
	
	@echo "Deploying NGINX Ingress Controller..."
	kubectl apply -f src/k8s-cluster/ingress-nginx/01_rbac.yaml
	kubectl apply -f src/k8s-cluster/ingress-nginx/02_controller.yaml
	kubectl apply -f src/k8s-cluster/ingress-nginx/03_services.yaml
	kubectl apply -f src/k8s-cluster/ingress-nginx/04_admission-webhook.yaml

	@echo "Waiting for NGINX Ingress to be ready..."
	kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s
	@echo "Deploying ZenML..."
	# kubectl apply -f src/k8s-cluster/zenml/

kube-cleanup:
	kubectl delete -f src/gke/

