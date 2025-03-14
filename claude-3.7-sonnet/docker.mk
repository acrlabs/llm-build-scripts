# docker.mk - Docker-related functionality
# This makefile provides Docker image building targets

# Docker settings
DOCKER_REGISTRY ?= localhost:5000
DOCKER_TAG = $(shell $(MAKEFILE_DIR)/docker_tag.sh)

# Add image target to default if Docker is enabled
default: build image

# Define image targets for each artifact with an image
IMAGE_ARTIFACTS ?= $(ARTIFACTS)
IMAGE_TARGETS = $(addprefix images/Dockerfile.,$(IMAGE_ARTIFACTS))

.PHONY: image pre-image main-image post-image $(IMAGE_TARGETS)

# Extensible image target with pre/post hooks
image:
	$(MAKE) pre-image
	$(MAKE) main-image
	$(MAKE) post-image

# Default implementations for hook targets (do nothing)
pre-image post-image:
	@:

# Main image build implementation
main-image: $(IMAGE_TARGETS)

# Image targets for each artifact
$(IMAGE_TARGETS):
	PROJECT_NAME=$(subst images/Dockerfile.,,$@) && \
		IMAGE_NAME=$(DOCKER_REGISTRY)/$$PROJECT_NAME:$(DOCKER_TAG) && \
		docker build $(BUILD_DIR) -f $@ -t $$IMAGE_NAME && \
		docker push $$IMAGE_NAME && \
		printf "$$IMAGE_NAME" > $(BUILD_DIR)/$${PROJECT_NAME}-image
