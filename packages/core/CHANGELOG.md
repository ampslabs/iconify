# Changelog

## [0.2.0] - 2026-03-12

### Added
- Comprehensive documentation and package-specific README.
- Micro-benchmarks for name parsing and alias resolution.
- Hardened `IconifyJsonParser` with better error handling for malformed data.

### Changed
- Bumped version for monorepo alignment.

## [0.1.0] - 2026-03-12

### Added
- Foundational pure-Dart engine for Iconify.
- Robust models for `IconifyName`, `IconifyIconData`, `IconifyLicense`, and `IconifyCollectionInfo`.
- Provider-based architecture with support for `Memory`, `FileSystem`, and `Remote` sources.
- Comprehensive `AliasResolver` with circular dependency protection.
- High-performance LRU cache implementation.
- Detailed error hierarchy for informative failure handling.
- 100% test coverage for core logic and models.
