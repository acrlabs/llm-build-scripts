# Kubernetes configuration
K8S_MANIFESTS_DIR ?= $(BUILD_DIR)/manifests

ifdef HAS_K8S
.PHONY: k8s run

k8s:
	mkdir -p "$(K8S_MANIFESTS_DIR)"
	@echo "Generating Kubernetes manifests..."

run: image k8s
	kubectl apply -f "$(K8S_MANIFESTS_DIR)"

default: run
endif
