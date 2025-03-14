include make/base.mk

GO ?= go
TARGET_OS ?= $(shell uname | tr A-Z a-z)
TARGET_ARCH ?= $(shell uname -m)

build::
	GOOS=$(TARGET_OS) GOARCH=$(TARGET_ARCH) $(GO) build -o $(BUILD_DIR)/app ./...

test::
	$(GO) test ./...

lint::
	golangci-lint run

cover::
ifeq ($(CI),true)
	$(GO) test -coverprofile=$(BUILD_DIR)/coverage.out ./...
else
	$(GO) test -cover ./...
endif

release::
	git cliff --tag $(shell git describe --tags --abbrev=0)
