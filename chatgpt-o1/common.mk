#######################################
# common.mk
#
# This file provides the shared logic for building, testing, linting,
# coverage, Docker image creation, and Kubernetes deployment across
# all language types. Individual projects can include language-specific
# mk files (rust.mk, golang.mk, python.mk) and selectively enable
# Docker or Kubernetes support.
#######################################

# .PHONY so that make doesn't look for actual files named "build", etc.
.PHONY: default verify build test lint cover clean release

# -----------------------------------------------------------------------
# Directory layout
# -----------------------------------------------------------------------
# All build artifacts and intermediates go under .build to keep the workspace clean.
# The language-specific mk file should place compiler artifacts, caches, etc. under .build/.
BUILD_DIR := .build

# If you want to differentiate local vs CI environment, define:
#  - CI=1 for the CI pipeline
#  - Otherwise local usage is assumed
# For example, cover might produce a CodeCov-friendly file in CI mode, and a textual
# report locally.
CI ?=

# -----------------------------------------------------------------------
# Meta targets
# -----------------------------------------------------------------------
# The "default" target is typically "build" but might also include
# "image" and/or "k8s" if those features are enabled in a project.
# The "verify" target ensures that test, lint, and coverage all run.
# Projects can override or extend these if needed.

## We’ll gather targets that should be part of "default" dynamically.
DEFAULT_TARGETS := build

## If a project wants the "image" target, it can set `DOCKER_ENABLED = 1`.
## If set, we append image to the DEFAULT_TARGETS.
ifneq ($(strip $(DOCKER_ENABLED)),)
DEFAULT_TARGETS += image
endif

## If a project wants the "k8s" or "run" targets, it can set `K8S_ENABLED = 1`.
## If set, we append k8s (and possibly run) to the DEFAULT_TARGETS.
ifneq ($(strip $(K8S_ENABLED)),)
DEFAULT_TARGETS += k8s
# In many projects, "run" is not necessarily always triggered by default,
# so you can decide whether to add it here or keep it separate.
endif

default: $(DEFAULT_TARGETS)

## The "verify" target typically runs test, lint, and coverage together
verify: test lint cover

# -----------------------------------------------------------------------
# Core build targets (must be defined; actual commands are delegated)
# -----------------------------------------------------------------------
build:
	@echo "[COMMON] Nothing to build by default. Include your language or custom logic."

test:
	@echo "[COMMON] Nothing to test by default. Include your language or custom logic."

lint:
	@echo "[COMMON] No lint step by default. Include your language or custom logic."

cover:
	@echo "[COMMON] No coverage step by default. Include your language or custom logic."

release:
	@echo "[COMMON] No release logic by default. Include your language or custom logic."

# -----------------------------------------------------------------------
# Docker and Kubernetes targets
# -----------------------------------------------------------------------
# If DOCKER_ENABLED=1, define how to build/push images, etc.
# If K8S_ENABLED=1, define how to build k8s manifests, run them, etc.

.PHONY: image k8s run
image:
ifneq ($(strip $(DOCKER_ENABLED)),)
	@echo "[COMMON] Building Docker image(s). Override this target or rely on language-specific rules."
else
	@echo "[COMMON] DOCKER_ENABLED not set. No images to build."
endif

k8s:
ifneq ($(strip $(K8S_ENABLED)),)
	@echo "[COMMON] Generating K8S manifests. Override this target or rely on extended logic."
else
	@echo "[COMMON] K8S_ENABLED not set. No k8s manifests generated."
endif

run:
ifneq ($(strip $(K8S_ENABLED)),)
	@echo "[COMMON] Deploying the app to Kubernetes. Override this target or rely on extended logic."
else
	@echo "[COMMON] K8S_ENABLED not set. Skipping run."
endif

# -----------------------------------------------------------------------
# Clean target
# -----------------------------------------------------------------------
clean:
	@echo "[COMMON] Removing '$(BUILD_DIR)' directory to clean all build artifacts."
	rm -rf $(BUILD_DIR)
