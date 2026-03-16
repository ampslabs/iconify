---
title: The Production Workflow
description: A step-by-step guide to taking your Flutter app from zero-config development to a fully optimized, offline-ready production build using the Iconify SDK.
---

This guide explains how to take your Flutter app from zero-config development to a fully optimized, offline-ready production build using the Iconify SDK.

## Step 1: Development Mode (Zero Config)

When you first add the Iconify SDK, you can use any icon identifier instantly. The SDK will automatically fetch the data from the Iconify API during development.

```dart
// No setup required!
IconifyIcon('mdi:rocket')
```

- **Pros**: Instant access to 200,000+ icons.
- **Cons**: Requires network, slightly slower first-load.

## Step 2: Synchronization

Once you've decided which icon sets you're using (e.g., Material Design Icons and Lucide), synchronize the full collections to your local machine.

1. **Initialize**: Run `dart run iconify_sdk_cli:iconify init` to create your `iconify.yaml`.
2. **Sync**: Run `dart run iconify_sdk_cli:iconify sync`.

This downloads the JSON snapshots to your `assets/iconify` directory. **You should commit these snapshots to your Git repository.**

## Step 3: Local Snapshots

Now that you have local data, the SDK will prefer loading icons from your local disk instead of the API. This makes your development environment faster and more reliable.

## Step 4: Bundling for Production

For your final production build, you don't want to ship massive JSON files. The Iconify CLI provides several optimization flags to minimize bundle size and maximize performance.

### Recommended Bundling Command

```bash
# Generate optimized binary files, compressed, with font fallback
dart run iconify_sdk_cli:iconify generate --format=all --compress --font
```

### Optimization Options

| Flag | Description | Benefit |
|---|---|---|
| `--format=binary` | Generates `.iconbin` files instead of JSON. | **~3000x faster** icon lookup. |
| `--compress` | Applies GZIP compression to all assets. | **~70% reduction** in bundle size. |
| `--font` | Generates a `.otf` font for monochrome icons. | **~40% smaller** than raw SVG. |
| `--format=sprite` | Generates SVG sprite sheets (Web only). | Optimizes rendering for **Web HTML renderer**. |

## Step 5: Offline Deployment

In your `main.dart`, initialize the SDK with your optimized assets:

```dart
import 'package:flutter/material.dart';
import 'package:iconify_sdk/iconify_sdk.dart';

void main() {
  runApp(
    IconifyApp(
      config: IconifyConfig(
        compress: true, // Match your CLI --compress flag
        mode: IconifyMode.auto,
      ),
      child: MyApp(),
    ),
  );
}
```

By default, **release builds block all remote network calls**. By following this workflow, your app is now 100% offline-ready, blazing fast, and perfectly optimized for production.
