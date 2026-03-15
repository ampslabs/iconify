---
title: Impeller & Flutter Rendering
description: Understand how the Iconify SDK handles Flutter's Impeller rendering engine with its automated hybrid rendering path for perfect visuals on all platforms.
---

The Iconify SDK is built to be "Impeller Ready," ensuring smooth performance on Flutter's next-generation rendering engine.

## The Impeller Challenge

Impeller introduced significant changes to how SVG color filters are handled. In some scenarios, applying a `color` override to a complex SVG can result in rendering artifacts or performance drops on certain devices.

## How the SDK Solves It

The SDK implements an **Automated Hybrid Rendering Path** to ensure perfect visuals regardless of your renderer:

1. **Direct SVG**: By default, the SDK uses `flutter_svg` to render the icon directly. This is the fastest and most memory-efficient path.
2. **Rasterized Fallback**: If the SDK detects that:
   - Impeller is the active renderer.
   - A `color` override is requested.
   - The icon is complex (or a specific flag is set).

   ...it will automatically switch to a rasterized path. The SVG is rendered to a high-resolution `ui.Image` in a separate isolate and then displayed. This bypasses the Impeller color-filter issue entirely.

## Platform Support Matrix

| Platform | Default Renderer | Iconify Path |
|---|---|---|
| **iOS** | Impeller (>= 3.10) | Hybrid (Auto-switch) |
| **Android** | Skia (Impeller Opt-in) | Skia (Direct) / Impeller (Hybrid) |
| **Web** | CanvasKit / HTML | Direct SVG |
| **Desktop** | Skia | Direct SVG |

## Manual Override

You can manually control the rendering strategy for a specific icon if needed:

```dart
IconifyIcon(
  'mdi:rocket',
  renderStrategy: RenderStrategy.rasterized, // Force rasterization
)
```

For most users, leaving the default `RenderStrategy.auto` is recommended.
