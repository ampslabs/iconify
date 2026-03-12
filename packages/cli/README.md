# iconify_sdk_cli

The command-line interface for the Iconify SDK. Manage project configuration, synchronize icon collections from GitHub, and audit your icon usage.

[![Pub Version](https://img.shields.io/pub/v/iconify_sdk_cli)](https://pub.dev/packages/iconify_sdk_cli)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

## Installation

Add the CLI to your `dev_dependencies`:

```yaml
dev_dependencies:
  iconify_sdk_cli: ^0.1.0
```

## Commands

Run these via `dart run iconify_sdk_cli:iconify <command>` or globally via `iconify <command>`.

### `init`
Initialize an `iconify.yaml` configuration file in your project.

```bash
dart run iconify_sdk_cli:iconify init
```

### `sync`
Download full icon collections from GitHub Raw source to your local data directory.

```bash
dart run iconify_sdk_cli:iconify sync
```

### `doctor`
Check the health of your Iconify setup, including missing snapshots and attribution warnings.

```bash
dart run iconify_sdk_cli:iconify doctor
```

### `generate`
Manually trigger the icon bundling process (same logic as the `build_runner` builder).

```bash
dart run iconify_sdk_cli:iconify generate
```

### `licenses`
Generate a comprehensive license and attribution report for the icons used in your app.

```bash
dart run iconify_sdk_cli:iconify licenses --format=markdown > ICON_LICENSES.md
```

## Configuration

The CLI is driven by an `iconify.yaml` file in your project root.

```yaml
sets:
  - mdi:*
  - lucide:rocket
data_dir: assets/iconify
output: lib/icons.g.dart
mode: auto
license_policy: warn
```

## License

This project is licensed under the MIT License. See the [LICENSE](../../LICENSE) file for details.
