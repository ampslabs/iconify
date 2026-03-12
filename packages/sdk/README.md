# Iconify SDK for Flutter

The official Flutter package for [Iconify](https://iconify.design/). Render any icon from over 200 open-source icon sets (150,000+ icons) with a single widget.

## Features

- **One-liner usage**: `IconifyIcon('mdi:home')`.
- **Zero Configuration**: Works out of the box in debug mode with remote fetching.
- **Production Ready**: Automatically blocks remote calls in release builds for reliability and ethics.
- **Impeller Optimized**: Built-in workaround for Impeller rendering bugs when applying colors.
- **Offline First**: Optimized for use with bundled snapshots or generated code.

## Quick Start

1. Add the package to your `pubspec.yaml`:
   ```bash
   flutter pub add iconify_sdk
   ```

2. Wrap your app in `IconifyApp`:
   ```dart
   void main() {
     runApp(
       const IconifyApp(
         child: MyApp(),
       ),
     );
   }
   ```

3. Use the widget anywhere:
   ```dart
   IconifyIcon('mdi:home', size: 24, color: Colors.blue)
   ```

## Rendering & Impeller

Flutter's new **Impeller** renderer has known issues with SVG `colorFilter` (used for theming monochrome icons). 

Iconify SDK detects if Impeller is active. If you provide a `color` override while Impeller is enabled, the SDK automatically switches from `svgDirect` to a `rasterized` path. This ensures your icons always render correctly and sharply without you having to manage workarounds manually.

## Operational Modes

You can configure the SDK's behavior via `IconifyConfig`:

- **`auto` (Default)**: Use remote API in debug/profile for speed, but require local icons in release.
- **`offline`**: Disable all network calls entirely.
- **`generated`**: Only allow icons that have been bundled via the CLI generator.
- **`remoteAllowed`**: Explicitly allow remote fetching in production (use responsibly).

## Performance

- **LRU Caching**: Icons are cached in memory after resolution to ensure smooth scrolling in lists.
- **Micro-batching**: Remote requests are automatically grouped by collection to minimize HTTP overhead.
- **Rasterization Cache**: Rasterized Impeller-safe images are cached to avoid redundant rendering work.

## Related Packages

- `iconify_sdk_core`: The pure Dart engine (no Flutter dependency).
- `iconify_sdk_cli`: Command-line tool for syncing and bundling icons.
- `iconify_sdk_builder`: `build_runner` integration for type-safe constants.
