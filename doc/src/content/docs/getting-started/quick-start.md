---
title: Quick Start
description: Get up and running quickly with Iconify SDK in your Flutter application.
---

This tutorial will show you how to render your first icon using the `iconify_sdk`. We will start with the zero-configuration development mode, which requires an internet connection to fetch icon data the first time.

## 1. Wrap Your App

The SDK requires an `IconifyApp` wrapper at the root of your application. This sets up the necessary providers, caching, and state management for icons to render smoothly.

Open your `main.dart` and wrap your `MyApp` widget:

```dart
import 'package:flutter/material.dart';
import 'package:iconify_sdk/iconify_sdk.dart';

void main() {
  runApp(
    // 1. Initialize IconifyApp to manage caching and providers
    const IconifyApp(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Iconify Quick Start')),
        body: const Center(
           // Your icons will go here!
        ),
      ),
    );
  }
}
```

## 2. Render an Icon

To display an icon, use the `IconifyIcon` widget and provide the global Iconify string identifier (e.g., `mdi:home`).

```dart
import 'package:flutter/material.dart';
import 'package:iconify_sdk/iconify_sdk.dart';

class MyHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      // 2. Simply type any icon identifier to fetch and render it!
      child: IconifyIcon(
        'lucide:rocket', 
        size: 64,
        color: Colors.blue,
      ),
    );
  }
}
```

When you run your application, the `lucide:rocket` icon will render seamlessly!

## Understanding Zero-Config Mode

In zero-config mode, the SDK fetches the SVG data for `lucide:rocket` over the network and caches it. While this is great for rapid prototyping, it is **not recommended for production**.

## Next Steps

To make your app offline-ready, blazing fast, and safe for production releases, read our [Production Workflow](/guides/production-workflow/) guide.
