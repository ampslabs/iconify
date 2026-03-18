# Changelog

## [1.0.1] - 2026-03-18

### Added
- **Zero-Friction DX**:
  - The `iconify` command now defaults to `generate` when run without arguments.
  - **Auto-Init**: All commands now proactively offer to initialize `iconify.yaml` if it's missing.
  - **JIT Syncing**: The `generate` command automatically detects icons in source code that lack local snapshots and offers to sync them immediately.
- **Enhanced Testing**: Added new integration tests for Auto-Init and JIT Sync workflows.

### Changed
- Refactored CLI architecture to use a unified `BaseCommand` for consistent setup and syncing logic.

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
