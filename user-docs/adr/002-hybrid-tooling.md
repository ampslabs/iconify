# ADR-002: Hybrid CLI + build_runner Strategy

## Status
Accepted

## Context
Developers need to bundle icons locally for offline reliability and performance. This requires a tool to scan source code, identify used icons, and download/bundle them.
The Flutter ecosystem has two standard paths:
1. **Standalone CLI**: Fast, low dependency, but manual.
2. **build_runner (Source Gen)**: Integrated into the Dart compiler workflow, supports `watch` mode, but can be slow for large projects.

## Decision
We will implement a **hybrid approach** where the core logic resides in a CLI package (`iconify_sdk_cli`), but is exposed as a `build_runner` builder (`iconify_sdk_builder`).

- The **CLI** will be the "power user" tool for CI/CD and manual bundling.
- The **Builder** will provide the "effortless" experience for developers used to `build_runner`.

## Consequences
- **Pros**:
    - Flexibility: Works for developers who hate `build_runner` and for those who love it.
    - Consistency: Both tools share the same logic in `iconify_sdk_core`.
- **Cons**:
    - Maintenance: Requires managing two entry points for the same functionality.
    - Complexity: Potential confusion on which tool to use (mitigated by clear documentation).
