# `iconify.yaml` Configuration Specification (v1)

This document defines the configuration schema for the `iconify_sdk` project, used by the CLI and builder to manage icon bundling and code generation.

## File Location
The `iconify.yaml` file should be located in the root of your Flutter/Dart project.

## Fields

| Field | Type | Default | Description |
|---|---|---|---|
| `sets` | `List<String>` | `[]` | List of icon identifiers or patterns to include (e.g., `mdi:home`, `lucide:*`). |
| `output` | `String` | `lib/icons.g.dart` | Path for the generated Dart file containing icon data. |
| `data_dir` | `String` | `assets/iconify` | Directory where local JSON snapshots of icon sets are stored. |
| `mode` | `Enum` | `auto` | Operation mode. Options: `auto`, `offline`, `generated`, `remoteAllowed`. |
| `license_policy` | `Enum` | `warn` | How to handle attribution-required licenses. Options: `permissive`, `warn`, `strict`. |
| `custom_sets` | `List<String>` | `[]` | Paths to local JSON files for custom icon collections. |
| `fail_on_missing` | `Bool` | `false` | Whether the build should fail if an icon is not found. |

### Modes Summary
- `auto`: Uses local assets if available, falls back to remote in debug mode.
- `offline`: Only uses local assets and starter registry. No network calls.
- `generated`: Strict mode using only code-generated constants.
- `remoteAllowed`: Allows remote fetching in both debug and release builds (not recommended).

### License Policies
- `permissive`: Silently bundles all icons.
- `warn`: Bundles icons but prints warnings for those requiring attribution.
- `strict`: Fails the build if an icon requiring attribution is used without explicit approval.
