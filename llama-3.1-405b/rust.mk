# Define the Rust build target
.PHONY: build
build: $(BUILD_DIR)
	@echo "Building Rust binary..."
	cargo build --target-dir=$(BUILD_DIR) $(addprefix -p=,$(ARTIFACTS)) --color=always

# Define the Rust test target
.PHONY: test
test: $(BUILD_DIR)
	@echo "Testing Rust binary..."
	cargo test $(CARGO_TEST) --features testutils -- --skip itest

# Define the Rust lint target
.PHONY: lint
lint: $(BUILD_DIR)
	@echo "Linting Rust code..."
	pre-commit run --all

# Define the Rust cover target
.PHONY: cover
cover: $(BUILD_DIR)
	@echo "Computing Rust code coverage..."
	grcov . --binary-path $(BUILD_DIR)/debug/deps -s . -t $(RUST_COVER_TYPE) -o $(RUST_COVER_FILE) --branch \
		--ignore '../*' \
		--ignore '/*' \
		--ignore '*/tests/*' \
		--ignore '*_test.rs' \
		--ignore 'sk-api/*' \
		--ignore '*/testutils/*' \
		--ignore '.build/*' \
		--excl-line '#\[derive' \
		--excl-start '#\[cfg\((test|feature = "testutils")'

# Define the Rust release target
.PHONY: release
release: $(BUILD_DIR)
	@echo "Releasing Rust package..."
	cargo set-version $(NEW_APP_VERSION)
	git cliff -u --tag $(NEW_APP_VERSION) --prepend CHANGELOG.md
	make kustomize
	git commit -a -m "release: version v$(NEW_APP_VERSION)" && \
		git tag v$(NEW_APP_VERSION)

# Define the Rust publish target
.PHONY: publish
publish: $(BUILD_DIR)
	@echo "Publishing Rust package..."
	cargo ws publish --publish-as-is
