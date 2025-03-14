# golang.mk - Go-specific build functionality
# This makefile provides Go-specific targets and settings

# Go build settings
GO_BUILD_DIR = $(BUILD_DIR)/go
GO_COVERAGE_DIR = $(BUILD_DIR)/coverage
GO_COVER_FILE = $(GO_COVERAGE_DIR)/go-coverage.txt

# Determine environment-specific settings
ifdef IN_CI
GO_COVER_FORMAT ?= cobertura
else
GO_COVER_FORMAT = func
endif

# Get app version using git
APP_VERSION = $(shell git describe --tags --always --dirty 2>/dev/null || echo "0.0.0")

# Create necessary directories
$(GO_COVERAGE_DIR):
	mkdir -p $@

# Main build implementation for Go projects
main-build: | $(GO_COVERAGE_DIR)
	CGO_ENABLED=0 go build -ldflags "-s -w" -trimpath -o $(BUILD_DIR)/ ./...

# Cross-compile when GO_OS and GO_ARCH are specified
ifdef GO_OS
ifdef GO_ARCH
main-build: | $(GO_COVERAGE_DIR)
	CGO_ENABLED=0 GOOS=$(GO_OS) GOARCH=$(GO_ARCH) go build -ldflags "-s -w" -trimpath -o $(BUILD_DIR)/ ./...
endif
endif

# Build in Docker container when needed
build-in-docker: GO_BUILD_IMAGE ?= golang:latest
build-in-docker:
	docker run --rm -u `id -u`:`id -g` -w /go/src/app \
		-v `pwd`:/go/src/app:rw \
		-v $(BUILD_DIR):/go/src/app/.build:rw \
		-v $(HOME)/go/pkg:/go/pkg:rw \
		$(GO_BUILD_IMAGE) make build

# Test implementation
main-test: | $(GO_COVERAGE_DIR)
	mkdir -p $(GO_COVERAGE_DIR)
	go test -v -coverprofile=$(GO_COVER_FILE) ./...

# Linting implementation
main-lint:
	golangci-lint run

# Coverage implementation
main-cover: | $(GO_COVERAGE_DIR)
	go tool cover -$(GO_COVER_FORMAT)=$(GO_COVER_FILE)

# Release implementation using git cliff
main-release: NEW_APP_VERSION = $(subst v,,$(shell git cliff --bumped-version))
main-release:
	echo "$(NEW_APP_VERSION)" > VERSION
	git cliff -u --tag $(NEW_APP_VERSION) --prepend CHANGELOG.md
	git commit -a -m "release: version v$(NEW_APP_VERSION)" && \
		git tag v$(NEW_APP_VERSION)
