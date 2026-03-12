# ADR-004: Rendering Strategy

## Status
Accepted

## Context
Rendering SVGs in Flutter typically uses the `flutter_svg` package. However, with the introduction of the **Impeller** rendering engine, certain SVGs (specifically those using complex color filters or specific combinations of gradients/masks) have shown rendering inconsistencies.

## Decision
We will use a **layered rendering strategy** with an automatic Impeller workaround:

1. **Primary**: `flutter_svg` for direct vector rendering.
2. **Impeller Fallback**: If Impeller is detected AND a color override is requested, the SDK can optionally rasterize the SVG to a `ui.Image` at the target resolution to ensure visual correctness.
3. **Explicit Strategy**: The `IconifyIcon` widget will allow developers to force a strategy: `svgDirect`, `rasterized`, or `auto`.

## Consequences
- **Pros**:
    - High-quality vector rendering by default.
    - Safety net for known Impeller color-filtering edge cases.
    - Performance control for complex icons.
- **Cons**:
    - Slightly higher library complexity due to the rasterization logic.
    - Potential memory overhead if many icons are rasterized (mitigated by LRU caching of images).
