## 0.1.0

- Initial release of the Iconify SDK Core engine.
- Implemented `IconifyName` with validation logic.
- Implemented `IconifyIconData`, `IconifyCollectionInfo`, and `IconifyLicense` models.
- Added `IconifyProvider` abstraction and implementations:
    - `MemoryIconifyProvider`
    - `RemoteIconifyProvider` (HTTP)
    - `FileSystemIconifyProvider`
    - `CompositeIconifyProvider`
    - `CachingIconifyProvider`
- Added `LruIconifyCache` for performance.
- Implemented `AliasResolver` for recursive alias handles.
- Implemented `IconifyJsonParser` for collection processing.
- Added `DevModeGuard` for production safety.
