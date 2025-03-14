#######################################
# rust.mk
#
# Language-specific rules for Rust projects.
# This file relies on variables and meta-targets from common.mk.
# Include it *after* including common.mk in your project Makefile.
#######################################

# PHONY targets for Rust
.PHONY: rust-build rust-test rust-lint rust-cover rust-release rust-publish

# Build artifacts will go under .build/rust-target. We set cargo's target-dir:
CARGO_TARGET_DIR := $(BUILD_DIR)/rust-target

# You can define your Rust build artifacts in a variable:
#   RUST_CRATES = "crate1 crate2"
# Then you'd specify how to build them below. For simple projects, you might
# just have one crate in the current directory.

rust-build:
	@echo "[RUST] Building Rust crates..."
	cargo build --target-dir $(CARGO_TARGET_DIR) $(CARGO_FLAGS)
	@echo "[RUST] Done building."

# Test uses the same target-dir to preserve caching
rust-test:
	@echo "[RUST] Running tests..."
	cargo test --target-dir $(CARGO_TARGET_DIR) $(CARGO_FLAGS)
	@echo "[RUST] Tests complete."

# For linting, we typically run cargo clippy
rust-lint:
	@echo "[RUST] Linting with cargo clippy..."
	cargo clippy --target-dir $(CARGO_TARGET_DIR) $(CARGO_FLAGS) -- -D warnings
	@echo "[RUST] Linting complete."

# For coverage, we can use cargo tarpaulin, cargo llvm-cov, or another coverage tool.
# Below is an example with cargo tarpaulin. Adjust as needed.
rust-cover:
	@echo "[RUST] Running coverage..."
ifeq ($(CI),1)
	@echo "[RUST] Running coverage in CI mode (generating coverage report for CI)."
	cargo tarpaulin --out Xml --output-dir $(BUILD_DIR)/coverage --target-dir $(CARGO_TARGET_DIR)
else
	@echo "[RUST] Running coverage locally (generating textual coverage report)."
	cargo tarpaulin --out Text --target-dir $(CARGO_TARGET_DIR)
endif
	@echo "[RUST] Coverage complete."

# For releasing, we might do version bumps, generate a changelog, etc.
rust-release:
	@echo "[RUST] Generating changelog and bumping version with git cliff..."
	git cliff --output CHANGELOG.md
	# example for bumping version in Cargo.toml, adjust as needed
	cargo set-version --bump patch
	@echo "[RUST] Release steps complete."

# For publishing a crate to crates.io
rust-publish:
	@echo "[RUST] Publishing crate(s) to crates.io..."
	cargo publish --target-dir $(CARGO_TARGET_DIR)
	@echo "[RUST] Publish complete."

# Cross-compilation: set RUST_TARGET, e.g. `make build RUST_TARGET=x86_64-unknown-linux-gnu`
# Then cargo build --target $(RUST_TARGET) ...
# We define a small convenience if the user sets RUST_TARGET:
ifneq ($(strip $(RUST_TARGET)),)
	CARGO_FLAGS += --target $(RUST_TARGET)
endif

# Override the build/test/lint/cover targets from common.mk so the meta-targets
# will call the Rust-specific rules:
build: rust-build
test: rust-test
lint: rust-lint
cover: rust-cover
release: rust-release

# Optionally, define targets for Docker images that rely on the Rust build artifacts:
# Example usage:
#   DOCKER_IMAGE_NAME = myrustapp
image: rust-build
ifneq ($(strip $(DOCKER_ENABLED)),)
	@echo "[RUST] Building Docker image for $(DOCKER_IMAGE_NAME)..."
	# e.g. ./docker_tag.sh might produce a tag like myrustapp:v1.2.3
	DOCKER_TAG=$$(./docker_tag.sh $(DOCKER_IMAGE_NAME)) && \
	  docker build -t $$DOCKER_TAG .
	@echo "[RUST] Docker image build complete."
endif
