# Specification: Modernize GitHub Workflows

## Overview
This track aims to modernize the project's GitHub Actions workflows by synchronizing them with a reference implementation from the `Math` dependency. The goal is to standardize CI/CD practices across projects, ensuring robust testing and documentation deployment.

## Functional Requirements

### 1. Workflow Synchronization
-   **Update Existing Workflows:**
    -   `ci-linux.yml`: Update content to match the reference.
    -   `ci-macos.yml`: Update content to match the reference.
    -   `ci-windows.yml`: Update content to match the reference.
    -   `markdown-link-check.yml`: Update content to match the reference.

-   **Add New Workflows/Config:**
    -   `ci-ios.yml`: Add this new workflow from the reference.
    -   `docs.yml`: Add this new workflow from the reference (replacing `documentation.yml`).
    -   `mlc_config.json`: Add this configuration file from the reference.

-   **Remove Legacy Workflows:**
    -   `documentation.yml`: Remove this file (superseded by `docs.yml`).

-   **Adapt Existing Workflows:**
    -   `ci-wasm.yml`: Update this workflow to match the structure, triggers, and configuration patterns found in the reference workflows (e.g., concurrency groups, checkout versions), even though a direct reference file does not exist.

### 2. Documentation Deployment
-   **Strict Adherence:** The `docs.yml` workflow must be implemented exactly as in the reference.
-   **Makefile Updates:** Modify `Makefile` targets (e.g., `make docs-generate`, `make generate-docs-githubpages`) if necessary to align with the new `docs.yml` expectations (e.g., output directory, branch name).

## Non-Functional Requirements
-   **Correctness:** The updated workflows must be syntactically correct and functional (as per the assumption that the reference is working).
-   **Consistency:** Naming conventions and structure should match the reference project.

## Out of Scope
-   Verifying the execution of the workflows (user will handle verification).

## Acceptance Criteria
-   `ci-linux.yml`, `ci-macos.yml`, `ci-windows.yml` match the reference content.
-   `ci-ios.yml` exists and matches the reference.
-   `documentation.yml` is deleted.
-   `docs.yml` exists and matches the reference.
-   `markdown-link-check.yml` and `mlc_config.json` match the reference.
-   `ci-wasm.yml` is updated to align with the style and common configuration of the reference workflows.
-   `Makefile` supports the new `docs.yml` workflow.
