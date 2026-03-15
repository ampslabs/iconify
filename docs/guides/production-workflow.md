# The Production Workflow

This guide explains how to take your Flutter app from zero-config development to a fully optimized, offline-ready production build using the Iconify SDK.

## Step 1: Development Mode (Zero Config)

When you first add the Iconify SDK, you can use any icon identifier instantly. The SDK will automatically fetch the data from the Iconify API during development.

```dart
// No setup required!
IconifyIcon('mdi:rocket')
```

*   **Pros**: Instant access to 200,000+ icons.
*   **Cons**: Requires network, slightly slower first-load.

## Step 2: Synchronization

Once you've decided which icon sets you're using (e.g., Material Design Icons and Lucide), synchronize the full collections to your local machine.

1.  **Initialize**: Run `dart run iconify_sdk_cli:iconify init` to create your `iconify.yaml`.
2.  **Sync**: Run `dart run iconify_sdk_cli:iconify sync`.

This downloads the JSON snapshots to your `assets/iconify` directory. **You should commit these snapshots to your Git repository.**

## Step 3: Local Snapshots

Now that you have local data, the SDK will prefer loading icons from your local disk instead of the API. This makes your development environment faster and more reliable.

## Step 4: Bundling for Production

For your final production build, you don't want to ship massive JSON files. Instead, use the builder to extract only the icons you've actually used.

1.  **Add Builder**: Add `iconify_sdk_builder` to your `dev_dependencies`.
2.  **Generate**: Run `dart run build_runner build`.

This creates `lib/icons.g.dart` containing type-safe Dart constants for your specific icon set.

## Step 5: Offline Deployment

In your `main.dart`, initialize the generated icons:

```dart
import 'icons.g.dart';

void main() {
  // Populates the memory provider with your bundled icons
  final memoryProvider = MemoryIconifyProvider();
  initGeneratedIcons(memoryProvider);

  runApp(
    IconifyApp(
      config: IconifyConfig(
        customProviders: [memoryProvider],
      ),
      child: MyApp(),
    ),
  );
}
```

By default, **release builds block all remote network calls**. By following this workflow, your app is now 100% offline-ready and perfectly optimized.

## Step 6: Security & CI

To ensure your supply chain is secure and that you are complying with icon licenses, you can add these steps to your CI pipeline:

1.  **Verify Integrity**: Run `dart run iconify verify` to ensure your local icon snapshots match the upstream versions and have not been tampered with.
2.  **Enforce Licenses**: Run `dart run iconify generate --strict-licenses` as a pre-build step. This will cause the CI to fail if any used icons require attribution, ensuring you don't accidentally ship icons that violate their license terms without proper attribution.
3.  **Audit Attribution**: Check the auto-generated `ICON_ATTRIBUTION.md` in your project root to see a consolidated list of all icons requiring attribution.

