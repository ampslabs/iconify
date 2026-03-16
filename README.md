# Iconify SDK for Flutter

The definitive Flutter SDK for Iconify. Access 200,000+ open-source icons from 100+ collections (MDI, Lucide, Phosphor, etc.) with zero-config setup and high-performance production bundling.

[![Pub Version](https://img.shields.io/pub/v/iconify_sdk)](https://pub.dev/packages/iconify_sdk)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

---

## 🚀 Key Features

- **Blistering Performance**:proprietary `.iconbin` format for zero-parsing startup and $O(\log n)$ lookup.
- **Intelligent Bundling**: Automatic GZIP compression and monochromatic font path for minimal bundle footprint.
- **Impeller Ready**: Hardware-accelerated rendering with intelligent raster fallbacks.
- **Offline-First**: Built-in "Starter Registry" and "Living Cache" system.
- **License Aware**: Automatic attribution report generation and license policy enforcement.

## 📦 Packages

| Package | Version | Description |
|---|---|---|
| [**iconify_sdk**](packages/sdk) | `1.0.0` | The primary Flutter package with the `IconifyIcon` widget. |
| [**iconify_sdk_core**](packages/core) | `1.0.0` | Pure Dart engine for Iconify (models, providers, binary format). |
| [**iconify_sdk_cli**](packages/cli) | `1.0.0` | Command-line tool for syncing, bundling, and auditing icons. |
| [**iconify_sdk_builder**](packages/builder) | `1.0.0` | `build_runner` integration for automated icon bundling. |

## 🏁 Quick Start

1. **Add dependency**:
```bash
flutter pub add iconify_sdk
```

2. **Wrap your app**:
```dart
void main() {
  runApp(
    const IconifyApp(
      child: MyApp(),
    ),
  );
}
```

3. **Use any icon**:
```dart
IconifyIcon('mdi:rocket', color: Colors.blue, size: 32)
```

## 🛡️ The Production Workflow

Iconify SDK is designed to be frictionless in development and rigid in production.

1. **Sync**: Download full collections for local development.
2. **Scan**: Automatically detect icons used in your source code.
3. **Bundle**: Produce highly optimized binary or font-based assets.
4. **Deploy**: Your app runs 100% offline with zero network overhead.

```bash
# Example production bundling command
iconify generate --format=all --compress --font
```

## 📊 Performance Baseline

| Feature | JSON (v1) | Binary (v2) | Improvement |
|---|---|---|---|
| **Startup Parse** | 29ms | 11ms | **2.6x** |
| **Icon Lookup** | 11.8ms | 3.9μs | **~3000x** |
| **Bundle Size (50 icons)** | 21KB | 6KB (GZ) | **70% reduction** |

For detailed metrics, see [docs/performance-baseline.md](docs/performance-baseline.md).

## 📄 Documentation

- [Binary Format Specification](docs/binary-format-spec.md)
- [Configuration Reference](docs/config-spec.md)
- [License Guide](docs/license-guide.md)
- [Migration Guide](docs/guides/migration-from-iconify-flutter.md)

## ⚖️ License

MIT License. See [LICENSE](LICENSE) for details.
