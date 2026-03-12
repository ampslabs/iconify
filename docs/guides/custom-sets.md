# Custom Icon Sets

The Iconify SDK allows you to easily integrate your own proprietary or custom-designed icons alongside the standard open-source collections.

## Option 1: Using the CLI `sync` (Recommended)

The easiest way to add custom icons is to provide them in the standard Iconify JSON format.

1.  **Prepare your JSON**: Create a JSON file (e.g., `my_icons.json`) following the [Iconify JSON Specification](https://iconify.design/docs/types/iconify-json.html).
2.  **Add to `iconify.yaml`**:
    ```yaml
    custom_sets:
      - data/custom/my_icons.json
    ```
3.  **Generate**: Run `dart run build_runner build`.

The builder will automatically pick up your custom icons and generate type-safe constants for them.

## Option 2: Manual Memory Injection

If you prefer to load icons dynamically at runtime, you can inject them directly into a `MemoryIconifyProvider`.

```dart
final customProvider = MemoryIconifyProvider();

customProvider.putIcon(
  const IconifyName('custom', 'logo'),
  const IconifyIconData(
    body: '<path d="..." fill="currentColor"/>',
    width: 24,
    height: 24,
  ),
);

// Add to your IconifyApp
IconifyApp(
  config: IconifyConfig(
    customProviders: [customProvider],
  ),
  child: MyApp(),
)
```

## Creating Iconify JSON

You can use the [Iconify Tools](https://github.com/iconify/tools) (Node.js) to convert a folder of SVG files into a standard Iconify JSON collection. This is the best way to manage large internal icon libraries.
