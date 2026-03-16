# Changelog

## [1.0.0] - 2026-03-16

### Added
- **Optimization Flags**:
  - `--format=binary`: Generates high-performance `.iconbin` files.
  - `--format=sprite`: Generates SVG sprite sheets for Web HTML optimization.
  - `--compress`: Automatically applies GZIP compression to all generated assets.
  - `--font`: Generates `.otf` icon fonts for monochromatic icon sets.
- **Manifest Generation**: Automatic creation of `icons.sprite.json` and `icons.font.json` for SDK provider synchronization.

### Changed
- Stable release version 1.0.0.
- `generate` command now supports background processing for large collection encoding.

## [0.2.0] - 2026-03-12

### Added
- `README.md` with full command reference.
- `docs/guides/production-workflow.md` documenting the end-to-end CLI usage.
- Improved output formatting for `iconify doctor` and `iconify licenses`.

### Changed
- CLI tool name alignment.

## [0.1.0] - 2026-03-12

### Added
- Unified CLI runner for managing Iconify icon sets.
- `init` command for interactive project setup.
- `sync` command for high-speed multi-collection synchronization from GitHub.
- `doctor` command for project health and configuration auditing.
- `generate` command for manual icon bundling and code generation.
- `licenses` command for generating legal attribution reports.
- Comprehensive end-to-end integration test suite.
