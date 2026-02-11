# Project Commands Reference

This document serves as a comprehensive reference for all `make` commands available in the project. These commands are defined in the `Makefile` and automate various tasks such as building, testing, linting, and documentation generation.

## Setup & Dependencies

| Command | Description |
| :--- | :--- |
| `make setup` | Installs dependencies (Homebrew, Mint) and bootstraps the environment. |

## Code Quality & Formatting

| Command | Description |
| :--- | :--- |
| `make lint` | Runs `swiftlint` and `swiftformat` in lint-only mode (no changes). |
| `make lint-fix` | Runs `swiftlint` (autocorrect) and `swiftformat` (formatting) on `Sources/` and `Tests/`. |

## Testing

| Command | Description |
| :--- | :--- |
| `make test` | Runs tests in parallel with code coverage enabled. |
| `make test-coverage` | Runs tests and generates a code coverage report using `llvm-cov`. |

## Code Generation

| Command | Description |
| :--- | :--- |
| `make generate-code` | Runs `sourcery` to generate boilerplate code based on configurations `.sourcery.yml` and `.sourceryTests.yml`. |

## Pre-Commit Workflow

| Command | Description |
| :--- | :--- |
| `make pre-commit` | **MANDATORY**: Runs `lint-fix` and `test`. Must be run before committing changes. |

## Build

| Command | Description |
| :--- | :--- |
| `make build-debug` | Builds the project in debug configuration (`swift build -c debug`). |
| `make build-release` | Builds the project in release configuration (`swift build -c release --skip-update`). |

## Documentation

| Command | Description |
| :--- | :--- |
| `make docs` | Alias for `make docs-generate`. |
| `make docs-preview` | Builds and previews the DocC documentation locally. |
| `make docs-generate` | Generates a static DocC archive in the `.build` directory. |
| `make docs-coverage` | Checks documentation coverage. |
| `make docs-check-links` | Checks documentation for broken links. |
| `make preview-analysis-docs` | Previews DocC documentation with analysis, warnings, and coverage overview. |
| `make generate-docs-githubpages` | Generates static HTML documentation suitable for GitHub Pages in the `./docs` directory. |

## Maintenance & Cleanup

| Command | Description |
| :--- | :--- |
| `make clean` | Cleans build artifacts (`.build`, `.swiftpm`) and Sourcery caches. |
| `make clean-sourcery` | Removes the Sourcery cache directory. |
| `make testReadme` | Checks the `README.md` for broken links (requires `markdown-link-check`). |