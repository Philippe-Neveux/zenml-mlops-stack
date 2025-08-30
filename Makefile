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
