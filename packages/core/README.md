# iconify_sdk_core

The pure Dart engine for Iconify icons. This package provides the core infrastructure for parsing, resolving, caching, and loading Iconify icons without any dependency on Flutter.

## Features

- **Iconify Name Parsing**: Validates and parses `prefix:icon` identifiers.
- **Iconify JSON Support**: Full support forIconify JSON format.
- **Alias Resolution**: Handles recursive aliases with circular dependency protection.
- **Flexible Providers**: Resolve icons from Memory, HTTP, File System, or Asset Bundles.
- **High Performance Caching**: LRU (Least Recently Used) in-memory cache.
- **Dev Mode Guard**: Prevents accidental remote fetches in production.
- **Zero Flutter Dependency**: Perfect for CLI tools, server-side Dart, and cross-platform apps.

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  iconify_sdk_core: ^0.1.0
```

## Usage

### Simple Icon Resolution

```dart
import 'lib/iconify_sdk_core.dart';

void main() async {
  // 1. Setup a provider (e.g., Remote)
  final provider = RemoteIconifyProvider();

  // 2. Parse an icon name
  final iconName = IconifyName.parse('mdi:home');

  // 3. Resolve icon data
  final iconData = await provider.getIcon(iconName);

  if (iconData != null) {
    // 4. Generate SVG string
    final svg = iconData.toSvgString(color: '#1a73e8', size: 24);
    print(svg);
  }
}
```

### Advanced: Composite Provider with Caching

Prioritize local icons and fallback to remote, using a cache to avoid redundant network calls.

```dart
final provider = CachingIconifyProvider(
  inner: CompositeIconifyProvider([
    MemoryIconifyProvider(),
    FileSystemIconifyProvider(root: 'assets/icons'),
    RemoteIconifyProvider(),
  ]),
  cache: LruIconifyCache(maxEntries: 500),
);
```

## Security & Ethics

By default, `RemoteIconifyProvider` blocks network requests in **Release Mode** to avoid unexpected data usage and to encourage bundling icons with the app. You can override this behavior if explicitly needed.

```dart
DevModeGuard.allowRemoteInRelease();
```

## License

MIT License - see [LICENSE](LICENSE) for details.
