# Go configuration
ifdef GO_PROJECT
ARTIFACTS ?=
GO_COVER_FILE ?= $(COVERAGE_DIR)/go-coverage.txt

do-build: $(addprefix $(BUILD_DIR)/,$(ARTIFACTS))

$(BUILD_DIR)/%:
	CGO_ENABLED=0 GOOS=$(GOOS) GOARCH=$(GOARCH) \
		go build -trimpath -ldflags "-s -w" -o "$@" "./cmd/$*"

test:
	go test -v -coverprofile="$(GO_COVER_FILE)" ./...

cover:
	go tool cover -func="$(GO_COVER_FILE)"

release:
	NEW_VERSION=$$(git cliff --bumped-version) && \
	sed -i "s/^version: .*/version: $${NEW_VERSION#v}/" go.mod && \
	git cliff --tag "$$NEW_VERSION" --prepend CHANGELOG.md && \
	git commit -am "Release $$NEW_VERSION" && \
	git tag "$$NEW_VERSION"

endif
