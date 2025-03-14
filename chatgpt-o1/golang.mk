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
