# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
