Below is one example solution that factors the common behavior into a shared “base” Makefile (here placed in a subdirectory called “common”) and then shows how each project’s Makefile (for Rust, Golang, and Python) can simply include that base and add language‐specific rules. (You can adjust file names and variable names as needed.)

Below are the files:

---

**File: common/base.mk**
This file defines the common targets and “meta‐target” (the default target) that automatically runs build and verify (which in turn runs test, lint, and cover). It also conditionally includes Docker image targets (if you set the variable `HAS_IMAGE`) and Kubernetes targets (if you set `HAS_K8S`). It also centralizes where build artifacts are stored and provides for environment-specific behavior (e.g. human‑readable output locally versus CI output).

```make
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
```

---

**File: Makefile.rust**
This file is for a Rust project. It includes the common base, then provides implementations for the delegated targets. In this example the Rust build uses Cargo and supports optional cross-compilation via the `TARGET` variable. There is also an extra `release` target that runs `git cliff` to generate a CHANGELOG and reminds you to bump version numbers, plus a `publish` target to push a new version to Crates.io.

```make
# Makefile.rust - Project-specific Makefile for Rust projects
#
# Include the common base
include common/base.mk

# Uncomment or set these if your project should build a Docker image or deploy to Kubernetes.
# HAS_IMAGE = 1
# HAS_K8S = 1

# Project-specific variables
PROJECT = my_rust_app
CARGO_BIN ?= cargo

# Allow cross-compilation; if TARGET is set, use it.
TARGET ?=

# Implement the _build target for Rust.
_build:
	@echo ">> [RUST] Building project..."
	mkdir -p $(BUILD_DIR)
ifeq ($(TARGET),)
	$(CARGO_BIN) build --release --target-dir $(BUILD_DIR)
else
	$(CARGO_BIN) build --release --target $(TARGET) --target-dir $(BUILD_DIR)
endif

# Implement the _test target.
_test:
	@echo ">> [RUST] Running tests..."
	$(CARGO_BIN) test

# Implement the _lint target using Clippy.
_lint:
	@echo ">> [RUST] Running lint (clippy)..."
	$(CARGO_BIN) clippy -- -D warnings

# Implement the _cover target.
_cover:
	@echo ">> [RUST] Running coverage..."
ifeq ($(COVERAGE_MODE),ci)
	@echo "[RUST] Running coverage in CI mode..."
	# Example: cargo tarpaulin --out Xml --target-dir $(BUILD_DIR)
else
	@echo "[RUST] Running coverage locally..."
	# Example: cargo tarpaulin --out Html --target-dir $(BUILD_DIR)
endif

# Docker image target – build image if HAS_IMAGE is set.
ifdef HAS_IMAGE
_image:
	@echo ">> [RUST] Building Docker image for Rust binary..."
	# Example: Build the binary inside a container to match deployment environment.
	docker build --build-arg TARGET=$(TARGET) -t $(shell ./docker_tag.sh) .
endif

# Kubernetes targets – if HAS_K8S is set.
ifdef HAS_K8S
_k8s:
	@echo ">> [RUST] Generating Kubernetes manifests..."
	# For example, use scripts or templating.
	./scripts/generate_k8s.sh

_run:
	@echo ">> [RUST] Deploying to Kubernetes..."
	kubectl apply -f k8s/
endif

# Additional Rust-specific targets.
.PHONY: release publish
release:
	@echo ">> [RUST] Releasing new version..."
	git cliff -o CHANGELOG.md
	@echo "Remember to update Cargo.toml with the new version."

publish: build test lint
	@echo ">> [RUST] Publishing to Crates.io..."
	$(CARGO_BIN) publish
```

---

**File: Makefile.golang**
This file is for a Golang project. It includes similar hooks as the Rust one. It supports cross-compilation by letting you specify `TARGET_OS` and `TARGET_ARCH`. The release target runs `git cliff` and reminds you to bump the version in your module files.

```make
# Makefile.golang - Project-specific Makefile for Golang projects
#
# Include the common base Makefile
include common/base.mk

# Uncomment these if your project needs Docker images or Kubernetes deployment.
# HAS_IMAGE = 1
# HAS_K8S = 1

# Project-specific variables
PROJECT = my_golang_app
GO ?= go

# Allow cross-compilation via TARGET_OS and TARGET_ARCH variables.
TARGET_OS ?=
TARGET_ARCH ?=

_build:
	@echo ">> [GOLANG] Building project..."
	mkdir -p $(BUILD_DIR)
ifneq ($(TARGET_OS),)
	@echo ">> [GOLANG] Cross-compiling for $(TARGET_OS)/$(TARGET_ARCH)..."
	GOOS=$(TARGET_OS) GOARCH=$(TARGET_ARCH) $(GO) build -o $(BUILD_DIR)/$(PROJECT)
else
	$(GO) build -o $(BUILD_DIR)/$(PROJECT)
endif

_test:
	@echo ">> [GOLANG] Running tests..."
	$(GO) test ./...

_lint:
	@echo ">> [GOLANG] Running golint..."
	golint ./...

_cover:
	@echo ">> [GOLANG] Running code coverage..."
ifneq ($(COVERAGE_MODE),ci)
	@echo "[GOLANG] Running coverage locally..."
	$(GO) test -coverprofile=$(BUILD_DIR)/coverage.out ./... && go tool cover -html=$(BUILD_DIR)/coverage.out
else
	@echo "[GOLANG] Running coverage in CI mode..."
	$(GO) test -coverprofile=$(BUILD_DIR)/coverage.out ./...
endif

ifdef HAS_IMAGE
_image:
	@echo ">> [GOLANG] Building Docker image for Go binary..."
	docker build --build-arg TARGET_OS=$(TARGET_OS) --build-arg TARGET_ARCH=$(TARGET_ARCH) -t $(shell ./docker_tag.sh) .
endif

ifdef HAS_K8S
_k8s:
	@echo ">> [GOLANG] Generating Kubernetes manifests..."
	./scripts/generate_k8s.sh

_run:
	@echo ">> [GOLANG] Deploying to Kubernetes..."
	kubectl apply -f k8s/
endif

.PHONY: release
release:
	@echo ">> [GOLANG] Releasing new version..."
	git cliff -o CHANGELOG.md
	@echo "Remember to update go.mod with the new version."
```

---

**File: Makefile.python**
For a Python project the process is similar. Typically you may not need Docker or Kubernetes targets (unless you’re containerizing your Python app), so those targets are not defined unless you set `HAS_IMAGE` or `HAS_K8S`.

```make
# Makefile.python - Project-specific Makefile for Python projects
#
# Include the common base Makefile
include common/base.mk

# For most Python projects, you may not need HAS_IMAGE or HAS_K8S.
# Uncomment the lines below if your project requires these.
# HAS_IMAGE = 1
# HAS_K8S = 1

# Project-specific variables
PROJECT = my_python_app
PYTHON ?= python3
PIP ?= pip

_build:
	@echo ">> [PYTHON] Building project..."
	# For Python, the build step might package the project or prepare a virtual environment.
	mkdir -p $(BUILD_DIR)
	$(PYTHON) setup.py build --build-base $(BUILD_DIR)

_test:
	@echo ">> [PYTHON] Running tests..."
	pytest

_lint:
	@echo ">> [PYTHON] Running linting..."
	flake8 .

_cover:
	@echo ">> [PYTHON] Running code coverage..."
ifeq ($(COVERAGE_MODE),ci)
	@echo "[PYTHON] Running coverage in CI mode..."
	pytest --maxfail=1 --disable-warnings -q --cov=$(PROJECT) --cov-report=xml:$(BUILD_DIR)/coverage.xml
else
	@echo "[PYTHON] Running coverage locally..."
	pytest --maxfail=1 --disable-warnings -q --cov=$(PROJECT) --cov-report=term-missing
endif

.PHONY: release
release:
	@echo ">> [PYTHON] Releasing new version..."
	git cliff -o CHANGELOG.md
	@echo "Remember to update version information in setup.py (or equivalent)."
```

---

### How to Use These Makefiles

1. **Common Base File:**
   Place the `common/base.mk` in a common directory (or adjust the include path as desired). Every project’s Makefile should begin with:
   ```make
   include common/base.mk
   ```
   This imports all the default targets and sets up the meta target (i.e. the default target that runs `build`, `verify`, and, if enabled, `image`, `k8s`, and `run`).

2. **Extending Targets:**
   Each project-specific Makefile implements the delegated “underscore” targets (_build, _test, etc.). You can add extra commands or prerequisites by modifying these targets. For example, you might add extra steps to your _build target for multi-artifact builds or containerized builds.

3. **Optional Targets:**
   If your project creates Docker images, simply set `HAS_IMAGE = 1` (either at the top of your project Makefile or via the environment). Similarly, for Kubernetes-related functionality, set `HAS_K8S = 1`.

4. **Cross-compilation & Containerized Builds:**
   For Rust and Golang projects, you can set variables such as `TARGET` (for Rust) or `TARGET_OS`/`TARGET_ARCH` (for Golang) to cross-compile. The Docker image targets show an example of passing these variables to the container build process.

5. **Releases:**
   A `release` target is provided for each language that uses `git cliff` to generate a CHANGELOG and reminds you to bump the version. (You can automate version bumping by adding commands to update your metadata files.)

6. **Clean Build Artifacts:**
   All generated artifacts should reside in the `.build` subdirectory. Running `make clean` will remove this directory, ensuring that your builds are self-contained.

7. **Local vs. CI Behavior:**
   The variable `COVERAGE_MODE` is automatically set based on whether the `CI` variable is defined. This lets you run different coverage commands when building locally versus in your CI pipeline (for example, producing human‑readable reports locally and machine‑readable XML reports for CodeCov).

This design is modular and extensible: common functionality is centralized, and each project only needs to define its language‑specific build steps. You can further customize each target by adding extra prerequisites or commands as your projects evolve.

Feel free to adjust paths, tool names, and extra steps as needed for your environment.
