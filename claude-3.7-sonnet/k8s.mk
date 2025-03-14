# k8s.mk - Kubernetes-related functionality
# This makefile provides Kubernetes manifests generation and deployment

# Kubernetes settings
K8S_MANIFESTS_DIR ?= $(BUILD_DIR)/manifests
KUSTOMIZE_DIR ?= kustomize

.PHONY: k8s pre-k8s main-k8s post-k8s kustomize run pre-run main-run post-run

# Add k8s and run targets to default if K8s is enabled
default: build image k8s run

# Create manifests directory
$(K8S_MANIFESTS_DIR):
	mkdir -p $@

# Extensible k8s target with pre/post hooks
k8s:
	$(MAKE) pre-k8s
	$(MAKE) main-k8s
	$(MAKE) post-k8s

# Extensible run target with pre/post hooks
run:
	$(MAKE) pre-run
	$(MAKE) main-run
	$(MAKE) post-run

# Default implementations for hook targets (do nothing)
post-k8s pre-run post-run:
	@:

# Pre-k8s default implementation
pre-k8s: | $(K8S_MANIFESTS_DIR)
	if [ -f "k8s/pyproject.toml" ]; then cd k8s && poetry install; fi

# Main k8s implementation
main-k8s: | $(K8S_MANIFESTS_DIR)
	cp -r k8s/raw $(K8S_MANIFESTS_DIR) || true
	if [ -f "k8s/pyproject.toml" ]; then \
		cd k8s && JSII_SILENCE_WARNING_UNTESTED_NODE_VERSION=1 CDK8S_OUTDIR=$(K8S_MANIFESTS_DIR) BUILD_DIR=$(BUILD_DIR) APP_VERSION=$(APP_VERSION) poetry run ./main.py; \
	fi

# Kustomize target
kustomize: pre-k8s
	cd k8s && rm -rf $(KUSTOMIZE_DIR)/* && mkdir -p $(KUSTOMIZE_DIR) && cp raw/* $(KUSTOMIZE_DIR)/. || true
	cd k8s && JSII_SILENCE_WARNING_UNTESTED_NODE_VERSION=1 CDK8S_OUTDIR=$(KUSTOMIZE_DIR) BUILD_DIR=$(KUSTOMIZE_DIR) APP_VERSION=$(APP_VERSION) poetry run ./main.py --kustomize

# Main run implementation
main-run: k8s
	kubectl apply -f $(K8S_MANIFESTS_DIR)/raw || true
	kubectl apply -f $(K8S_MANIFESTS_DIR)
