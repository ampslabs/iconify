# ADR-007: Starter Registry Strategy

## Status
Accepted

## Context
A major barrier to using a dynamic icon library is the "empty state" where no icons work until you configure a provider or run a CLI tool.

## Decision
We will ship a **Starter Registry** bundled as assets with the `iconify_sdk` package.

- **Content**: The top ~500 most popular icons from major sets (Material Design Icons, Lucide, Tabler, Heroicons).
- **Metadata**: Licensing and basic info for all 200+ collections (so names are recognized even if the body isn't bundled).
- **Size Budget**: Strict **200KB limit** (uncompressed) for all bundled assets.
- **Auto-Fallthrough**: The `IconifyIcon` widget automatically checks the Starter Registry if the icon isn't found in memory or generated code.

## Consequences
- **Pros**:
    - "Magical" first-run experience: Most common icons like `mdi:home` or `lucide:settings` work instantly.
    - Zero configuration for small prototypes.
- **Cons**:
    - Adding ~200KB to the application size (this is considered acceptable for the benefit provided, and can be disabled).
