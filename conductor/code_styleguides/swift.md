# Swift Code Style Guide

This guide outlines the Swift coding standards for the Fireblade ECS project, derived from the project's `.swiftlint.yml` and `.swiftformat` configurations.

## General Formatting

-   **Line Length:** Maximum of **220 characters**.
-   **Indentation:** Use 4 spaces for indentation (standard Swift convention).
-   **Commas:** Inline commas (do not use trailing commas in multi-line lists).
-   **File Header:** Include a standard file header.
-   **Imports:** Sort imports alphabetically (`sorted_imports`).

## Naming Conventions

-   **Identifiers:** Use `camelCase` for variables and functions, `PascalCase` for types.
-   **File Names:** Must not contain spaces (`file_name_no_space`).
-   **Numbers:** Use separators for large numbers (minimum length 5, e.g., `1_000_000`).
-   **Boolean Toggles:** Use `.toggle()` instead of `!value` (`toggle_bool`).

## Syntax & Usage

-   **Self Usage:**
    -   **Remove `self`** where it is not required (`--self remove`).
    -   **Require `self`** only in closures where necessary/explicit (`--selfrequired get`, `explicit_self`).
    -   Prefer `Self` over type name (`prefer_self_type_over_type_of_self`).
-   **Closures:**
    -   Use trailing closure syntax where appropriate (`trailing_closure`).
    -   Strip unused arguments in closures (`--stripunusedargs closure-only`).
    -   Ensure proper spacing and indentation (`closure_spacing`, `closure_body_length`, `closure_end_indentation`).
-   **Optionals:**
    -   **Avoid Force Unwrapping:** Strictly prohibited (`force_unwrapping`, `implicitly_unwrapped_optional`).
    -   Avoid discouraged optional boolean and collection usage (`discouraged_optional_boolean`, `discouraged_optional_collection`).
    -   Use `first(where:)` instead of `filter().first` (`first_where`).
-   **Control Flow:**
    -   Avoid "Yoda conditions" (`yoda_condition`).
    -   Use `switch` cases on new lines (`switch_case_on_newline`).
    -   Use `fallthrough` explicitly where intended (`fallthrough`).
-   **Collections:**
    -   Use `isEmpty` instead of checking `count == 0` (`empty_count`).
    -   Use `contains` where appropriate (`contains_over_filter_count`, `contains_over_first_not_nil`).
    -   Align collection elements consistently (`collection_alignment`).

## Safety & Best Practices

-   **Access Control:**
    -   Explicitly define top-level ACL (`explicit_top_level_acl`).
    -   Ensure strict `fileprivate` usage (`strict_fileprivate`).
-   **Classes:**
    -   Mark classes as `final` where possible (implied by usage, good practice for performance).
    -   Use `convenience init` properly (`convenience_type`).
-   **Testing:**
    -   Use a single test class per file (`single_test_class`).
    -   Avoid empty test methods (`empty_xctest_method`).

## Linting & Enforcement

-   **Strictness:** Treat all warnings as errors.
-   **Tools:**
    -   `SwiftLint` is used to enforce these rules.
    -   `swift-format` is used for automated formatting.
