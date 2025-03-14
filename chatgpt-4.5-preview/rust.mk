include make/base.mk

CARGO ?= cargo
TARGET ?=
TARGET_FLAG := $(if $(TARGET),--target $(TARGET))

build::
	$(CARGO) build $(TARGET_FLAG) --release

test::
	$(CARGO) test $(TARGET_FLAG)

lint::
	$(CARGO) fmt -- --check
	$(CARGO) clippy $(TARGET_FLAG) -- -D warnings

cover::
ifeq ($(CI),true)
	cargo tarpaulin --out Xml
else
	cargo tarpaulin
endif

release::
	git cliff --tag $(shell cargo pkgid | cut -d'#' -f2)
	cargo release patch

publish::
	cargo publish
