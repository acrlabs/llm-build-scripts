# Define the Kubernetes manifest target
.PHONY: k8s
k8s: $(BUILD_DIR)
	@echo "Generating Kubernetes manifests..."
	$(eval K8S_MANIFESTS_DIR := $(BUILD_DIR)/manifests)
	mkdir -p $(K8S_MANIFESTS_DIR)
	cp -r k8s/raw $(K8S_MANIFESTS_DIR) || true
	if [ -f "k8s/pyproject.toml" ]; then \
	  	cd k8s && JSII_SILENCE_WARNING_UNTESTED_NODE_VERSION=1 CDK8S_OUTDIR=$(K8S_MANIFESTS_DIR) BUILD_DIR=$(BUILD_DIR) poetry run ./main.py; \
	fi

# Define the Kubernetes deploy target
.PHONY: deploy
deploy: k8s
	@echo "Deploying to Kubernetes..."
	kubectl apply -f $(K8S_MANIFESTS_DIR)/raw || true
	kubectl apply -f $(K8S_MANIFESTS_DIR)
