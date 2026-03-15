---
title: Installation
description: How to install and add the Iconify SDK to your Flutter project.
---

This tutorial will guide you through installing the `iconify_sdk` in your Flutter project.

## 1. Add Dependencies

Add `iconify_sdk` to your `pubspec.yaml` file. If you plan to bundle icons for production (highly recommended), you should also add the CLI and Builder tools to your `dev_dependencies`.

Run the following commands in your terminal:

```bash
# Add the core SDK
flutter pub add iconify_sdk

# Add development tools for static extraction and offline support
flutter pub add dev:iconify_sdk_builder dev:iconify_sdk_cli
```

## 2. Verify pubspec.yaml

Your `pubspec.yaml` should now look something like this:

```yaml
dependencies:
  flutter:
    sdk: flutter
  iconify_sdk: ^latest_version

dev_dependencies:
  flutter_test:
    sdk: flutter
  iconify_sdk_builder: ^latest_version
  iconify_sdk_cli: ^latest_version
```

## Next Steps

Now that you have installed the necessary packages, proceed to the [Quick Start](/getting-started/quick-start/) guide to render your first icons!
