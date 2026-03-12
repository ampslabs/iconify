# ADR-005: CLI Data Source Policy

## Status
Accepted

## Context
The Iconify project maintains two primary ways to access icon data:
1. **HTTP API**: `api.iconify.design`. Good for individual icon lookups.
2. **GitHub Repository**: `github.com/iconify/icon-sets`. Contains the full source JSON files for all collections.

## Decision
The **`iconify_sdk_cli` and `builder` will use GitHub Raw JSON files** as their primary data source for bundling and generation.

- Instead of making hundreds of API calls, we download the collection-level JSON file.
- This allows for "offline-first" builds where a local copy of the repo can be used.
- It bypasses API rate limits and provides more stable indexing for CI environments.

## Consequences
- **Pros**:
    - Faster bundling: One download per collection rather than one per icon.
    - Reliability: GitHub's infrastructure is optimized for raw file delivery.
    - Full metadata access: CLI can check licenses and versions more reliably.
- **Cons**:
    - Larger initial download if a collection has thousands of icons but only one is used (mitigated by caching and trimmed storage).
