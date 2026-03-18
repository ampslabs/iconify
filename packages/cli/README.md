# iconify_sdk_cli

Command-line interface for the Iconify SDK. Manage, synchronize, and bundle icons for production with zero-friction.

[![Pub Version](https://img.shields.io/pub/v/iconify_sdk_cli)](https://pub.dev/packages/iconify_sdk_cli)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

## Installation

```bash
dart pub global activate iconify_sdk_cli
```

## Usage

Just run `iconify` in your Flutter project root. The tool will intelligently handle everything:

1.  **Auto-Init**: Prompts to create `iconify.yaml` if missing.
2.  **Auto-Scan**: Scans your `lib/` directory for icon usages.
3.  **JIT Sync**: Proactively downloads missing icon collections.
4.  **Optimized Bundle**: Generates binary, font, and JSON assets.

```bash
# One-command optimization
iconify
```

## Commands

### `init`
Initialize Iconify in your project. Creates `iconify.yaml`.

### `sync`
Synchronize icon collections from GitHub to your local snapshot directory.
```bash
iconify sync
```

### `generate`
Bundle the icons used in your source code into optimized formats.
```bash
iconify generate --format=all --compress --font
```
- `--format=binary`: Create high-speed `.iconbin` files.
- `--format=sprite`: Create SVG sprite sheets for Web.
- `--compress`: Apply GZIP compression to all outputs (~70% reduction).
- `--font`: Generate an icon font for monochrome icons.

### `licenses`
Generate an `ICON_ATTRIBUTION.md` file based on the icons used in your project.

### `doctor`
Check your project configuration and local snapshots for issues.

## License

MIT
