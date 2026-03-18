# Changelog

## [1.0.1] - 2026-03-18

### Fixed
- **Tree-Shaking**: Switched font-based rendering to use `Text` instead of `Icon(IconData)` to bypass Flutter's icon tree-shaker, enabling release builds without the `--no-tree-shake-icons` flag.
- **Assets**: Correctly registered the `starter/` icon directory in `pubspec.yaml` to ensure default icons are bundled.
- **Stability**: Prevented runtime crashes when the SDK attempts to write to the read-only `AssetBundle`.

### Added
- **Onboarding**: Added proactive console warnings in `IconifyApp` (Debug mode) to guide users toward installing and using the CLI for production optimization.

## [1.0.0] - 2026-03-16

### Added
- **Optimization**: New `IconifyPictureCache` implemented to decouple icon data from `dart:ui.Picture` lifecycle, significantly reducing re-render overhead.
- **Diagnostics**: Added `IconifyDiagnostics` to monitor cache performance (hits, misses, hit rate) in real-time.
- **Web Support**: Enhanced Flutter Web HTML renderer support via `SpriteIconifyProvider` and SVG sprite sheet optimization.
- **Native Rendering**: Added `FontIconifyProvider` to render monochrome icons as native Flutter `Icon` widgets using `.otf` fonts.
- **Bundling**: Automatic support for GZIP-compressed assets (`.gz`) across all providers.

### Changed
- Stable release version 1.0.0.
- `IconifyIcon` now uses `CachedSvgIconifyWidget` for optimized SVG management.
- Updated `IconifyApp.preload` to support background collection loading.

## [0.2.0] - 2026-03-12

### Added
- Detailed `README.md` with usage patterns and configuration guides.
- New `examples/basic` and `examples/bundled` demonstration projects.
- `docs/guides/migration-from-iconify-flutter.md` for existing Iconify users.
- `docs/guides/safe-collections.md` for licensing compliance.

### Changed
- Improved `AssetBundleIconifyProvider` reliability.

## [0.1.0] - 2026-03-12

### Added
- Core `IconifyIcon` widget for high-fidelity SVG rendering.
- `IconifyApp` entry-point for centralized provider configuration.
- Impeller-optimized rendering path with automatic rasterized fallback for color overrides.
- Built-in `Starter Registry` containing ~700 popular icons from MDI, Lucide, Tabler, and Heroicons.
- Mode-based provider chains (auto, offline, generated, remoteAllowed).
- Release-mode guard: blocks all network calls by default in production builds.
- Customizable `loadingBuilder` and `errorBuilder` for the `IconifyIcon` widget.
- Golden tests for all major renderers and Impeller support.
