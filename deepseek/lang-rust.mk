# Rust configuration
CARGO ?= cargo
CARGO_HOME ?= $(BUILD_DIR)/cargo
RUST_BUILD_IMAGE ?= rust:1.79-bullseye

ifdef RUST_PROJECT
# Build configuration
ARTIFACTS ?=
DOCKER_BUILD_ARTIFACTS ?= $(ARTIFACTS)
CARGO_TEST_FLAGS ?= --features testutils

# Coverage
RUST_COVER_TYPE = $(if $(IN_CI),lcov,markdown)
RUST_COVER_FILE ?= $(COVERAGE_DIR)/rust-coverage.$(RUST_COVER_TYPE)

# Cross-compilation
ifdef TARGET_ARCH
CARGO_FLAGS += --target $(TARGET_ARCH)
endif

do-build: $(addprefix $(BUILD_DIR)/,$(ARTIFACTS))

$(BUILD_DIR)/%:
ifeq ($(filter $*,$(DOCKER_BUILD_ARTIFACTS)),$*)
	@echo "Building $* in Docker"
	docker run --rm -u "$$(id -u):$$(id -g)" \
		-v "$$PWD:/build" -v "$(CARGO_HOME):/usr/local/cargo" \
		-w /build "$(RUST_BUILD_IMAGE)" \
		$(CARGO) build $(CARGO_FLAGS) -p $* --target-dir "$(BUILD_DIR)"
else
	$(CARGO) build --target-dir "$(BUILD_DIR)" -p $* $(CARGO_FLAGS)
endif
	cp "$(BUILD_DIR)/debug/$*" "$(BUILD_DIR)/"

test:
	$(CARGO) test $(CARGO_TEST_FLAGS) --target-dir "$(BUILD_DIR)"

cover:
	grcov . --binary-path "$(BUILD_DIR)/debug/deps" \
		-s . -t "$(RUST_COVER_TYPE)" -o "$(RUST_COVER_FILE)" \
		--branch --ignore '*/tests/*'

release:
	$(MAKE) crd validation_rules
	NEW_VERSION=$$(git cliff --bumped-version) && \
	$(CARGO) set-version "$${NEW_VERSION#v}" && \
	git cliff --tag "$$NEW_VERSION" --prepend CHANGELOG.md && \
	git commit -am "Release $$NEW_VERSION" && \
	git tag "$$NEW_VERSION"

publish:
	$(CARGO) publish --target-dir "$(BUILD_DIR)"

endif
