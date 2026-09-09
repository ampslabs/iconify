# iconify_sdk_cli

Command-line tool for the Iconify SDK. It downloads icon sets and generates
optimized Dart code from your `iconify.yaml` configuration.

## Install

```sh
dart pub global activate iconify_sdk_cli
```

## Quick start

1. Create an `iconify.yaml` (see [`iconify.yaml`](iconify.yaml) in this
   directory for a ready-to-use example):

   ```sh
   iconify init
   ```

2. Generate icon assets and code for the sets you configured:

   ```sh
   iconify generate --compress --font
   ```

   This produces `used_icons.json` (GZIP-compressed), `.iconbin` files for
   high-performance lookups, and optionally an `.otf` font for monochrome
   sets — all picked up automatically by `IconifyApp`.

3. Keep locally-synced icons up to date as you add icons to your code:

   ```sh
   iconify sync
   ```

## Available commands

| Command    | Description                                              |
| ---------- | -------------------------------------------------------- |
| `init`     | Scaffold an `iconify.yaml` and `.gitignore`               |
| `sync`     | Download the icon sets declared in `iconify.yaml`          |
| `generate` | Build optimized assets and Dart code (default command)    |
| `verify`   | Check that all icons used in code are bundled              |