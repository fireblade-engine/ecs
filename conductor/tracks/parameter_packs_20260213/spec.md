# Specification: Parameter Pack Refactoring

## 1. Overview
Refactor the Fireblade ECS to exclusively use Swift Parameter Packs (SE-0393), replacing the existing code-generated `Family` and `Component` management logic. This modernization aims to provide a unified, sleek, and type-safe API, removing the dependency on Sourcery code generation.

## 2. Goals
-   **Modernization:** Adopts Swift 6.0+ Parameter Packs.
-   **Simplification:** Removes 1000s of lines of generated code.
-   **Unified API:** Provides a single, variadic interface for `Family`, `Nexus`, and `Entity` operations.
-   **Tooling:** Removes Sourcery dependency and build steps.

## 3. Functional Requirements
### 3.1 Family & Nexus API
-   **Replace:** `Family2`, `Family3`, etc., with a single `Family<each Component>` type.
-   **Update:** `Nexus.family(requires:)` to accept a parameter pack of component types.
-   **Breaking Change:** Existing `FamilyN` type aliases will be removed.

### 3.2 System & Entity API
-   **Update:** `System` protocols to support variadic generic constraints for family requirements.
-   **Update:** `Entity.assign(...)` and `Entity.create(...)` to accept variadic component arguments.

### 3.3 Tooling
-   **Remove:** `.sourcery.yml`, `.sourceryTests.yml`, and all `*.stencil` templates.
-   **Remove:** `make generate-code` build step.

## 4. Non-Functional Requirements
-   **Language:** Swift 6.0+
-   **Performance:** While no specific benchmarks are required for this track, the implementation should aim to maintain existing performance characteristics where possible.

## 5. Out of Scope
-   Detailed performance regression testing (per user instruction).
-   Backward compatibility layers (deprecated type aliases).

## 6. Success Criteria
-   The project compiles with Swift 6.0+.
-   All existing tests (updated for the new API) pass.
-   Sourcery configuration and templates are removed.
-   `Family` and `Nexus` APIs usage is cleaner and variadic.