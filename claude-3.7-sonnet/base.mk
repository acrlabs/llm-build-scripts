# base.mk - Core build system for all projects
# This makefile provides the foundation of the build system and is included by all projects

# Build directory for all artifacts and intermediate files
BUILD_DIR ?= $(shell pwd)/.build

# Directory where these makefiles are stored
MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# Define all phony targets
.PHONY: default verify build test lint cover clean
.PHONY: pre-build main-build post-build 
.PHONY: pre-test main-test post-test
.PHONY: pre-lint main-lint post-lint
.PHONY: pre-cover main-cover post-cover
.PHONY: pre-release main-release post-release
.PHONY: pre-publish main-publish post-publish

# Default goal is to build
.DEFAULT_GOAL = default

# Default implementations for hook targets (do nothing)
pre-build post-build pre-test post-test pre-lint post-lint pre-cover post-cover pre-release post-release pre-publish post-publish:
	@:

# Create build directory
$(BUILD_DIR):
	mkdir -p $@

# Default target builds the project
default: build

# Verify runs tests, linting, and coverage
verify: test lint cover

# Extensible build target with pre/post hooks
build: | $(BUILD_DIR)
	$(MAKE) pre-build
	$(MAKE) main-build
	$(MAKE) post-build

# Extensible test target with pre/post hooks
test:
	$(MAKE) pre-test
	$(MAKE) main-test
	$(MAKE) post-test

# Extensible lint target with pre/post hooks
lint:
	$(MAKE) pre-lint
	$(MAKE) main-lint
	$(MAKE) post-lint

# Extensible cover target with pre/post hooks 
cover:
	$(MAKE) pre-cover
	$(MAKE) main-cover
	$(MAKE) post-cover

# Extensible release target with pre/post hooks
release:
	$(MAKE) pre-release
	$(MAKE) main-release
	$(MAKE) post-release

# Extensible publish target with pre/post hooks
publish:
	$(MAKE) pre-publish
	$(MAKE) main-publish
	$(MAKE) post-publish

# Clean target removes build directory
clean:
	rm -rf $(BUILD_DIR)

# Setup target for development environment
setup::
	pre-commit install

# Include language-specific Makefile if defined
ifdef LANGUAGE
include $(MAKEFILE_DIR)/$(LANGUAGE).mk
endif

# Include feature-specific Makefiles if enabled
ifdef ENABLE_DOCKER
include $(MAKEFILE_DIR)/docker.mk
endif

ifdef ENABLE_K8S
include $(MAKEFILE_DIR)/k8s.mk
endif
