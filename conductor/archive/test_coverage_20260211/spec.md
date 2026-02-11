# Specification: Extend Test Coverage and Migrate to Swift Testing

## Overview
This track aims to achieve >95% code coverage across the entire `FirebladeECS` codebase. Simultaneously, it involves migrating all existing `XCTest` suites to the modern `Swift Testing` framework to align with the project's modernization goals.

## Goals
- Achieve >95% code coverage for the entire project.
- Ensure every individual source file exceeds >95% code coverage.
- Migrate 100% of existing tests from `XCTest` to `Swift Testing`.

## Functional Requirements
- **Coverage Expansion:** Identify and fill gaps in the current test suite until every file in `Sources/FirebladeECS` meets the 95% threshold.
- **Framework Migration:**
    - Replace `XCTestCase` with `@Test` and `@Suite`.
    - Replace `XCTAssert...` macros with `#expect` and `#require`.
    - Update `Package.swift` or test targets if necessary to support Swift Testing.
- **Refactoring:** Update existing tests to follow idiomatic `Swift Testing` patterns (e.g., using `arguments` for parameterized tests).

## Non-Functional Requirements
- **Build Integrity:** The project must build successfully on all supported platforms (macOS, Linux, Windows, WASM) after migration.
- **Performance:** Ensure that the transition to `Swift Testing` does not negatively impact the execution time of the test suite.

## Acceptance Criteria
- `make test-coverage` reports an overall project coverage of >95%.
- Each individual file in `Sources/FirebladeECS` shows >95% coverage in the coverage report.
- No `import XCTest` remains in the `Tests/` directory (excluding performance tests if `Swift Testing` doesn't yet support them equivalently).
- `make pre-commit` passes without errors.

## Out of Scope
- Major architectural refactoring of the core ECS logic (unless required for testability).
- Expanding coverage for the `Benchmarks` target, unless it shares code with the main library that needs testing.
