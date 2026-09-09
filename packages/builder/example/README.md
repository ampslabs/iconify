# iconify_sdk_builder

Code generator and `build_runner` builder for the Iconify SDK. It turns the
icon references found in your Dart source into type-safe, tree-shakeable
constants via `icons.g.dart`.

## Typical workflow

1. **Define the icon sets** you use in an `iconify.yaml` at the project root:

   ```yaml
   sets:
     - mdi:*
     - lucide:*
     - fa6-solid:*

   data_dir: assets/iconify
   output: lib/icons.g.dart
   mode: auto
   ```

2. **Generate icon assets** with the CLI (or any tool that writes the icon
   data for `data_dir`):

   ```sh
   dart pub global activate iconify_sdk_cli
   iconify generate --compress --font
   ```

3. **Run the builder** to (re)generate Dart constants whenever your source
   changes:

   ```sh
   dart run build_runner build --delete-conflicting-outputs
   ```

## Programmatic usage

See [`main.dart`](main.dart) for a self-contained example of the scanner and
code generator APIs without a full build setup:

```sh
dart run example/main.dart
```