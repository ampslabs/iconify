# iconify_sdk_core

Pure Dart engine for Iconify icons. Provides models, providers, caching, and the high-performance binary format.

[![Pub Version](https://img.shields.io/pub/v/iconify_sdk_core)](https://pub.dev/packages/iconify_sdk_core)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

## Features

- **Iconify Model System**: Type-safe representations of icons, names, and collections.
- **Provider Architecture**: Pluggable data sources (Memory, FileSystem, Remote, LivingCache).
- **.iconbin Format**: A proprietary binary format optimized for zero-parsing startup and $O(\log n)$ random access lookup.
- **GZIP Support**: Built-in support for transparent decompression of icon data.
- **Alias Resolution**: Full support for Iconify's alias system with circular dependency protection.
- **Sanitization**: Integrated SVG sanitization for secure icon rendering.

## Usage

This package is intended for use by tools and other packages. For Flutter applications, use [iconify_sdk](../sdk).

```dart
import 'package:iconify_sdk_core/iconify_sdk_core.dart';

void main() async {
  // Direct binary lookup (Blisteringly fast)
  final bytes = await File('mdi.iconbin').readAsBytes();
  final icon = BinaryIconFormat.decodeIcon(bytes, 'home');
  
  print(icon?.body); // SVG path data
}
```

## License

MIT
