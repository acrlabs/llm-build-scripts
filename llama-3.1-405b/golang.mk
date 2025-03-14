# Define the Go build target
.PHONY: build
build: $(BUILD_DIR)
	@echo "Building Go binary..."
	CGO_ENABLED=0 go build -ldflags "-s -w" -trimpath -o $(BUILD_DIR)/$(ARTIFACT) ./cmd/.

# Define the Go test target
.PHONY: test
test: $(BUILD_DIR)
	@echo "Testing Go binary..."
	go test -v -coverprofile=$(GO_COVER_FILE) ./...

# Define the Go lint target
.PHONY: lint
lint: $(BUILD_DIR)
	@echo "Linting Go code..."
	golangci-lint run

# Define the Go cover target
.PHONY: cover
cover: $(BUILD_DIR)
	@echo "Computing Go code coverage..."
	go tool cover -func=$(GO_COVER_FILE)
