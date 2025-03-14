# Python configuration
ifdef PYTHON_PROJECT
test:
	poetry run pytest -svv tests

cover:
	poetry run coverage report --show-missing

release:
	NEW_VERSION=$$(git cliff --bumped-version) && \
	poetry version "$${NEW_VERSION#v}" && \
	git cliff --tag "$$NEW_VERSION" --prepend CHANGELOG.md && \
	git commit -am "Release $$NEW_VERSION" && \
	git tag "$$NEW_VERSION"

endif
