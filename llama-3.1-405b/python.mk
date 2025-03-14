# Define the Python build target
.PHONY: build
build: $(BUILD_DIR)
	@echo "Building Python package..."
	poetry build

# Define the Python test target
.PHONY: test
test: $(BUILD_DIR)
	@echo "Testing Python package..."
	poetry run pytest -svv tests

# Define the Python lint target
.PHONY: lint
lint: $(BUILD_DIR)
	@echo "Linting Python code..."
	poetry run flake8 .

# Define the Python cover target
.PHONY: cover
cover: $(BUILD_DIR)
	@echo "Computing Python code coverage..."
	poetry run coverage run -m pytest -svv tests
	poetry run coverage report --show-missing
