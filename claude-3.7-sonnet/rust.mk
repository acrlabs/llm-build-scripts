# rust.mk - Rust-specific build functionality
# This makefile provides Rust-specific targets and settings

# Rust build settings
RUST_BUILD_DIR = $(BUILD_DIR)/rust
CARGO_HOME_ENV = CARGO_HOME=$(RUST_BUILD_DIR)/cargo
RUST_COVERAGE_DIR = $(BUILD_DIR)/coverage
RUST_COVER_FILE = $(RUST_COVERAGE_DIR)/rust-coverage

# Determine environment-specific settings
ifdef IN_CI
CARGO_TEST_PREFIX = $(CARGO_HOME_ENV) CARGO_INCREMENTAL=0 RUSTFLAGS='-Cinstrument-coverage' LLVM_PROFILE_FILE='$(RUST_COVERAGE_DIR)/cargo-test-%p-%m.profraw'
RUST_COVER_TYPE ?= lcov
DOCKER_ARGS =
else
RUST_COVER_TYPE = markdown
DOCKER_ARGS = -it --init
endif

# Get app version from Cargo.toml
APP_VERSION = $(shell tomlq -r .workspace.package.version Cargo.toml 2>/dev/null || tomlq -r .package.version Cargo.toml 2>/dev/null || echo "0.0.0")

# Default Rust build image
RUST_BUILD_IMAGE ?= rust:1.79-bullseye

# Create necessary directories
$(RUST_COVERAGE_DIR):
	mkdir -p $@

# Main build implementation for Rust projects
main-build: | $(RUST_COVERAGE_DIR)
	cargo build --target-dir=$(BUILD_DIR) $(addprefix -p=,$(ARTIFACTS)) --color=always
	$(foreach artifact,$(ARTIFACTS),cp $(BUILD_DIR)/debug/$(artifact) $(BUILD_DIR)/. ;)

# Build in Docker container when needed
build-in-docker:
	docker run $(DOCKER_ARGS) -u `id -u`:`id -g` -w /build \
		-v `pwd`:/build:rw \
		-v $(BUILD_DIR):/build/.build:rw \
		$(RUST_BUILD_IMAGE) make build-docker

# Cross-compile when RUST_TARGET is specified
ifdef RUST_TARGET
main-build: | $(RUST_COVERAGE_DIR)
	rustup target add $(RUST_TARGET)
	cargo build --target-dir=$(BUILD_DIR) --target=$(RUST_TARGET) $(addprefix -p=,$(ARTIFACTS)) --color=always
	$(foreach artifact,$(ARTIFACTS),cp $(BUILD_DIR)/$(RUST_TARGET)/debug/$(artifact) $(BUILD_DIR)/. ;)
endif

# Test implementation split into unit and integration tests
main-test: unit-test integration-test

unit-test: | $(RUST_COVERAGE_DIR)
	mkdir -p $(RUST_COVERAGE_DIR)
	rm -f $(RUST_COVERAGE_DIR)/*.profraw
	$(CARGO_TEST_PREFIX) cargo test $(CARGO_TEST) $(CARGO_TEST_ARGS) -- --skip itest

integration-test: | $(RUST_COVERAGE_DIR)
	$(CARGO_TEST_PREFIX) cargo test itest $(CARGO_TEST_ARGS) -- --nocapture --test-threads=1

# Linting implementation 
main-lint:
	pre-commit run --all
	cargo clippy -- -D warnings

# Coverage implementation
main-cover: | $(RUST_COVERAGE_DIR)
	grcov . --binary-path $(BUILD_DIR)/debug/deps -s . -t $(RUST_COVER_TYPE) -o $(RUST_COVER_FILE).$(RUST_COVER_TYPE) --branch \
		--ignore '../*' \
		--ignore '/*' \
		--ignore '*/tests/*' \
		--ignore '*_test.rs' \
		--ignore '*/testutils/*' \
		--ignore '.build/*' \
		--excl-line '#\[derive' \
		--excl-start '#\[cfg\((test|feature = "testutils")'
	@if [ "$(RUST_COVER_TYPE)" = "markdown" ]; then cat $(RUST_COVER_FILE).$(RUST_COVER_TYPE); fi

# Release implementation using git cliff
main-release: NEW_APP_VERSION = $(subst v,,$(shell git cliff --bumped-version))
main-release:
	cargo set-version $(NEW_APP_VERSION)
	git cliff -u --tag $(NEW_APP_VERSION) --prepend CHANGELOG.md
	git commit -a -m "release: version v$(NEW_APP_VERSION)" && \
		git tag v$(NEW_APP_VERSION)

# Publish to crates.io
main-publish:
	cargo publish
