# Project Workflow

This document outlines the standard development workflow for the Fireblade ECS project, ensuring code quality, consistency, and stability.

## Core Principles

1.  **Branching Strategy:**
    -   **Protect Main/Master:** NEVER commit, push, or merge directly to `main` or `master`. All changes must go through a Pull Request (PR). Direct action on `main` or `master` by the agent is strictly prohibited.
    -   **Stay on Branch:** Always work on a dedicated branch for the current task or track. If you are on `main` or `master`, immediately create a new branch named `track/<track-id>`.
    -   **Track-Based Branching:** Create a new branch for each new track using the format `track/<track-id>`.

2.  **Test-Driven Development (TDD):**
    -   Write tests *before* implementation.
    -   Ensure all new code is covered by unit tests.
    -   **Minimum Coverage:** Maintain >95% code coverage for all new code.

3.  **Code Quality:**
    -   Adhere strictly to the project's [Code Style Guides](./code_styleguides/swift.md).
    -   Resolve all linter warnings (treat warnings as errors).
    -   Ensure the project builds successfully before committing.

## Phase Completion Verification and Checkpointing Protocol

To ensure rigorous quality control, the following protocol must be executed at the end of each **Phase** in a track plan.

1.  **Verify Tests:** Run the full test suite. All tests must pass.
2.  **Verify Coverage:** Check that code coverage meets the >95% threshold.
3.  **Mandatory Checks:** Run `make pre-commit` to execute code generation, formatting, linting, and tests.
    *   Ensure all tests pass.
    *   Verify that `swiftlint` and `swiftformat` have run without errors.
4.  **Documentation:** verify that all new public APIs are documented using DocC.
5.  **Checkpoint:**
    -   **Commit:** Create a commit for the completed phase.
    -   **Message:** "feat(phase): Complete <Phase Name>" (or "fix", "refactor" as appropriate).
    -   **Task Summary:** Record a summary of the work done in the phase using Git Notes (see below).

## Task Execution

1.  **Start Task:**
    -   Checkout the track branch.
    -   Understand the requirements.

2.  **Implementation:**
    -   Write failing test(s).
    -   Implement the code to pass the test(s).
    -   Refactor and optimize.

3.  **Completion:**
    -   Verify tests pass.
    -   Run `make pre-commit` to ensure code quality and generation.
    -   Check coverage.
    -   **Git Notes:** Append a note to the commit using `git notes append -m "Task: <Task Name> - <Summary>"`.

## Final Review

-   Before merging a track branch, perform a final review of the code, documentation, and test coverage.
-   Ensure the branch is up-to-date with `main` / `master`.