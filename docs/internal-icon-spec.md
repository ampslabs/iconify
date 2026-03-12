# Internal Icon Schema Definition

This document defines the normalized internal schema used by `iconify_sdk_core` to represent icon collections and individual icons. This schema is a subset of the official Iconify JSON format, optimized for the Dart SDK.

## Collection Object

```json
{
  "schemaVersion": 1,
  "prefix": "mdi",
  "info": {
    "name": "Material Design Icons",
    "author": "Google",
    "license": {
      "title": "Apache 2.0",
      "spdx": "Apache-2.0",
      "url": "https://www.apache.org/licenses/LICENSE-2.0"
    },
    "samples": ["home", "account"],
    "total": 7000
  },
  "icons": {
    "home": {
      "body": "<path ... />",
      "width": 24,
      "height": 24
    }
  },
  "aliases": {
    "house": {
      "parent": "home"
    }
  },
  "width": 24,
  "height": 24
}
```

## Key Components

### 1. `info` (IconifyCollectionInfo)
Contains metadata about the set, primarily used for license tracking and attribution hints.
- `spdx`: Standard identifier (e.g., `MIT`, `Apache-2.0`). Critical for `license_policy` enforcement.

### 2. `icons` (Map<String, IconifyIconData>)
The raw path data and dimensions.
- `body`: The SVG path data without the `<svg>` tag.
- `width`/`height`: Viewbox dimensions (internal fallback to collection-level defaults).

### 3. `aliases` (Map<String, AliasEntry>)
Maps secondary names to parent icons.
- `parent`: The target icon name or another alias (supports chaining).
- Overrides: Redefines `width`, `height`, `rotate`, `hFlip`, `vFlip` for the specific alias.

### 4. `width` / `height` (Collection Defaults)
Default dimensions applied to all icons in the collection if they don't specify their own.
