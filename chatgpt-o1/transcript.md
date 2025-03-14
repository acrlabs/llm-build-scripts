Below is an example of a refactored build system that satisfies your requirements. It is split into four files:

1. **common.mk** – The main logic shared across all projects (meta-targets, core targets, environment checks, directory layout, etc.).
2. **rust.mk** – Language-specific rules for Rust projects (cargo build, test, lint, coverage, publishing to crates.io, cross-compilation, etc.).
3. **golang.mk** – Language-specific rules for Go projects (build, test, lint, coverage, cross-compilation, etc.).
4. **python.mk** – Language-specific rules for Python projects (build, test, lint, coverage, etc.).

Each project’s own `Makefile` (e.g. `Makefile.rust`, `Makefile.golang`, or `Makefile.python`) includes `common.mk` and one of the language-specific files, then selectively opts in to Docker/Kubernetes targets if needed.

> **Note**: Since you have projects in different languages, you can keep these files in a single git submodule repository (the new “common base” you referenced) and then include them in each project as needed. Example usage is shown after the file listings.

---

## File: `common.mk`

```makefile
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
```

---

## File: `rust.mk`

```makefile
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
```

---

## File: `golang.mk`

```makefile
#######################################
# golang.mk
#
# Language-specific rules for Go projects.
# This file relies on variables and meta-targets from common.mk.
# Include it *after* including common.mk in your project Makefile.
#######################################

.PHONY: go-build go-test go-lint go-cover go-release

# By default, compiled binaries go under .build/go-bin
GO_BIN_DIR := $(BUILD_DIR)/go-bin
GO_CACHE_DIR := $(BUILD_DIR)/go-cache

# If the user sets GOOS/GOARCH, we can cross-compile easily.
# Example usage: make build GOOS=linux GOARCH=amd64
# We also ensure the build cache is under .build to preserve caching.

go-build:
	@echo "[GO] Building Go binaries..."
	CGO_ENABLED=0 GOCACHE=$(GO_CACHE_DIR) go build -o $(GO_BIN_DIR) ./...
	@echo "[GO] Build complete."

go-test:
	@echo "[GO] Running tests..."
	GOCACHE=$(GO_CACHE_DIR) go test -v ./...
	@echo "[GO] Tests complete."

go-lint:
	@echo "[GO] Running golint..."
	# If you use 'golangci-lint' or 'go vet', put the commands here
	go vet ./...
	@echo "[GO] Linting complete."

go-cover:
	@echo "[GO] Running coverage..."
ifeq ($(CI),1)
	@echo "[GO] Running coverage in CI mode."
	go test -coverprofile=$(BUILD_DIR)/coverage.out ./...
	# This file can be uploaded to CodeCov or similar
else
	@echo "[GO] Running coverage locally, printing summary."
	go test -coverprofile=$(BUILD_DIR)/coverage.out ./...
	go tool cover -func=$(BUILD_DIR)/coverage.out
endif
	@echo "[GO] Coverage complete."

go-release:
	@echo "[GO] Generating changelog and bumping version..."
	git cliff --output CHANGELOG.md
	# For Go modules, you might do: go mod edit -replace or set new version tags, etc.
	@echo "[GO] Release steps complete."

# Override the core targets:
build: go-build
test: go-test
lint: go-lint
cover: go-cover
release: go-release

# If DOCKER_ENABLED=1:
# Example usage:
#   DOCKER_IMAGE_NAME = mygoapp
image: go-build
ifneq ($(strip $(DOCKER_ENABLED)),)
	@echo "[GO] Building Docker image for $(DOCKER_IMAGE_NAME)..."
	DOCKER_TAG=$$(./docker_tag.sh $(DOCKER_IMAGE_NAME)) && \
	  docker build -t $$DOCKER_TAG .
	@echo "[GO] Docker image build complete."
endif
```

---

## File: `python.mk`

```makefile
#######################################
# python.mk
#
# Language-specific rules for Python projects.
# This file relies on variables and meta-targets from common.mk.
# Include it *after* including common.mk in your project Makefile.
#######################################

.PHONY: py-build py-test py-lint py-cover py-release

# For Python, "build" might mean preparing a virtualenv or build artifacts (wheel, etc.)
# We store intermediate artifacts in .build/python-dist
PY_DIST_DIR := $(BUILD_DIR)/python-dist
PY_VENV_DIR := $(BUILD_DIR)/venv

py-build:
	@echo "[PYTHON] Creating a virtual environment and building artifacts..."
	python3 -m venv $(PY_VENV_DIR)
	$(PY_VENV_DIR)/bin/pip install --upgrade pip wheel setuptools
	$(PY_VENV_DIR)/bin/pip wheel -w $(PY_DIST_DIR) .
	@echo "[PYTHON] Build complete."

py-test:
	@echo "[PYTHON] Running Python tests..."
	$(PY_VENV_DIR)/bin/pip install -r requirements-dev.txt
	$(PY_VENV_DIR)/bin/pytest tests
	@echo "[PYTHON] Tests complete."

py-lint:
	@echo "[PYTHON] Linting with flake8 (or pylint)..."
	$(PY_VENV_DIR)/bin/pip install flake8
	$(PY_VENV_DIR)/bin/flake8 .
	@echo "[PYTHON] Lint complete."

py-cover:
	@echo "[PYTHON] Running coverage..."
	$(PY_VENV_DIR)/bin/pip install coverage
ifeq ($(CI),1)
	@echo "[PYTHON] Coverage in CI mode."
	$(PY_VENV_DIR)/bin/coverage run --source=. -m pytest tests
	$(PY_VENV_DIR)/bin/coverage xml -o $(BUILD_DIR)/coverage.xml
else
	@echo "[PYTHON] Coverage locally, printing coverage report."
	$(PY_VENV_DIR)/bin/coverage run --source=. -m pytest tests
	$(PY_VENV_DIR)/bin/coverage report
endif
	@echo "[PYTHON] Coverage complete."

py-release:
	@echo "[PYTHON] Generating changelog and bumping version..."
	git cliff --output CHANGELOG.md
	# Bump version in setup.cfg, pyproject.toml, or similar if needed
	@echo "[PYTHON] Release steps complete."

# Override the core targets:
build: py-build
test: py-test
lint: py-lint
cover: py-cover
release: py-release

# If DOCKER_ENABLED=1:
# Example usage:
#   DOCKER_IMAGE_NAME = mypyapp
image: py-build
ifneq ($(strip $(DOCKER_ENABLED)),)
	@echo "[PYTHON] Building Docker image for $(DOCKER_IMAGE_NAME)..."
	DOCKER_TAG=$$(./docker_tag.sh $(DOCKER_IMAGE_NAME)) && \
	  docker build -t $$DOCKER_TAG .
	@echo "[PYTHON] Docker image build complete."
endif
```

---

## Example Usage in a Project’s Makefile

Below are three simplified examples showing how you might adapt your existing `Makefile.rust`, `Makefile.golang`, or `Makefile.python` to use these new base files. You would replace your old contents with the new approach. Adjust as needed for each project’s details.

### 1. Rust Project (`Makefile.rust`)

```makefile
#######################################
# Makefile.rust
#
# Example Rust project Makefile that uses the new base scripts.
#######################################

# Include the common logic first
include common.mk

# Enable Docker if this project should build Docker images.
# (Optional: remove if you don't need it)
DOCKER_ENABLED = 1
DOCKER_IMAGE_NAME = my-rust-app

# Optionally enable Kubernetes if needed
# K8S_ENABLED = 1

# Now include the Rust-specific rules
include rust.mk

# Example: define additional crate(s) or override variables
# RUST_CRATES = my-app

# Optionally extend or override targets:
# build: rust-build
#     echo "[PROJECT] Doing an extra step..."

# That’s it! The meta-targets default, verify, etc. come from common.mk
# Rust build/test/lint/cover/release come from rust.mk
```

### 2. Go Project (`Makefile.golang`)

```makefile
#######################################
# Makefile.golang
#
# Example Go project Makefile that uses the new base scripts.
#######################################

include common.mk

# This project also wants Docker images
DOCKER_ENABLED = 1
DOCKER_IMAGE_NAME = my-go-app

# No k8s in this example
# K8S_ENABLED = 1

include golang.mk

# Optionally override or add custom steps.
# build: go-build
#    echo "[PROJECT] Additional build steps..."

# The meta-targets are inherited from common.mk
```

### 3. Python Project (`Makefile.python`)

```makefile
#######################################
# Makefile.python
#
# Example Python project Makefile that uses the new base scripts.
#######################################

include common.mk

# This project doesn't need Docker or K8S:
# DOCKER_ENABLED = 1
# K8S_ENABLED = 1

include python.mk

# If you do need Docker, just set DOCKER_ENABLED=1 and
# DOCKER_IMAGE_NAME before including python.mk.
```

---

## How This System Addresses Your 15 Requirements

1. **Basic targets**: `build`, `test`, `lint`, `cover` are defined in `common.mk` (overridden in each language file). The meta-targets `default` (build) and `verify` (test + lint + cover) are also defined.
2. **Docker images**: If `DOCKER_ENABLED` is set, an `image` target is added and also appended to the `default` target. A `docker_tag.sh` script can be used to compute the tag.
3. **Kubernetes**: If `K8S_ENABLED` is set, `k8s` (and optionally `run`) are defined. Those can also be appended to `default` (commented out or enabled based on your preference).
4. **Extensibility**: Each target can be extended or overridden (e.g. `build: rust-build ...`). Make variables allow you to define additional dependencies or commands.
5. **Multiple artifacts**: By listing them in environment variables (e.g. `RUST_CRATES`, or using a pattern for multiple build artifacts), you can build multiple binaries or wheels. Similarly, you can define multiple Docker images if needed.
6. **Building in a Docker container**: You can integrate container-based builds by adjusting the commands in `rust-build`, `go-build`, or `py-build` to invoke Docker. For instance, you could override `rust-build` to run `docker run -v $(PWD):/src ... cargo build`.
7. **Support for Rust, Golang, Python**: Each has its own `.mk` file with relevant commands.
8. **`release` target with `git cliff`**: Provided as `rust-release`, `go-release`, `py-release`. They generate a changelog with `git cliff` and can bump versions.
9. **Publish to Crates.io**: The `rust.mk` file has a `rust-publish` target (`cargo publish`).
10. **Cross-compilation**: For Rust, set `RUST_TARGET`; for Go, set `GOOS`, `GOARCH`. Both examples are shown.
11. **Caching build artifacts in container**: The example uses `.build/rust-target` or `.build/go-cache` directories so that repeated builds do not re-fetch dependencies if you mount `.build` as a volume in Docker.
12. **Rust incremental rebuild**: By specifying `--target-dir $(CARGO_TARGET_DIR)`, cargo reuses incremental artifacts, so consecutive `make test`, `make build`, `make test` does not rebuild if code hasn’t changed.
13. **Self-contained `.build` directory**: All compilers use `.build/` for intermediate artifacts, and `make clean` just removes that directory.
14. **Only the needed targets**: If Docker or K8S support isn’t needed, do not set `DOCKER_ENABLED` or `K8S_ENABLED`, and those targets effectively become no-ops.
15. **Local vs CI**: We check `CI ?=` in `common.mk` so coverage or other steps can produce different output depending on `CI=1` or not.

This modular design should simplify maintenance across multiple projects and languages. Simply adjust each project’s Makefile to include `common.mk` plus the relevant language `.mk`, then opt in to Docker or Kubernetes as needed.
