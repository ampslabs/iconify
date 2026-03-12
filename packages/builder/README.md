# iconify_sdk_builder

The code generator for the Iconify SDK. Automatically bundles icons into type-safe Dart constants for 100% offline production builds.

[![Pub Version](https://img.shields.io/pub/v/iconify_sdk_builder)](https://pub.dev/packages/iconify_sdk_builder)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

## Overview

This package is a `build_runner` extension that scans your Flutter source code for `IconifyIcon(...)` usages. It resolves the required icon data from your local snapshots and generates a `lib/icons.g.dart` file.

## Setup

Add the builder to your `dev_dependencies`:

```yaml
dev_dependencies:
  iconify_sdk_builder: ^0.2.0
  build_runner: ^2.4.0
```

## Usage

Run the build command:

```bash
dart run build_runner build
```

The builder will look for an `iconify.yaml` file in your project root to determine where your local icon snapshots are stored and where to write the generated code.

### Example `iconify.yaml`

```yaml
sets:
  - mdi:*
  - lucide:rocket
data_dir: assets/iconify
output: lib/icons.g.dart
```

## How it Works

1. **Scanning**: It uses a hybrid AST + Regex scanner to find icon identifiers like `'mdi:home'` in your `.dart` files.
2. **Resolution**: It searches your `data_dir` for the corresponding Iconify JSON snapshots.
3. **Generation**: It produces a type-safe Dart file containing only the icons you've actually used, ensuring zero-waste bundles.

## Limitations

- **Literal Strings Only**: The scanner currently only detects icons passed as literal strings (e.g., `IconifyIcon('mdi:home')`). It cannot detect icons assigned to variables or constructed dynamically at runtime.

## License

This project is licensed under the MIT License. See the [LICENSE](../../LICENSE) file for details.
