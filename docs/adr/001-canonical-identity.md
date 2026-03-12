# ADR-001: Canonical Identity Strategy

## Status
Accepted

## Context
When integrating Iconify with Flutter, there is a choice between two identity patterns:
1. **Generated Constants**: e.g., `MdiIcons.home` (standard Flutter approach).
2. **Canonical String Identifiers**: e.g., `mdi:home` (standard Iconify approach).

Iconify provides over 200,000 icons across 200+ collections. Generating Dart constants for the entire registry is technically unfeasible (massive binary bloat, IDE lag).

## Decision
We will use the **string-based `prefix:name` pattern** as the primary identity for icons in the `iconify_sdk`.

- Developers will use strings like `IconifyIcon('mdi:home')`.
- The internal engine resolves these strings at runtime through a layered provider system.
- Code generation (Phase 3) will be used to generate local metadata for *only* the icons actually used in the project, rather than the entire collection.

## Consequences
- **Pros**: 
    - Infinite scalability: Any Iconify icon works immediately without waiting for a library update.
    - Consistency: MatchesIconify documentation and API.
    - Performance: No massive generated classes for unneeded icons.
- **Cons**: 
    - No autocompletion for icon names in basic string mode (mitigated by IDE plugins and code generation in Phase 3).
    - Type safety is shifted to runtime unless the code generator is used.
