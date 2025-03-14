# Extensible Make Build System

This build system provides a modular, flexible, and extensible way to build, test, and deploy projects across multiple programming languages (Rust, Go, Python) while maintaining consistent targets and functionality.

## Core Features

- **Common targets** for all projects: `build`, `test`, `lint`, `cover`
- **Meta targets**: `default` (builds) and `verify` (tests, linting, coverage)
- **Extensibility** through pre/post hooks for each target
- **Language-specific implementations** for Rust, Go, and Python
- **Docker image support** with configurable registry and tags
- **Kubernetes deployment** with manifest generation
- **Cross-compilation** for Rust and Go projects
- **In-container builds** with proper caching
- **Self-contained artifacts** in the `.build` directory
- **Environment-aware behavior** (CI vs local) for user-friendly reports

## File Structure

- `base.mk` - Core build system included by all projects
- `rust.mk` - Rust-specific implementations
- `golang.mk` - Go-specific implementations
- `python.mk` - Python-specific implementations
- `docker.mk` - Docker image building functionality
- `k8s.mk` - Kubernetes deployment functionality

## Getting Started

1. Copy the `build/` directory to your project
2. Create a `Makefile` that includes the relevant functionality

```makefile
# Specify artifacts to build
ARTIFACTS = my-app my-tool

# Specify language
LANGUAGE = rust  # or golang or python

# Enable optional features
ENABLE_DOCKER = 1  # Add if Docker images are needed
ENABLE_K8S = 1     # Add if Kubernetes deployment is needed

# Include base makefile
include build/base.mk

# Override targets as needed for your project
pre-build:
    # Custom steps before the build
```

## Common Targets

| Target | Description |
|--------|-------------|
| `make` | Build the project (default target) |
| `make build` | Build the project |
| `make test` | Run tests |
| `make lint` | Run linting |
| `make cover` | Generate code coverage |
| `make verify` | Run tests, linting, and coverage |
| `make clean` | Remove build artifacts |
| `make image` | Build Docker images (if enabled) |
| `make k8s` | Generate Kubernetes manifests (if enabled) |
| `make run` | Deploy to Kubernetes (if enabled) |
| `make release` | Generate changelog and bump version |
| `make publish` | Publish to package registry (language-specific) |

## Extensibility

Every target in the system is extensible through pre/post hooks:

```makefile
# Run before the main build
pre-build:
    echo "Preparing build..."

# Run after the main build
post-build:
    echo "Build completed!"

# Override the main implementation entirely
main-build:
    echo "Custom build implementation"
```

Available hooks for each target: `pre-*`, `main-*`, `post-*`

## Configuration Variables

### Common
- `BUILD_DIR` - Directory for build artifacts (default: `.build`)
- `ARTIFACTS` - List of artifacts to build
- `IN_CI` - Set when running in CI environment

### Docker
- `DOCKER_REGISTRY` - Registry for Docker images (default: `localhost:5000`)
- `IMAGE_ARTIFACTS` - List of artifacts to build Docker images for (defaults to `ARTIFACTS`)

### Rust
- `RUST_BUILD_IMAGE` - Docker image for Rust builds
- `RUST_TARGET` - Target architecture for cross-compilation
- `RUST_COVER_TYPE` - Coverage report format (`markdown` local, `lcov` in CI)

### Go
- `GO_OS`, `GO_ARCH` - Target OS/architecture for cross-compilation
- `GO_COVER_FORMAT` - Coverage report format (`func` local, `cobertura` in CI)

### Python
- `PYTHON_COVER_FORMAT` - Coverage report format (`report` local, `xml` in CI)

## Environment-Aware Behavior

The build system automatically adjusts its behavior based on the environment:

- In CI environments (when `IN_CI` is set):
  - Coverage reports are machine-readable (lcov, xml)
  - Docker containers run non-interactively

- In local environments:
  - Coverage reports are human-readable (markdown, terminal output)
  - Docker containers run with interactive TTY

## Language-Specific Features

### Rust
- Unit and integration test separation
- Cross-compilation with `RUST_TARGET`
- In-container builds with cached dependencies
- Publishing to Crates.io

### Go
- Cross-compilation with `GO_OS` and `GO_ARCH`
- In-container builds with cached modules
- Testing with code coverage

### Python
- Poetry-based build and test
- Multiple linters (flake8, black, isort)
- Test coverage with pytest

## Example Usage

### Basic Rust Project
```makefile
ARTIFACTS = my-app
LANGUAGE = rust
include build/base.mk
```

### Rust Library with Crates.io Publishing
```makefile
ARTIFACTS = my-lib
LANGUAGE = rust
include build/base.mk

# Custom release process
post-release:
    echo "Don't forget to update the examples!"
```

### Go Project with Cross-Compilation
```makefile
ARTIFACTS = my-tool
LANGUAGE = golang
GO_OS = linux
GO_ARCH = arm64
include build/base.mk
```

### Python Project with Docker and Kubernetes
```makefile
LANGUAGE = python
ENABLE_DOCKER = 1
ENABLE_K8S = 1
include build/base.mk

# Custom Kubernetes pre-processing
pre-k8s:
    ./generate-secrets.sh
```
