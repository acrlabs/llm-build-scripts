# python.mk - Python-specific build functionality
# This makefile provides Python-specific targets and settings

# Python build settings
PYTHON_BUILD_DIR = $(BUILD_DIR)/python
PYTHON_COVERAGE_DIR = $(BUILD_DIR)/coverage
PYTHON_COVER_FILE = $(PYTHON_COVERAGE_DIR)/python-coverage

# Determine environment-specific settings
ifdef IN_CI
PYTHON_COVER_FORMAT ?= xml
else
PYTHON_COVER_FORMAT = report
endif

# Get app version from pyproject.toml or setup.py
APP_VERSION = $(shell grep -m 1 'version =' pyproject.toml 2>/dev/null | cut -d'"' -f2 || \
              grep -m 1 'version=' setup.py 2>/dev/null | cut -d'"' -f2 || \
              echo "0.0.0")

# Create necessary directories
$(PYTHON_COVERAGE_DIR):
	mkdir -p $@

# Main build implementation for Python projects
main-build: | $(PYTHON_COVERAGE_DIR)
	poetry build
	mkdir -p $(BUILD_DIR)/dist
	cp -r dist/* $(BUILD_DIR)/dist/ || true

# Build in Docker container when needed
build-in-docker: PYTHON_BUILD_IMAGE ?= python:3.11-slim
build-in-docker:
	docker run --rm -u `id -u`:`id -g` -w /app \
		-v `pwd`:/app:rw \
		-v $(BUILD_DIR):/app/.build:rw \
		$(PYTHON_BUILD_IMAGE) make build

# Test implementation
main-test: | $(PYTHON_COVERAGE_DIR)
	poetry run coverage erase
	JSII_SILENCE_WARNING_UNTESTED_NODE_VERSION=1 poetry run coverage run -m pytest -svv tests
	poetry run coverage $(PYTHON_COVER_FORMAT) --show-missing

# Linting implementation
main-lint:
	poetry run flake8 || true
	poetry run black --check . || true
	poetry run isort --check . || true

# Coverage implementation
main-cover: | $(PYTHON_COVERAGE_DIR)
	poetry run coverage $(PYTHON_COVER_FORMAT) --show-missing

# Release implementation using git cliff
main-release: NEW_APP_VERSION = $(subst v,,$(shell git cliff --bumped-version))
main-release:
	poetry version $(NEW_APP_VERSION)
	git cliff -u --tag $(NEW_APP_VERSION) --prepend CHANGELOG.md
	git commit -a -m "release: version v$(NEW_APP_VERSION)" && \
		git tag v$(NEW_APP_VERSION)
