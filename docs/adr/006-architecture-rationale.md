# ADR-006: Three-Package Architecture Rationale

## Status
Accepted

## Context
A monolithic package containing Flutter widgets, CLI tools, and core logic would be heavy and problematic:
- CLI tools don't need Flutter.
- Pure Dart apps (AngularDart, Shelf) might want the core engine.
- `build_runner` packages should avoid Flutter dependencies to run faster in isolated environments.

## Decision
The project is split into four packages within a monorepo:

1. **`iconify_sdk_core`**: Pure Dart. Models, parsers, and logic. No Flutter dependency.
2. **`iconify_sdk`**: Flutter-specific. Widgets, asset providers, and rendering logic.
3. **`iconify_sdk_builder`**: Build system integration. Depends on `core`.
4. **`iconify_sdk_cli`**: Command-line interface. Depends on `core`.

## Consequences
- **Pros**:
    - Clean dependency separation.
    - `iconify_sdk_core` can be used on the server or in Dart CLI apps.
    - Minimal footprint for the main `iconify_sdk` package.
- **Cons**:
    - Increased maintenance complexity (monorepo management).
    - Requires Melos for coordinated development.
