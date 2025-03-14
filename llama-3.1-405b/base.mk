# Define the build directory
BUILD_DIR ?= $(shell pwd)/.build

# Define the default target
.DEFAULT_GOAL := build

# Define the verify target
.PHONY: verify
verify: test lint cover

# Define the build target
.PHONY: build
build: $(BUILD_DIR)
	@echo "Building..."

# Define the test target
.PHONY: test
test: $(BUILD_DIR)
	@echo "Testing..."

# Define the lint target
.PHONY: lint
lint: $(BUILD_DIR)
	@echo "Linting..."

# Define the cover target
.PHONY: cover
cover: $(BUILD_DIR)
	@echo "Computing code coverage..."

# Define the clean target
.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)

# Define the $(BUILD_DIR) target
$(BUILD_DIR):
	mkdir -p $@
