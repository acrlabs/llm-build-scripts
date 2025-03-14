# base.mk

# Default environment (set CI=true in CI environments)
CI ?= false

# Standard directories
BUILD_DIR := .build
DOCKER_TAG_SCRIPT := scripts/docker_tag.sh

# Meta targets
.PHONY: default verify build test lint cover clean

default: build $(if $(filter image,$(MAKECMDGOALS)),image) $(if $(filter k8s,$(MAKECMDGOALS)),k8s)

verify: test lint cover

clean:
	rm -rf $(BUILD_DIR)

# Extensible targets
build::
	@echo "No build steps defined"

test::
	@echo "No tests defined"

lint::
	@echo "No linting defined"

cover::
	@echo "No coverage defined"

image::
	@echo "No Docker image defined"

k8s::
	@echo "No Kubernetes manifests defined"

run::
	@echo "No Kubernetes run defined"
