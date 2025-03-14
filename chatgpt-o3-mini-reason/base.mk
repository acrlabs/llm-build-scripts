# common/base.mk
#
# Usage:
#   In your project-specific Makefile, include this file:
#       include common/base.mk
#
# Provided targets:
#   build   - builds the project (delegates to _build)
#   test    - runs tests (delegates to _test)
#   lint    - runs linting (delegates to _lint)
#   cover   - computes code coverage (delegates to _cover)
#   verify  - runs test, lint, and cover
#   clean   - removes generated build artifacts (the .build/ directory)
#   default - meta target that by default runs build, verify, and conditionally image, k8s, run
#
# Optional targets (if enabled via variables):
#   image   - builds Docker images (if HAS_IMAGE is defined)
#   k8s     - generates Kubernetes manifests (if HAS_K8S is defined)
#   run     - deploys the app to Kubernetes (if HAS_K8S is defined)
#
# Environment detection:
#   If the CI variable is set, COVERAGE_MODE is “ci” (for machine‐readable output);
#   otherwise it is “local” (for human-readable reports).

# Directories for build artifacts and caches.
BUILD_DIR ?= .build
CACHE_DIR ?= .cache

# Environment detection for code coverage output.
ifdef CI
	COVERAGE_MODE = ci
else
	COVERAGE_MODE = local
endif

# Default meta-target.
.PHONY: default
default: meta-target

meta-target: build verify
ifdef HAS_IMAGE
	$(MAKE) image
endif
ifdef HAS_K8S
	$(MAKE) k8s run
endif

# Basic targets that call language‐ or project-specific implementations.
.PHONY: build test lint cover verify clean
build:
	@echo ">> [BASE] Running build..."
	$(MAKE) _build

test:
	@echo ">> [BASE] Running tests..."
	$(MAKE) _test

lint:
	@echo ">> [BASE] Running linting..."
	$(MAKE) _lint

cover:
	@echo ">> [BASE] Running coverage..."
	$(MAKE) _cover COVERAGE_MODE=$(COVERAGE_MODE)

verify: test lint cover

clean:
	@echo ">> [BASE] Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)

# Default (stub) implementations for delegated targets.
# Projects should override these with their own commands.
.PHONY: _build _test _lint _cover
_build:
	@echo ">> [BASE] _build: no instructions provided. Please override _build in your project Makefile."

_test:
	@echo ">> [BASE] _test: no instructions provided. Please override _test in your project Makefile."

_lint:
	@echo ">> [BASE] _lint: no instructions provided. Please override _lint in your project Makefile."

_cover:
	@echo ">> [BASE] _cover: no instructions provided. Please override _cover in your project Makefile."

# Optional Docker image target – available if HAS_IMAGE is defined.
ifdef HAS_IMAGE
.PHONY: image
image:
	@echo ">> [BASE] Building Docker image(s)..."
	$(MAKE) _image
endif

# Optional Kubernetes targets – available if HAS_K8S is defined.
ifdef HAS_K8S
.PHONY: k8s run
k8s:
	@echo ">> [BASE] Generating Kubernetes manifests..."
	$(MAKE) _k8s

run:
	@echo ">> [BASE] Deploying to Kubernetes..."
	$(MAKE) _run
endif
