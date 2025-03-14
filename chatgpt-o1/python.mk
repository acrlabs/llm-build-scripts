#######################################
# python.mk
#
# Language-specific rules for Python projects.
# This file relies on variables and meta-targets from common.mk.
# Include it *after* including common.mk in your project Makefile.
#######################################

.PHONY: py-build py-test py-lint py-cover py-release

# For Python, "build" might mean preparing a virtualenv or build artifacts (wheel, etc.)
# We store intermediate artifacts in .build/python-dist
PY_DIST_DIR := $(BUILD_DIR)/python-dist
PY_VENV_DIR := $(BUILD_DIR)/venv

py-build:
	@echo "[PYTHON] Creating a virtual environment and building artifacts..."
	python3 -m venv $(PY_VENV_DIR)
	$(PY_VENV_DIR)/bin/pip install --upgrade pip wheel setuptools
	$(PY_VENV_DIR)/bin/pip wheel -w $(PY_DIST_DIR) .
	@echo "[PYTHON] Build complete."

py-test:
	@echo "[PYTHON] Running Python tests..."
	$(PY_VENV_DIR)/bin/pip install -r requirements-dev.txt
	$(PY_VENV_DIR)/bin/pytest tests
	@echo "[PYTHON] Tests complete."

py-lint:
	@echo "[PYTHON] Linting with flake8 (or pylint)..."
	$(PY_VENV_DIR)/bin/pip install flake8
	$(PY_VENV_DIR)/bin/flake8 .
	@echo "[PYTHON] Lint complete."

py-cover:
	@echo "[PYTHON] Running coverage..."
	$(PY_VENV_DIR)/bin/pip install coverage
ifeq ($(CI),1)
	@echo "[PYTHON] Coverage in CI mode."
	$(PY_VENV_DIR)/bin/coverage run --source=. -m pytest tests
	$(PY_VENV_DIR)/bin/coverage xml -o $(BUILD_DIR)/coverage.xml
else
	@echo "[PYTHON] Coverage locally, printing coverage report."
	$(PY_VENV_DIR)/bin/coverage run --source=. -m pytest tests
	$(PY_VENV_DIR)/bin/coverage report
endif
	@echo "[PYTHON] Coverage complete."

py-release:
	@echo "[PYTHON] Generating changelog and bumping version..."
	git cliff --output CHANGELOG.md
	# Bump version in setup.cfg, pyproject.toml, or similar if needed
	@echo "[PYTHON] Release steps complete."

# Override the core targets:
build: py-build
test: py-test
lint: py-lint
cover: py-cover
release: py-release

# If DOCKER_ENABLED=1:
# Example usage:
#   DOCKER_IMAGE_NAME = mypyapp
image: py-build
ifneq ($(strip $(DOCKER_ENABLED)),)
	@echo "[PYTHON] Building Docker image for $(DOCKER_IMAGE_NAME)..."
	DOCKER_TAG=$$(./docker_tag.sh $(DOCKER_IMAGE_NAME)) && \
	  docker build -t $$DOCKER_TAG .
	@echo "[PYTHON] Docker image build complete."
endif
