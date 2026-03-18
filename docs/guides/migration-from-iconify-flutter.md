# Migrating from `iconify_flutter`

This guide helps you migrate your project from the legacy (and now archived) `iconify_flutter` package to the modern `iconify_sdk`.

## Key Differences

| Feature | `iconify_flutter` | `iconify_sdk` |
|---|---|---|
| **Rendering** | Direct SVG | Hybrid (SVG + Raster fallback for Impeller) |
| **Offline** | Manual download of large classes | Automatic bundling of only used icons |
| **Performance** | Basic | Optimized with LRU caching & pure Dart core |
| **CLI** | None | Full suite for syncing and auditing |

## Migration Steps

### 1. Update Dependencies

Remove the old package and add the new one:

```yaml
# pubspec.yaml
dependencies:
  # iconify_flutter: ^0.1.0 <-- Remove
  iconify_sdk: ^1.0.0
```

### 2. Add the App Wrapper

Wrap your root widget in `IconifyApp`. This replaces the need for any manual initialization.

```dart
// main.dart
void main() {
  runApp(const IconifyApp(child: MyApp()));
}
```

### 3. Update Widget Names

Rename `Iconify(...)` widgets to `IconifyIcon(...)`. The parameters are mostly compatible.

```dart
// OLD
Iconify(Mdi.home, color: Colors.blue)

// NEW (Dynamic string)
IconifyIcon('mdi:home', color: Colors.blue)

// NEW (Type-safe bundled)
IconifyIcon.name(IconsMdi.home, color: Colors.blue)
```

### 4. Adopt the CLI Workflow

Instead of manually maintaining massive icon data classes, use the new bundling workflow:

1.  Run `dart run iconify_sdk_cli:iconify init`
2.  Run `dart run iconify_sdk_cli:iconify sync`
3.  Add `iconify_sdk_builder` to `dev_dependencies`
4.  Run `dart run build_runner build`

This will generate a tiny, optimized `lib/icons.g.dart` file containing only the icons your app actually uses.
