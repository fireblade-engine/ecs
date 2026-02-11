# Project Commands Reference

This document serves as a comprehensive reference for all `make` commands available in the project. These commands are defined in the `Makefile` and automate various tasks such as building, testing, linting, and documentation generation.

## Code Quality & Formatting

| Command | Description |
| :--- | :--- |
| `make lint-fix` | Runs both `swiftlint` (autocorrect) and `swiftformat` to ensure code style compliance. |
| `make swiftlint` | Runs `swiftlint` with `--fix` to correct linting errors. |
| `make swiftformat` | Runs `swiftformat` on the entire project using the current Swift version. |

## Code Generation

| Command | Description |
| :--- | :--- |
| `make generate-code` | Runs `sourcery` to generate boilerplate code based on configurations `.sourcery.yml` and `.sourceryTests.yml`. |

## Pre-Commit / Pre-Push

| Command | Description |
| :--- | :--- |
| `make pre-push` | **MANDATORY**: Runs `generate-code` and `lint-fix`. Must be run before pushing or committing changes. |
| `make precommit` | Alias for `make pre-push`. |

## Build

| Command | Description |
| :--- | :--- |
| `make build-debug` | Builds the project in debug configuration (`swift build -c debug`). |
| `make build-release` | Builds the project in release configuration (`swift build -c release --skip-update`). |

## Setup & Dependencies

| Command | Description |
| :--- | :--- |
| `make setupEnvironment` | Installs all necessary dependencies for macOS (Homebrew, Mint, etc.). |
| `make install-dependencies-macOS` | Installs Homebrew (if missing), updates it, installs Mint, and bootstraps Mint dependencies. |
| `make setup-brew` | Installs and/or updates Homebrew. |

## Documentation

| Command | Description |
| :--- | :--- |
| `make preview-docs` | Builds and previews the DocC documentation locally. |
| `make preview-analysis-docs` | Previews DocC documentation with analysis, warnings, and coverage overview. |
| `make generate-docs` | Generates a static DocC archive in the `.build` directory. |
| `make generate-docs-githubpages` | Generates static HTML documentation suitable for GitHub Pages in the `./docs` directory. |

## Maintenance & Cleanup

| Command | Description |
| :--- | :--- |
| `make clean` | Cleans build artifacts and Sourcery caches (`swift package clean`). |
| `make clean-sourcery` | Removes the Sourcery cache directory. |
| `make testReadme` | Checks the `README.md` for broken links (requires `markdown-link-check`). |
