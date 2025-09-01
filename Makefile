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
	kubectl apply -f src/k8s-cluster/cert-manager/cert-manager.yaml
	@echo "Waiting for cert-manager pods to be ready..."
	kubectl wait --namespace cert-manager --for=condition=ready pod --selector=app.kubernetes.io/name=cert-manager --timeout=120s
	kubectl wait --namespace cert-manager --for=condition=ready pod --selector=app.kubernetes.io/name=webhook --timeout=120s

	@echo "⚠️  Skipping ClusterIssuers for now (webhook issue)"
# 	kubectl apply -f src/k8s-cluster/cert-manager/cluster-issuers.yaml 
	@echo "Deploying NGINX Ingress Controller..."
	kubectl apply -f src/k8s-cluster/ingress-nginx/rbac.yaml
	kubectl apply -f src/k8s-cluster/ingress-nginx/controller.yaml
	kubectl apply -f src/k8s-cluster/ingress-nginx/service.yaml
	kubectl apply -f src/k8s-cluster/ingress-nginx/admission-webhook.yaml

	@echo "Waiting for NGINX Ingress to be ready..."
	kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s
	@echo "Deploying ZenML..."
	# kubectl apply -f src/k8s-cluster/zenml/

kube-cleanup:
	kubectl delete -f src/gke/

