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

helm-install-nginx-ingress: helm-update
	@echo "Installing ingress-nginx resources with helm..."
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm install nginx-ingress ingress-nginx/ingress-nginx \
		--namespace nginx-ingress \
		--create-namespace \
		--version $(NGINX_INGRESS_CONTROLLER_VERSION)
	@echo "ingress-nginx resources deployed !!!"

CERT_MANAGER_VERSION := v1.18.2

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


kube-apply:	connect-k8s-cluster helm-install-cert-manager helm-install-nginx-ingress
	@echo "Waiting for cert-manager pods to be ready..."
	kubectl wait --namespace cert-manager --for=condition=ready pod --selector=app.kubernetes.io/name=cert-manager --timeout=120s
	kubectl wait --namespace cert-manager --for=condition=ready pod --selector=app.kubernetes.io/name=cainjector --timeout=120s
	kubectl wait --namespace cert-manager --for=condition=ready pod --selector=app.kubernetes.io/name=webhook --timeout=120s

	@echo "Waiting for cert-manager webhook to be fully ready and CA bundle injection..."
	@sleep 60
	@echo "Deploying ClusterIssuers..."
	kubectl apply -f src/k8s-cluster/cert-manager/cluster-issuers.yaml
	
	@echo "Waiting for NGINX Ingress to be ready..."
	kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s
# 	@echo "Deploying ZenML..."
# 	kubectl apply -f src/k8s-cluster/zenml/

kube-cleanup:
	kubectl delete -f src/k8s-cluster/

ZENML_VERSION := 0.84.3

# ZenML
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

# Run pipelines
run-process: zenml-login
	@echo "Running training pipeline..."
	uv run src/zenml_mlops_stack/main.py

# Run pipelines
run-training: zenml-login
	@echo "Running training pipeline..."
	uv run src/zenml_mlops_stack/train.py