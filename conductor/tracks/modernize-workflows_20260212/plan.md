# Implementation Plan: Modernize GitHub Workflows

This plan outlines the steps to synchronize GitHub Actions workflows with the reference implementation and adapt existing project-specific workflows to the new standards.

## Phase 1: Preparation and Extraction

- [ ] Task: Extract reference workflow content from `Math` dependency.
    - [ ] Read `ci-ios.yml`, `ci-linux.yml`, `ci-macos.yml`, `ci-windows.yml`, `docs.yml`, `markdown-link-check.yml`, and `mlc_config.json`.
- [ ] Task: Analyze existing `ci-wasm.yml` and `Makefile` to identify necessary adaptations.
    - [ ] Read `.github/workflows/ci-wasm.yml`.
    - [ ] Read `Makefile`.

## Phase 2: Workflow Updates and Additions

- [ ] Task: Update core CI workflows.
    - [ ] Replace content of `.github/workflows/ci-linux.yml` with reference.
    - [ ] Replace content of `.github/workflows/ci-macos.yml` with reference.
    - [ ] Replace content of `.github/workflows/ci-windows.yml` with reference.
- [ ] Task: Add new platform and documentation workflows.
    - [ ] Create `.github/workflows/ci-ios.yml` with reference content.
    - [ ] Create `.github/workflows/docs.yml` with reference content.
    - [ ] Delete `.github/workflows/documentation.yml`.
- [ ] Task: Update utility workflows and configuration.
    - [ ] Update `.github/workflows/markdown-link-check.yml` with reference content.
    - [ ] Create `.github/workflows/mlc_config.json` with reference content.
- [ ] Task: Adapt `ci-wasm.yml` to match new project standards.
    - [ ] Update triggers, concurrency, and environment setup to align with reference style.
- [ ] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md)

## Phase 3: Build System Alignment

- [ ] Task: Update `Makefile` targets for documentation.
    - [ ] Align `docs-generate` and related targets with `docs.yml` requirements.
- [ ] Task: Verify overall project consistency.
    - [ ] Run `make lint` and `make build-debug` to ensure no regressions in local tooling.
- [ ] Task: Conductor - User Manual Verification 'Phase 3' (Protocol in workflow.md)
