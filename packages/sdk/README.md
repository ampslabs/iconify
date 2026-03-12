# iconify_sdk

The definitive Iconify SDK for Flutter. Instant access to 200,000+ open-source icons with zero-config setup and production-grade optimization.

[![Pub Version](https://img.shields.io/pub/v/iconify_sdk)](https://pub.dev/packages/iconify_sdk)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

## Getting Started

Add `iconify_sdk` to your `pubspec.yaml` and wrap your app in `IconifyApp`:

```dart
import 'package:flutter/material.dart';
import 'package:iconify_sdk/iconify_sdk.dart';

void main() {
  runApp(
    const IconifyApp(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          // One-liner usage. Fetches from API in debug,
          // then you bundle it for production.
          child: IconifyIcon('mdi:home', size: 48, color: Colors.blue),
        ),
      ),
    );
  }
}
```

## Key Features

- **🚀 Zero Config**: Works out of the box in Debug mode using the Iconify API.
- **📦 Offline First**: Built-in "Starter Registry" with top icons from MDI, Lucide, Tabler, and Heroicons.
- **⚡ Performance**: Impeller-optimized rendering path for stutter-free scrolling.
- **🛡️ Production Ready**: CLI and `build_runner` tools to lock your icon set and prevent network calls in release builds.
- **⚖️ License Aware**: Built-in tools to audit icon licenses and generate attribution reports.

## The Production Workflow

`iconify_sdk` is designed to be frictionless in development and rigid in production.

1. **Development**: Use any icon string (e.g., `mdi:rocket`). The SDK fetches it automatically.
2. **Sync**: Run `iconify sync` to download the full collections you're using.
3. **Bundle**: Run `build_runner build` to scan your code and generate optimized Dart constants.
4. **Deploy**: Your app now runs 100% offline with zero network overhead.

## Documentation

For advanced configuration and tooling details, see the [Full Documentation](https://github.com/ampslabs/iconify_sdk).

## License

This project is licensed under the MIT License. See the [LICENSE](../../LICENSE) file for details.
