# Technology Stack

This document outlines the technology stack, libraries, and tools used in the project.

## Core Language & Runtime
-   **Language:** Swift 6.0+
-   **Runtime:** macOS (primary development), Linux, Windows, WASM (supported via CI)

## Dependencies & Package Management
-   **Package Manager:** Swift Package Manager (SPM)
-   **Dependency Installer:** `make setup` (installs Homebrew, Mint, bootstraps environment)
-   **Tool Management:** Mint (`Mintfile`)

## Build System & Automation
-   **Build Tool:** `swift build` (via `Makefile` wrappers)
-   **Task Runner:** `make`
    -   **Debug Build:** `make build-debug`
    -   **Release Build:** `make build-release`

## Code Quality & Standards
-   **Linter:** SwiftLint (`.swiftlint.yml`)
-   **Formatter:** SwiftFormat (`.swiftformat`)
-   **Enforcement:**
    -   **Linting:** `make lint`
    -   **Fix/Format:** `make lint-fix`
    -   **Pre-Commit:** `make pre-commit` (runs lint-fix + tests)

## Testing
-   **Framework:** XCTest / Swift Testing (Migration in progress)
-   **Execution:** `make test`
-   **Coverage:** `make test-coverage` (llvm-cov)

## Documentation
-   **Generator:** DocC
-   **Preview:** `make docs-preview`
-   **Static Site Generation:** `make docs-generate` / `make generate-docs-githubpages`

## Code Generation
-   **Tool:** Sourcery
-   **Command:** `make generate-code`
-   **Config:** `.sourcery.yml`, `.sourceryTests.yml`

## Continuous Integration (CI)
-   **Platform:** GitHub Actions
-   **Workflows:**
    -   `ci-macos.yml`
    -   `ci-linux.yml`
    -   `ci-windows.yml`
    -   `ci-wasm.yml`
    -   `documentation.yml`