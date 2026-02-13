# Implementation Plan - Parameter Pack Refactoring

## Phase 1: API Design & Prototyping
- [x] Task: Analyze current `Family` and `Component` architecture to identify all affected types.
- [x] Task: Create `API_PROPOSAL.md` outlining the new `Family<each T>` signature, `Nexus` updates, and `System` protocol changes.
- [x] Task: Create a temporary test file to verify Swift 6.0 Parameter Pack syntax and feasibility for the specific ECS requirements (traits, storage).
- [x] Task: Review and approve `API_PROPOSAL.md` with the user.
- [ ] Task: Conductor - User Manual Verification 'API Design & Prototyping' (Protocol in workflow.md)

## Phase 2: Core Refactoring (Family & Nexus)
- [x] Task: Implement `Family<each Component>`.
    - [x] Sub-task: Create `Family+ParameterPacks.swift` with the new variadic struct.
    - [x] Sub-task: Implement trait matching and component storage access using pack iteration.
- [x] Task: Refactor `Nexus` to support variadic Families.
    - [x] Sub-task: Update `Nexus.family(requires:)` to accept `each Component`.
    - [x] Sub-task: Update internal family storage to handle the new generic type (may require type erasure updates).
- [x] Task: Implement Codable support for `Family<each Component>`.
    - [x] Sub-task: Create `Family+Coding.swift` to handle encoding/decoding of family components using parameter packs.
    - [x] Sub-task: Verify Codable conformance with unit tests.
- [x] Task: Remove Legacy Code.
    - [x] Sub-task: Delete `Family.generated.swift`.
    - [x] Sub-task: Remove `Family1`, `Family2`, ... type aliases.
- [x] Task: Fix immediate compilation errors in Core files (`Nexus`, `Family`, `Component`).
- [ ] Task: Conductor - User Manual Verification 'Core Refactoring' (Protocol in workflow.md)

## Phase 3: API Adoption & Cleanup
- [x] Task: Update `Entity` APIs.
    - [x] Sub-task: Refactor `Entity.assign(...)` and `Entity.create(...)` to use parameter packs.
- [x] Task: Update `System` protocols.
    - [x] Sub-task: Update `System` requirements to work with `Family<each Component>`.
- [x] Task: Migrate Tests & Fix Compilation.
    - [x] Sub-task: Update `FamilyTests`, `NexusTests`, and `EntityTests` to use the new API.
    - [x] Sub-task: Fix any remaining compilation errors in the test suite.
- [x] Task: Remove Sourcery Tooling.
    - [x] Sub-task: Delete `.sourcery.yml`, `.sourceryTests.yml`, and `Sources/FirebladeECS/Stencils`.
    - [x] Sub-task: Remove `generate-code` target from `Makefile` and CI workflows.
    - [x] Sub-task: Remove Sourcery from `Mintfile`.
- [x] Task: Conductor - User Manual Verification 'API Adoption & Cleanup' (Protocol in workflow.md)