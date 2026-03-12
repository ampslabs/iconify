# iconify_sdk_core

The high-performance, pure-Dart engine behind the Iconify SDK for Flutter.

[![Pub Version](https://img.shields.io/pub/v/iconify_sdk_core)](https://pub.dev/packages/iconify_sdk_core)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

## Overview

`iconify_sdk_core` provides the foundational logic for parsing, caching, and resolving icons from the [Iconify](https://iconify.design/) ecosystem. It is built with zero dependencies on Flutter, making it suitable for CLI tools, server-side Dart, or shared logic in monorepos.

## Key Features

- **Blazing Fast**: Benchmarked to parse 100,000 icon names in under 15ms.
- **Alias Resolution**: Fully supports Iconify's alias system with circular dependency protection.
- **LRU Caching**: Memory-efficient icon caching out of the box.
- **Provider Pattern**: Modular architecture for loading icons from Memory, File System, or Remote sources.
- **Type-Safe Models**: Robust models for Icon Data, Collection Metadata, and License information.

## Getting Started

```dart
import 'package:iconify_sdk_core/iconify_sdk_core.dart';

void main() async {
  // 1. Parse a canonical icon name
  final name = IconifyName.parse('mdi:home');

  // 2. Setup a provider (e.g., Memory)
  final provider = MemoryIconifyProvider();
  provider.putIcon(name, const IconifyIconData(body: '<path d="..." />'));

  // 3. Retrieve icon data
  final icon = await provider.getIcon(name);
  
  if (icon != null) {
    print('SVG Body: ${icon.body}');
    print('SVG String: ${icon.toSvgString(color: 'red', size: 32)}');
  }
}
```

## Architecture

This package is designed around the `IconifyProvider` interface. You can compose multiple providers using `CompositeIconifyProvider` to create complex loading strategies (e.g., Memory -> Local Disk -> Remote).

## License

This project is licensed under the MIT License. See the [LICENSE](../../LICENSE) file for details.
