# iconify_sdk

The modern, production-ready Iconify SDK for Flutter.

`iconify_sdk` brings the entire Iconify ecosystem (200,000+ open-source icons) to Flutter with a focus on developer experience, performance, and offline-first reliability.

## 📦 Packages

| Package | Purpose | Version |
|---|---|---|
| [`iconify_sdk`](packages/sdk) | **Primary Widget Library**. Start here. | [![Pub](https://img.shields.io/pub/v/iconify_sdk)](https://pub.dev/packages/iconify_sdk) |
| [`iconify_sdk_core`](packages/core) | Pure Dart engine (no Flutter dep). | [![Pub](https://img.shields.io/pub/v/iconify_sdk_core)](https://pub.dev/packages/iconify_sdk_core) |
| [`iconify_sdk_cli`](packages/cli) | CLI for syncing and auditing collections. | [![Pub](https://img.shields.io/pub/v/iconify_sdk_cli)](https://pub.dev/packages/iconify_sdk_cli) |
| [`iconify_sdk_builder`](packages/builder) | Build-time code generator for production. | [![Pub](https://img.shields.io/pub/v/iconify_sdk_builder)](https://pub.dev/packages/iconify_sdk_builder) |

## 🚀 Quick Start

```dart
// 1. Wrap your app
runApp(const IconifyApp(child: MyApp()));

// 2. Use any icon
IconifyIcon('mdi:home')
```

## 📖 Documentation

- [Production Workflow Guide](docs/guides/production-workflow.md)
- [Impeller & Rendering Path](docs/guides/impeller-notes.md)
- [Safe Icon Collections (Licenses)](docs/guides/safe-collections.md)
- [Architecture ADRs](docs/adr)

## 🛠️ Development

This is a monorepo managed with [Melos](https://melos.invert.dev/).

```bash
# Get dependencies
dart pub get
melos bootstrap

# Run tests across all packages
melos run test
```

## ⚖️ License

MIT License. See [LICENSE](LICENSE).
