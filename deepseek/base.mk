# Core build configuration
BUILD_DIR ?= $(shell pwd)/.build
COVERAGE_DIR ?= $(BUILD_DIR)/coverage
MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# Core targets
.PHONY: default verify build test lint cover clean

default: build
verify: test lint cover
clean:
	rm -rf "$(BUILD_DIR)"

# Target hooks for extensibility
pre-build:
do-build: pre-build
post-build: do-build
build: post-build

pre-test:
do-test: pre-test
post-test: do-test
test: post-test

pre-lint:
do-lint: pre-lint
post-lint: do-lint
lint: post-lint

pre-cover:
do-cover: pre-cover
post-cover: do-cover
cover: post-cover

# Include optional modules
-include $(MAKEFILE_DIR)/docker.mk
-include $(MAKEFILE_DIR)/k8s.mk
-include $(MAKEFILE_DIR)/lang-*.mk
