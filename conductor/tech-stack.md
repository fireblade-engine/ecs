# Technology Stack

The Fireblade ECS project leverages a modern, performance-oriented technology stack focused on Swift's native capabilities and data-oriented design.

## Core Language & Tools

-   **Primary Language:** **Swift**
    -   Targeting **Swift 6.1+** to leverage modern safety features and structured concurrency.
    -   Current minimum support for **Swift 5.8**.
-   **Dependency Management:** **Swift Package Manager (SPM)**.
    -   The core library maintains **zero external dependencies**.
-   **Build System:** 
    -   Native **Swift Build** (SPM).
    -   **Makefile** for automation of setup, testing, and documentation tasks.

## Build & Automation

The project uses a `Makefile` to standardize development tasks. All developers should use these commands for consistency.

-   **Code Generation:** `make generate-code` (Sourcery)
-   **Linting & Formatting:** `make lint-fix` (SwiftLint + SwiftFormat)
-   **Documentation:** `make preview-docs` (DocC)
-   **Pre-Push/Commit:** `make pre-push` (Mandatory before committing)

See [Commands Reference](./commands.md) for a full list.

## Quality & Standards

-   **Testing Frameworks:**
    -   **Swift Testing:** The primary framework for all new tests, utilizing modern macros like `#expect`.
    -   **XCTest:** Legacy framework being actively migrated to Swift Testing.
-   **Formatting & Linting:**
    -   **swift-format:** Enforced via `make swiftformat`.
    -   **SwiftLint:** Enforced via `make swiftlint`.
    -   **Automated Fixes:** Run `make lint-fix` to automatically correct style violations.
-   **Performance Monitoring:** Custom benchmarks integrated via SPM targets (e.g., `FirebladeECSPerformanceTests`).

## Documentation & Platforms

-   **Documentation:** **DocC** (Swift Documentation Compiler) for generating rich, integrated documentation.
-   **Target Platforms:** 
    -   Desktop: **macOS, Windows, Linux**
    -   Mobile: **iOS, Android**
    -   Web: **WASM**

## Architectural Patterns

-   **Data-Oriented Design (DOD):** Focus on memory layout, cache locality, and efficient data processing.
-   **Entity-Component System (ECS):** Decoupled architecture for high-performance entity management.
