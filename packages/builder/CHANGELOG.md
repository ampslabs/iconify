# Changelog

## [1.1.0] - 2026-09-09

### Changed
- Bumped Dart SDK constraint to `>=3.10.0 <4.0.0`.
- Updated dependencies (`build` 4.0.11, `analyzer` 13.3.0, `glob` 2.2.0, `yaml` 3.1.4, `build_runner` 2.16.1).
- Reformatted with the current `dart format` (tall style).

## [1.0.1] - 2026-03-18

### Changed
- Version alignment with SDK 1.0.1.

## [1.0.0] - 2026-03-16

### Changed
- Stable release version 1.0.0.
- SDK optimizations.

## [0.2.0] - 2026-03-12

### Added
- Expanded documentation and usage examples.
- Better integration tests for code generation.

### Changed
- Refined `IconNameScanner` AST-based detection for edge cases.

## [0.1.0] - 2026-03-12

### Added
- `build_runner` integration for automatic icon bundling.
- Hybrid AST + Regex scanner for detecting `IconifyIcon` usages in Dart source code.
- Optimized code generator for producing type-safe Dart constants.
- Full support for the `iconify.yaml` configuration specification.
- Seamless integration with the core memory provider.
