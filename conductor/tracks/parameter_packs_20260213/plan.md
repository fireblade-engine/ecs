# Implementation Plan - Parameter Pack Refactoring

## Phase 1: API Design & Prototyping
- [ ] Task: Analyze current `Family` and `Component` architecture to identify all affected types.
- [ ] Task: Create `API_PROPOSAL.md` outlining the new `Family<each T>` signature, `Nexus` updates, and `System` protocol changes.
- [ ] Task: Create a temporary test file to verify Swift 6.0 Parameter Pack syntax and feasibility for the specific ECS requirements (traits, storage).
- [ ] Task: Review and approve `API_PROPOSAL.md` with the user.
- [ ] Task: Conductor - User Manual Verification 'API Design & Prototyping' (Protocol in workflow.md)

## Phase 2: Core Refactoring (Family & Nexus)
- [ ] Task: Implement `Family<each Component>`.
    - [ ] Sub-task: Create `Family+ParameterPacks.swift` with the new variadic struct.
    - [ ] Sub-task: Implement trait matching and component storage access using pack iteration.
- [ ] Task: Refactor `Nexus` to support variadic Families.
    - [ ] Sub-task: Update `Nexus.family(requires:)` to accept `each Component`.
    - [ ] Sub-task: Update internal family storage to handle the new generic type (may require type erasure updates).
- [ ] Task: Remove Legacy Code.
    - [ ] Sub-task: Delete `Family.generated.swift`.
    - [ ] Sub-task: Remove `Family1`, `Family2`, ... type aliases.
- [ ] Task: Fix immediate compilation errors in Core files (`Nexus`, `Family`, `Component`).
- [ ] Task: Conductor - User Manual Verification 'Core Refactoring' (Protocol in workflow.md)

## Phase 3: API Adoption & Cleanup
- [ ] Task: Update `Entity` APIs.
    - [ ] Sub-task: Refactor `Entity.assign(...)` and `Entity.create(...)` to use parameter packs.
- [ ] Task: Update `System` protocols.
    - [ ] Sub-task: Update `System` requirements to work with `Family<each Component>`.
- [ ] Task: Migrate Tests & Fix Compilation.
    - [ ] Sub-task: Update `FamilyTests`, `NexusTests`, and `EntityTests` to use the new API.
    - [ ] Sub-task: Fix any remaining compilation errors in the test suite.
- [ ] Task: Remove Sourcery Tooling.
    - [ ] Sub-task: Delete `.sourcery.yml`, `.sourceryTests.yml`, and `Sources/FirebladeECS/Stencils`.
    - [ ] Sub-task: Remove `generate-code` target from `Makefile` and CI workflows.
- [ ] Task: Conductor - User Manual Verification 'API Adoption & Cleanup' (Protocol in workflow.md)