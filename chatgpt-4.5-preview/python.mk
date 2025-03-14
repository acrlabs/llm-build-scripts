include make/base.mk

PYTHON ?= python3

build::
	$(PYTHON) setup.py build

test::
	$(PYTHON) -m pytest tests

lint::
	flake8 src tests
	black --check src tests

cover::
ifeq ($(CI),true)
	pytest --cov=src --cov-report=xml
else
	pytest --cov=src
endif

release::
	git cliff --tag $(shell python setup.py --version)
	# manually increment the version in setup.py or pyproject.toml
