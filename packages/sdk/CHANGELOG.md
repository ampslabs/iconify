# Changelog

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
