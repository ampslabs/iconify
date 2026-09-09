# iconify_sdk example

A minimal Flutter app that renders icons with the `iconify_sdk` package.

![iconify_sdk](https://img.shields.io/badge/status-example-blue)

## Getting started

Create the platform scaffolding and run the app:

```sh
flutter create . --platforms=ios,android,macos,linux,windows,web
flutter run
```

No setup is required: the SDK ships with a starter icon set (a small subset
of MDI, Lucide, Tabler, and Heroicons), so the icons on screen render
immediately.

## Go further

In a real app you will usually want your *own* icon sets bundled with the app
for offline rendering and optimal bundle size:

```sh
# 1. Define the icon sets you use in `iconify.yaml` (see the root docs).
# 2. Install the CLI and generate an optimized bundle:
dart pub global activate iconify_sdk_cli
iconify generate --compress --font
```

The generated `used_icons.json` (optionally GZIP-compressed) is picked up
automatically by `IconifyApp` in release mode.