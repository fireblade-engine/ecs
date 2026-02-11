# Implementation Plan: Extend Test Coverage and Migrate to Swift Testing

## Phase 1: Setup and Baseline Audit
- [ ] Task: Audit current code coverage to identify specific files and paths below 95%.
    - [ ] Run `make test-coverage` and export the detailed report.
    - [ ] List all files in `Sources/FirebladeECS` currently below 95% coverage.
- [ ] Task: Verify Swift Testing environment.
    - [ ] Ensure `Package.swift` is configured for the `Testing` framework.
    - [ ] Create a "Hello World" Swift Testing file to confirm toolchain support.
- [ ] Task: Conductor - User Manual Verification 'Setup and Baseline Audit' (Protocol in workflow.md)

## Phase 2: Systematic Migration to Swift Testing
- [ ] Task: Migrate core utility tests.
    - [ ] Migrate `ComponentIdentifierTests.swift`.
    - [ ] Migrate `EntityIdGenTests.swift`.
    - [ ] Migrate `HashingTests.swift`.
- [ ] Task: Migrate entity and component management tests.
    - [ ] Migrate `EntityTests.swift` and `EntityCreationTests.swift`.
    - [ ] Migrate `ComponentTests.swift`.
    - [ ] Migrate `SparseSetTests.swift`.
- [ ] Task: Migrate high-level ECS logic tests.
    - [ ] Migrate `NexusTests.swift` and `NexusEventDelegateTests.swift`.
    - [ ] Migrate `FamilyTests.swift` and FamilyTraitsTests.swift`.
    - [ ] Migrate `SingleTests.swift` and `FSMTests.swift`.
- [ ] Task: Migrate generated and specialized tests.
    - [ ] Migrate `FamilyCodingTests.swift`.
    - [ ] Update `FamilyTests.stencil` to generate Swift Testing code.
- [ ] Task: Conductor - User Manual Verification 'Systematic Migration to Swift Testing' (Protocol in workflow.md)

## Phase 3: Coverage Gap Closure (Targeting >95% Per File)
- [ ] Task: Increase coverage for `Nexus` and internal management.
    - [ ] Add tests for edge cases in `Nexus+Internal.swift`.
    - [ ] Ensure all `NexusEvent` types are triggered and handled in tests.
- [ ] Task: Increase coverage for `Family` and `Coding`.
    - [ ] Add tests for complex `Family` requirements and trait sets.
    - [ ] Expand `FamilyDecoding` and `FamilyEncoding` tests for malformed data.
- [ ] Task: Increase coverage for Utilities and Extensions.
    - [ ] Add tests for `ManagedContiguousArray` bounds and growth.
    - [ ] Cover all helper methods in `Foundation+Extensions.swift`.
- [ ] Task: Conductor - User Manual Verification 'Coverage Gap Closure' (Protocol in workflow.md)

## Phase 4: Finalization and Quality Assurance
- [ ] Task: Final project-wide coverage audit.
    - [ ] Confirm `make test-coverage` reports >95% for every file.
    - [ ] Verify 100% of tests are using `Swift Testing` (no `XCTest` remaining in `Tests/FirebladeECSTests`).
- [ ] Task: Documentation and Style Review.
    - [ ] Ensure all new test suites and public API changes are documented.
    - [ ] Run `make lint` and `make lint-fix` to ensure adherence to style guides.
- [ ] Task: Cross-Platform Verification.
    - [ ] (If possible) Run tests on different platforms or verify via CI triggers.
- [ ] Task: Conductor - User Manual Verification 'Finalization and Quality Assurance' (Protocol in workflow.md)
