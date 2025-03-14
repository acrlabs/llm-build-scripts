# Define the Docker image target
.PHONY: image
image: $(BUILD_DIR)
	@echo "Building Docker image..."
	$(eval IMAGE_NAME := $(DOCKER_REGISTRY)/$(PROJECT_NAME):$(IMAGE_TAG))
	docker build $(BUILD_DIR) -f $(DOCKERFILE) -t $(IMAGE_NAME)
	docker push $(IMAGE_NAME)
	printf "$(IMAGE_NAME)" > $(BUILD_DIR)/image-name

# Define the Docker run target
.PHONY: run
run: image
	@echo "Running Docker container..."
	docker run -it --rm $(IMAGE_NAME)
