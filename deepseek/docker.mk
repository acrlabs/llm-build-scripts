# Docker image configuration
DOCKER_REGISTRY ?= localhost:5000
IMAGE_TAG ?= $(shell $(MAKEFILE_DIR)/docker_tag.sh)

ifdef ARTIFACTS_WITH_IMAGES
.PHONY: image

image: $(addprefix image-,$(ARTIFACTS_WITH_IMAGES))
	@echo "Built all Docker images"

image-%: $(BUILD_DIR)/%
	@echo "Building Docker image for $*"
	docker build -t "$(DOCKER_REGISTRY)/$*:$(IMAGE_TAG)" \
		-f "Dockerfile.$*" "$(BUILD_DIR)"
	docker push "$(DOCKER_REGISTRY)/$*:$(IMAGE_TAG)"
	echo "$(DOCKER_REGISTRY)/$*:$(IMAGE_TAG)" > "$(BUILD_DIR)/$*-image"

default: image
endif
