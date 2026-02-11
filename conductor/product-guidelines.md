# Product Guidelines

These guidelines define the standards for documentation, code style, and design principles for the Fireblade ECS project, ensuring consistency and quality across the codebase.

## Documentation & Prose Style

-   **Technical & Precise:** Documentation and code comments must prioritize technical accuracy, performance characteristics, and algorithmic complexity.
-   **Clarity over Verbosity:** Aim for clear, concise explanations that provide high value to systems engineers and game developers.
-   **Why over What:** Focus on explaining the reasoning behind complex architectural decisions rather than just describing the implementation.

## Code Examples

-   **Modern Swift:** All code examples must use the latest Swift syntax (Swift 6.1+), including structured concurrency and result builders where appropriate.
-   **Performance-Oriented:** Examples should highlight performance-critical patterns and data-oriented practices, even if they require more explicit code.
-   **Cross-Platform Validity:** Ensure that all examples are valid and functional across all supported platforms, including macOS, iOS, Android, Linux, Windows, and WASM.

## Design Principles

-   **Data-Oriented Design (DOD):** The codebase must emphasize memory layout and data access patterns to maximize cache efficiency and performance.
-   **Composition over Inheritance:** Leverage Swift's protocols and generics to build flexible, modular systems. Avoid deep class hierarchies.
-   **Safety and Correctness:** Prioritize memory and type safety. 
    -   Use the Swift compiler's features to catch errors at compile time.
    -   **Zero tolerance for `fatalError` or force unwraps (`!`).**
    -   **Prohibit the use of `try!` (force try).** All errors must be handled gracefully.
    -   **Zero Compiler Warnings:** The project must compile with zero errors and zero warnings. All warnings must be treated as errors (`-warnings-as-errors`).
-   **Platform Native & Lightweight:**
    -   **Avoid Objective-C APIs:** Do not use `NS*` or other Objective-C legacy types/APIs in favor of native Swift types.
    -   **Zero External Dependencies:** The core library must remain dependency-free.
    -   **Minimal Imports:** Keep imports to the absolute minimum necessary for functionality.
-   **Testing:**
    -   **Swift Testing Framework:** New tests must use the modern **Swift Testing** framework (using `#expect` macro).
    -   **XCTest Deprecation:** Avoid writing new XCTest-based tests. Plan to migrate existing tests to the new framework.
-   **Strict File Structure:**
    -   **One Type Per File:** Each file must contain exactly one primary type definition (class, struct, enum, or protocol) **if the type definition exceeds 5 lines**.
    -   **Naming Convention:** The file name must exactly match the name of the primary type it defines (e.g., `Nexus.swift` for the `Nexus` type).
