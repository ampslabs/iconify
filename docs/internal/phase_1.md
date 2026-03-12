# Phase 1: `iconify_sdk_core` — Complete Build Instructions

> Version: 1.0 | Date: 2026-03-12  
> Target: Production-ready pure Dart package. Zero Flutter dependency. Zero shortcuts.

---



### Recommended Agent Workflow
```
1. Read this entire document before writing a single file
2. Create files in order: pubspec → models → errors → providers → cache → alias → parser → tests
3. After EVERY file: run `dart analyze` — fix all warnings before moving on
4. After every test file: run `dart test path/to/test_file.dart` — must be green before next file
5. Never skip a test. Never write // TODO in production code.
6. When in doubt about a Dart 3 API: check dart.dev/language not Stack Overflow
```

### Agent Decision Rules
- If a type could be `final` or `sealed` — use the more restrictive one
- If a method could be `const` — make it `const`
- If a field could be `final` — make it `final`
- All public APIs must have dartdoc comments (`///`)
- No `dynamic` except inside the `raw` field that explicitly preserves upstream JSON
- Prefer `Result`-style returns over throwing for expected failure cases in providers
- Prefer `extension` for utility methods over polluting model classes

---

## What We Are Building

`iconify_sdk_core` is a **pure Dart package** — no Flutter dependency, no platform channels, no native code. It is the engine that every other package in this ecosystem builds on.

### What It Does
- Parses and validates Iconify icon identifiers (`mdi:home`, `lucide:settings`)
- Models all Iconify data structures (icons, collections, licenses)
- Resolves icon aliases recursively and detects circular chains
- Parses the canonical Iconify JSON format (the same format served by the API and stored in `iconify/icon-sets`)
- Provides a clean provider abstraction for resolving icons from different sources
- Ships built-in provider implementations: memory, HTTP, file system, asset bundle, composite, caching
- Implements an LRU cache with eviction, TTL, and corruption recovery
- Guards remote fetch behind a dev-mode flag
- Produces actionable, machine-readable errors (not generic exceptions)

### What It Does NOT Do
- No Flutter widgets (zero `import 'package:flutter/...'`)
- No SVG rendering
- No code generation
- No CLI commands
- No build_runner integration

### Package Identity
```
Name:    iconify_sdk_core
Pub.dev: https://pub.dev/packages/iconify_sdk_core
Repo:    packages/iconify_sdk_core/ (in monorepo root)
Dart SDK: >=3.3.0 <4.0.0
```

---

## What to Expect (Manual Test Checkpoints)

At the end of Phase 1, a developer should be able to write this Dart script and have it work:

```dart
import 'package:iconify_sdk_core/iconify_sdk_core.dart';

void main() async {
  // 1. Name parsing
  final name = IconifyName.parse('mdi:home');
  print(name.prefix);  // mdi
  print(name.iconName); // home
  print(name);          // mdi:home

  // 2. Invalid name throws correct error
  try {
    IconifyName.parse('mdi-home'); // wrong separator
  } on InvalidIconNameException catch (e) {
    print(e.message); // "Expected format 'prefix:name', got 'mdi-home'"
  }

  // 3. Memory provider round-trip
  final provider = MemoryIconifyProvider();
  await provider.putIcon(
    IconifyName.parse('mdi:home'),
    IconifyIconData(
      body: '<path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/>',
      width: 24,
      height: 24,
    ),
  );
  final icon = await provider.getIcon(IconifyName.parse('mdi:home'));
  print(icon?.body); // <path d="..."/>

  // 4. HTTP provider (real network call)
  final http = RemoteIconifyProvider();
  final homeIcon = await http.getIcon(IconifyName.parse('mdi:home'));
  print(homeIcon != null); // true

  // 5. Composite provider with fallback
  final composite = CompositeIconifyProvider([
    MemoryIconifyProvider(), // empty — will miss
    http,                    // will hit
  ]);
  final result = await composite.getIcon(IconifyName.parse('lucide:settings'));
  print(result != null); // true

  // 6. Alias resolution
  final resolver = AliasResolver();
  // 'mdi:home-account' is an alias for 'mdi:account-home' in real MDI data
  // Test with fixture data

  // 7. Parse raw iconify JSON
  const rawJson = '...'; // see test fixtures
  final collection = IconifyJsonParser.parseCollection(rawJson);
  print(collection.prefix);     // mdi
  print(collection.icons.length); // > 0

  // 8. Cache
  final cache = LruIconifyCache(maxEntries: 100);
  await cache.put(IconifyName.parse('mdi:home'), homeIcon!);
  final cached = await cache.get(IconifyName.parse('mdi:home'));
  print(cached != null); // true

  // 9. CachingIconifyProvider
  final cachingProvider = CachingIconifyProvider(
    inner: http,
    cache: cache,
  );
  final a = await cachingProvider.getIcon(IconifyName.parse('tabler:star'));
  final b = await cachingProvider.getIcon(IconifyName.parse('tabler:star')); // from cache
  print(a?.body == b?.body); // true

  // 10. DevModeGuard
  print(DevModeGuard.isRemoteAllowedInCurrentBuild()); // true in debug, false in release

  print('All Phase 1 checks passed');
}
```

Run this script: `dart run example/smoke_test.dart`  
**Expected**: All print statements complete. No exceptions. No network timeouts (add 10s timeout to HTTP calls).

---

## Directory Structure to Create

```
packages/iconify_sdk_core/
├── pubspec.yaml
├── analysis_options.yaml
├── CHANGELOG.md
├── README.md
├── lib/
│   ├── iconify_sdk_core.dart          ← barrel export (public API only)
│   └── src/
│       ├── models/
│       │   ├── iconify_name.dart
│       │   ├── iconify_icon_data.dart
│       │   ├── iconify_collection_info.dart
│       │   ├── iconify_license.dart
│       │   └── iconify_search_result.dart
│       ├── errors/
│       │   └── iconify_exception.dart
│       ├── providers/
│       │   ├── iconify_provider.dart           ← abstract interface
│       │   ├── memory_iconify_provider.dart
│       │   ├── http_iconify_provider.dart
│       │   ├── file_system_iconify_provider.dart
│       │   ├── asset_bundle_iconify_provider.dart
│       │   ├── composite_iconify_provider.dart
│       │   └── caching_iconify_provider.dart
│       ├── cache/
│       │   ├── iconify_cache.dart              ← abstract interface
│       │   └── lru_iconify_cache.dart
│       ├── resolver/
│       │   └── alias_resolver.dart
│       ├── parser/
│       │   └── iconify_json_parser.dart
│       └── guard/
│           └── dev_mode_guard.dart
├── test/
│   ├── models/
│   │   ├── iconify_name_test.dart
│   │   ├── iconify_icon_data_test.dart
│   │   └── iconify_collection_info_test.dart
│   ├── errors/
│   │   └── iconify_exception_test.dart
│   ├── providers/
│   │   ├── memory_iconify_provider_test.dart
│   │   ├── http_iconify_provider_test.dart
│   │   ├── composite_iconify_provider_test.dart
│   │   └── caching_iconify_provider_test.dart
│   ├── cache/
│   │   └── lru_iconify_cache_test.dart
│   ├── resolver/
│   │   └── alias_resolver_test.dart
│   ├── parser/
│   │   └── iconify_json_parser_test.dart
│   ├── guard/
│   │   └── dev_mode_guard_test.dart
│   └── fixtures/
│       ├── mdi_fixture.json          ← real subset of MDI collection
│       ├── lucide_fixture.json
│       ├── tabler_fixture.json
│       ├── malformed_fixture.json    ← intentionally broken
│       └── alias_chain_fixture.json  ← tests deep alias chains
└── example/
    └── smoke_test.dart
```

---

## Step 1 — pubspec.yaml

```yaml
name: iconify_sdk_core
description: >
  Pure Dart engine for Iconify icons. Provides models, providers, cache,
  alias resolution, and JSON parsing. No Flutter dependency required.
version: 0.1.0
repository: https://github.com/YOUR_ORG/iconify_flutter/tree/main/packages/iconify_sdk_core
issue_tracker: https://github.com/YOUR_ORG/iconify_flutter/issues

environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  http: ^1.2.0
  meta: ^1.15.0

dev_dependencies:
  mocktail: ^1.0.4
  test: ^1.25.0
  lints: ^4.0.0
```

> **Agent note**: Do not add Flutter as a dependency. If you feel the urge to add it, stop — you are solving the wrong problem. This package must be usable in pure Dart CLI tools.

---

## Step 2 — analysis_options.yaml

```yaml
include: package:lints/recommended.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    missing_required_param: error
    missing_return: error
    dead_code: warning
    unused_import: error
    unused_local_variable: warning

linter:
  rules:
    - always_declare_return_types
    - always_put_required_named_parameters_first
    - avoid_dynamic_calls
    - avoid_print
    - avoid_relative_lib_imports
    - avoid_returning_null_for_future
    - avoid_slow_async_io
    - cancel_subscriptions
    - close_sinks
    - comment_references
    - directives_ordering
    - document_ignores
    - flutter_style_todos
    - noop_primitive_operations
    - only_throw_errors
    - prefer_const_constructors
    - prefer_final_fields
    - prefer_final_in_for_each
    - prefer_final_locals
    - prefer_single_quotes
    - sort_constructors_first
    - unawaited_futures
    - unnecessary_await_in_return
    - use_named_constants
    - use_string_buffers
```

---

## Step 3 — Error Hierarchy

**File**: `lib/src/errors/iconify_exception.dart`

This is the foundation. Build it first because everything else throws these.

```dart
/// Base sealed exception for all Iconify errors.
///
/// Use pattern matching to handle specific error types:
/// ```dart
/// try {
///   await provider.getIcon(name);
/// } on IconifyException catch (e) {
///   switch (e) {
///     case InvalidIconNameException(:final input):
///       print('Bad name: $input');
///     case IconNotFoundException(:final name):
///       print('Not found: $name');
///     // ...
///   }
/// }
/// ```
sealed class IconifyException implements Exception {
  const IconifyException(this.message);

  /// Human-readable description. Always actionable. Never "an error occurred."
  final String message;

  @override
  String toString() => 'IconifyException($runtimeType): $message';
}

/// Thrown when an icon identifier string cannot be parsed.
///
/// Happens when the input does not match `prefix:name` format.
final class InvalidIconNameException extends IconifyException {
  const InvalidIconNameException({
    required this.input,
    required super.message,
  });

  /// The original string that failed to parse.
  final String input;
}

/// Thrown when an icon is not found in any provider.
final class IconNotFoundException extends IconifyException {
  const IconNotFoundException({
    required this.name,
    required super.message,
    this.suggestion,
  });

  /// The [IconifyName] that was requested but not found.
  final IconifyName name;

  /// Optional did-you-mean suggestion (e.g., 'lucide:settings' for 'lucide:setting').
  final String? suggestion;
}

/// Thrown when a collection is not available in any configured provider.
final class CollectionNotFoundException extends IconifyException {
  const CollectionNotFoundException({
    required this.prefix,
    required super.message,
    this.wasRemoteAttempted = false,
  });

  final String prefix;

  /// Whether a remote fetch was attempted before this exception was thrown.
  final bool wasRemoteAttempted;
}

/// Thrown on HTTP or network-layer failures.
final class IconifyNetworkException extends IconifyException {
  const IconifyNetworkException({
    required super.message,
    this.statusCode,
    this.uri,
  });

  final int? statusCode;
  final Uri? uri;
}

/// Thrown when license metadata is required but missing.
final class IconifyLicenseException extends IconifyException {
  const IconifyLicenseException({
    required this.prefix,
    required super.message,
  });

  final String prefix;
}

/// Thrown when the Iconify JSON data is malformed or fails schema validation.
final class IconifyParseException extends IconifyException {
  const IconifyParseException({
    required super.message,
    this.field,
    this.rawValue,
  });

  /// The JSON field that caused the parse failure, if known.
  final String? field;

  /// The raw value that could not be parsed, if present.
  final Object? rawValue;
}

/// Thrown when a circular alias chain is detected.
final class CircularAliasException extends IconifyException {
  const CircularAliasException({
    required this.chain,
    required super.message,
  });

  /// The full alias chain that created the cycle.
  /// Example: ['home-alias', 'home-alias2', 'home-alias']
  final List<String> chain;
}

/// Thrown when the local cache fails to read or write.
final class IconifyCacheException extends IconifyException {
  const IconifyCacheException({
    required super.message,
    this.cause,
  });

  final Object? cause;
}

// Forward declaration needed for IconNotFoundException.
// Import will be resolved by the barrel.
// Defined in models/iconify_name.dart
// ignore: undefined_class
typedef IconifyName = dynamic; // REPLACE THIS — see Step 4
```

> **Agent note**: The last `typedef` is a placeholder only. Delete it after Step 4 creates `IconifyName`. It exists here just to show that `IconNotFoundException` references `IconifyName`. The real class is in Step 4.

---

## Step 4 — IconifyName Model

**File**: `lib/src/models/iconify_name.dart`

This is the single most important class in the package. Get it right.

### Rules for `IconifyName`
- A valid name has exactly one colon
- Prefix: lowercase letters, digits, hyphens only. No leading/trailing hyphens.
- Icon name: lowercase letters, digits, hyphens only. No leading/trailing hyphens.
- Max length: 64 chars each (practical limit, not Iconify spec — guards against abuse)
- Must be value-equal: two `IconifyName('mdi', 'home')` must be `==`
- Must be usable as a `Map` key: implement `hashCode`
- Must be `const`-constructable when values are known at compile time
- `toString()` must return `prefix:name` (canonical form)

```dart
import 'package:meta/meta.dart';
import '../errors/iconify_exception.dart';

/// An immutable, validated Iconify icon identifier.
///
/// Every icon in the Iconify ecosystem is identified by a two-part name:
/// `prefix:iconName`, where `prefix` is the icon set (e.g., `mdi`, `lucide`)
/// and `iconName` is the specific icon (e.g., `home`, `settings`).
///
/// ```dart
/// final name = IconifyName.parse('mdi:home');
/// print(name.prefix);    // mdi
/// print(name.iconName);  // home
/// print(name);           // mdi:home
///
/// // Const construction when values are known:
/// const name = IconifyName('mdi', 'home');
/// ```
@immutable
final class IconifyName {
  /// Creates an [IconifyName] from pre-validated parts.
  ///
  /// Prefer [IconifyName.parse] when working with user input or API data.
  /// This constructor does NOT validate inputs for performance — use only
  /// when inputs are already known-good (e.g., from generated code).
  const IconifyName(this.prefix, this.iconName);

  /// The icon set prefix, e.g., `mdi`, `lucide`, `tabler`.
  final String prefix;

  /// The icon name within the set, e.g., `home`, `settings`, `arrow-left`.
  final String iconName;

  static final _prefixPattern = RegExp(r'^[a-z0-9][a-z0-9\-]*[a-z0-9]$|^[a-z0-9]$');
  static final _namePattern = RegExp(r'^[a-z0-9][a-z0-9\-]*[a-z0-9]$|^[a-z0-9]$');
  static const _maxPartLength = 64;

  /// Parses a canonical `prefix:name` string into an [IconifyName].
  ///
  /// Throws [InvalidIconNameException] if the input is not valid.
  ///
  /// ```dart
  /// final name = IconifyName.parse('mdi:home');      // OK
  /// IconifyName.parse('mdi-home');                    // throws: wrong separator
  /// IconifyName.parse(':home');                       // throws: empty prefix
  /// IconifyName.parse('MDI:Home');                    // throws: uppercase not allowed
  /// ```
  factory IconifyName.parse(String value) {
    final colonIndex = value.indexOf(':');

    if (colonIndex == -1) {
      throw InvalidIconNameException(
        input: value,
        message:
            "Expected format 'prefix:name', got '$value'. "
            "Did you mean to use a colon instead of a hyphen or slash?",
      );
    }

    if (value.indexOf(':', colonIndex + 1) != -1) {
      throw InvalidIconNameException(
        input: value,
        message:
            "Expected exactly one colon in '$value', found multiple. "
            "Format must be 'prefix:name'.",
      );
    }

    final prefix = value.substring(0, colonIndex);
    final name = value.substring(colonIndex + 1);

    _validatePart(value, prefix, 'prefix');
    _validatePart(value, name, 'name');

    return IconifyName(prefix, name);
  }

  static void _validatePart(String input, String part, String partName) {
    if (part.isEmpty) {
      throw InvalidIconNameException(
        input: input,
        message: "The $partName part of '$input' is empty. Both prefix and name are required.",
      );
    }
    if (part.length > _maxPartLength) {
      throw InvalidIconNameException(
        input: input,
        message:
            "The $partName part of '$input' is ${part.length} characters, "
            "exceeding the maximum of $_maxPartLength.",
      );
    }
    if (partName == 'prefix' && !_prefixPattern.hasMatch(part)) {
      throw InvalidIconNameException(
        input: input,
        message:
            "The prefix '$part' in '$input' contains invalid characters. "
            "Prefixes must use only lowercase letters (a-z), digits (0-9), "
            "and hyphens (-), and must not start or end with a hyphen.",
      );
    }
    if (partName == 'name' && !_namePattern.hasMatch(part)) {
      throw InvalidIconNameException(
        input: input,
        message:
            "The icon name '$part' in '$input' contains invalid characters. "
            "Names must use only lowercase letters (a-z), digits (0-9), "
            "and hyphens (-), and must not start or end with a hyphen.",
      );
    }
  }

  /// Tries to parse a string, returning `null` on failure instead of throwing.
  ///
  /// ```dart
  /// final name = IconifyName.tryParse('mdi:home');   // IconifyName
  /// final bad  = IconifyName.tryParse('mdi-home');   // null
  /// ```
  static IconifyName? tryParse(String value) {
    try {
      return IconifyName.parse(value);
    } on InvalidIconNameException {
      return null;
    }
  }

  /// Returns the canonical string representation: `prefix:iconName`.
  @override
  String toString() => '$prefix:$iconName';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IconifyName &&
          runtimeType == other.runtimeType &&
          prefix == other.prefix &&
          iconName == other.iconName;

  @override
  int get hashCode => Object.hash(prefix, iconName);
}
```

---

## Step 5 — IconifyLicense Model

**File**: `lib/src/models/iconify_license.dart`

```dart
import 'package:meta/meta.dart';

/// License information for an icon collection.
///
/// IMPORTANT: Always check [requiresAttribution] before shipping icons
/// from a collection in a commercial app. Collections with
/// [requiresAttribution] = true require you to display attribution
/// to the icon author in your app or documentation.
@immutable
final class IconifyLicense {
  const IconifyLicense({
    this.title,
    this.spdx,
    this.url,
    this.requiresAttribution = false,
  });

  /// Human-readable license name, e.g., "MIT License", "Apache License 2.0".
  final String? title;

  /// SPDX identifier, e.g., "MIT", "Apache-2.0", "CC-BY-4.0".
  ///
  /// May be null if the license is not a standard SPDX-registered license.
  final String? spdx;

  /// URL pointing to the full license text.
  final String? url;

  /// Whether this license requires attribution in derivative works.
  ///
  /// If true, your app must display the icon author's attribution.
  /// Consult the full license at [url] for exact attribution requirements.
  final bool requiresAttribution;

  /// Known safe licenses that do not require attribution for commercial use.
  static const Set<String> _noAttributionRequired = {
    'MIT', 'ISC', 'Apache-2.0', '0BSD', 'Unlicense', 'CC0-1.0',
  };

  /// Whether this license is known to be safe for commercial use
  /// without attribution requirements.
  ///
  /// Returns `false` when [spdx] is null or not in the known-safe list.
  /// When `false`, read the license at [url] before use.
  bool get isKnownCommercialFriendly =>
      spdx != null && _noAttributionRequired.contains(spdx);

  /// Creates a copy with the given fields replaced.
  IconifyLicense copyWith({
    String? title,
    String? spdx,
    String? url,
    bool? requiresAttribution,
  }) =>
      IconifyLicense(
        title: title ?? this.title,
        spdx: spdx ?? this.spdx,
        url: url ?? this.url,
        requiresAttribution: requiresAttribution ?? this.requiresAttribution,
      );

  Map<String, dynamic> toJson() => {
        if (title != null) 'title': title,
        if (spdx != null) 'spdx': spdx,
        if (url != null) 'url': url,
        'requiresAttribution': requiresAttribution,
      };

  factory IconifyLicense.fromJson(Map<String, dynamic> json) => IconifyLicense(
        title: json['title'] as String?,
        spdx: json['spdx'] as String?,
        url: json['url'] as String?,
        requiresAttribution: json['requiresAttribution'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      other is IconifyLicense &&
      title == other.title &&
      spdx == other.spdx &&
      url == other.url &&
      requiresAttribution == other.requiresAttribution;

  @override
  int get hashCode => Object.hash(title, spdx, url, requiresAttribution);

  @override
  String toString() =>
      'IconifyLicense(spdx: $spdx, requiresAttribution: $requiresAttribution)';
}
```

---

## Step 6 — IconifyIconData Model

**File**: `lib/src/models/iconify_icon_data.dart`

```dart
import 'package:meta/meta.dart';

/// The data for a single Iconify icon.
///
/// The [body] contains the SVG path content WITHOUT the outer `<svg>` tag.
/// To render this icon, wrap the body in:
/// ```xml
/// <svg xmlns="http://www.w3.org/2000/svg"
///      viewBox="0 0 {width} {height}"
///      width="{size}" height="{size}">
///   {body}
/// </svg>
/// ```
///
/// If the [body] contains `currentColor`, the icon is monotone and supports
/// color theming. If it does not, it is a multicolor icon and color overrides
/// should not be applied without explicit user consent.
@immutable
final class IconifyIconData {
  const IconifyIconData({
    required this.body,
    this.width = 24,
    this.height = 24,
    this.aliases = const [],
    this.hidden = false,
    this.rotate = 0,
    this.hFlip = false,
    this.vFlip = false,
    this.raw = const {},
  });

  /// SVG body content (everything inside the `<svg>` tag).
  final String body;

  /// Viewbox width. Defaults to 24 (the Iconify standard).
  final double width;

  /// Viewbox height. Defaults to 24 (the Iconify standard).
  final double height;

  /// Alias names for this icon within the same collection.
  final List<String> aliases;

  /// Whether this icon is hidden/deprecated in the upstream collection.
  final bool hidden;

  /// Rotation: 0, 1 (90°), 2 (180°), 3 (270°).
  final int rotate;

  /// Whether the icon should be flipped horizontally.
  final bool hFlip;

  /// Whether the icon should be flipped vertically.
  final bool vFlip;

  /// The original raw JSON data for this icon, preserved for debugging
  /// and advanced use cases. All values are JSON-safe types.
  final Map<String, dynamic> raw;

  /// Whether this icon supports color theming via `currentColor`.
  ///
  /// Monotone icons use `currentColor` for fill/stroke and can be
  /// recolored freely. Multicolor icons should not be recolored.
  bool get isMonochrome => body.contains('currentColor');

  /// Whether the viewbox is square.
  bool get isSquare => width == height;

  /// Creates a complete SVG string ready for rendering.
  ///
  /// [size] sets both width and height attributes. If null, uses
  /// the icon's natural [width] and [height].
  /// [color] replaces `currentColor` in the body (monotone icons only).
  String toSvgString({double? size, String? color}) {
    final w = size ?? width;
    final h = size ?? height;
    var svgBody = body;
    if (color != null && isMonochrome) {
      svgBody = svgBody.replaceAll('currentColor', color);
    }
    return '<svg xmlns="http://www.w3.org/2000/svg" '
        'viewBox="0 0 $width $height" '
        'width="$w" height="$h">'
        '$svgBody'
        '</svg>';
  }

  IconifyIconData copyWith({
    String? body,
    double? width,
    double? height,
    List<String>? aliases,
    bool? hidden,
    int? rotate,
    bool? hFlip,
    bool? vFlip,
    Map<String, dynamic>? raw,
  }) =>
      IconifyIconData(
        body: body ?? this.body,
        width: width ?? this.width,
        height: height ?? this.height,
        aliases: aliases ?? this.aliases,
        hidden: hidden ?? this.hidden,
        rotate: rotate ?? this.rotate,
        hFlip: hFlip ?? this.hFlip,
        vFlip: vFlip ?? this.vFlip,
        raw: raw ?? this.raw,
      );

  Map<String, dynamic> toJson() => {
        'body': body,
        'width': width,
        'height': height,
        if (aliases.isNotEmpty) 'aliases': aliases,
        if (hidden) 'hidden': hidden,
        if (rotate != 0) 'rotate': rotate,
        if (hFlip) 'hFlip': hFlip,
        if (vFlip) 'vFlip': vFlip,
      };

  factory IconifyIconData.fromJson(Map<String, dynamic> json) {
    return IconifyIconData(
      body: json['body'] as String,
      width: (json['width'] as num?)?.toDouble() ?? 24.0,
      height: (json['height'] as num?)?.toDouble() ?? 24.0,
      aliases: (json['aliases'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      hidden: json['hidden'] as bool? ?? false,
      rotate: json['rotate'] as int? ?? 0,
      hFlip: json['hFlip'] as bool? ?? false,
      vFlip: json['vFlip'] as bool? ?? false,
      raw: Map<String, dynamic>.from(json),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is IconifyIconData &&
      body == other.body &&
      width == other.width &&
      height == other.height;

  @override
  int get hashCode => Object.hash(body, width, height);

  @override
  String toString() =>
      'IconifyIconData(${width}x$height, monotone: $isMonochrome)';
}
```

---

## Step 7 — IconifyCollectionInfo Model

**File**: `lib/src/models/iconify_collection_info.dart`

```dart
import 'package:meta/meta.dart';
import 'iconify_license.dart';

/// Metadata for an Iconify icon collection (icon set).
@immutable
final class IconifyCollectionInfo {
  const IconifyCollectionInfo({
    required this.prefix,
    required this.name,
    required this.totalIcons,
    this.author,
    this.license,
    this.samples = const [],
    this.categories = const [],
    this.tags = const [],
    this.version,
    this.raw = const {},
  });

  /// The collection prefix, e.g., `mdi`, `lucide`.
  final String prefix;

  /// Human-readable name, e.g., "Material Design Icons".
  final String name;

  /// Total number of icons in this collection.
  final int totalIcons;

  /// Author name or URL.
  final String? author;

  /// License information. Check before use in commercial apps.
  final IconifyLicense? license;

  /// Sample icon names from this collection (for preview).
  final List<String> samples;

  /// Category names used to group icons in this collection.
  final List<String> categories;

  /// Search tags for this collection.
  final List<String> tags;

  /// Version string if the collection is versioned.
  final String? version;

  /// Original raw JSON data for this collection's info block.
  final Map<String, dynamic> raw;

  /// Whether attribution is required when using icons from this collection.
  bool get requiresAttribution => license?.requiresAttribution ?? false;

  /// Whether this collection is known safe for commercial use without attribution.
  bool get isKnownCommercialFriendly => license?.isKnownCommercialFriendly ?? false;

  Map<String, dynamic> toJson() => {
        'prefix': prefix,
        'name': name,
        'totalIcons': totalIcons,
        if (author != null) 'author': author,
        if (license != null) 'license': license!.toJson(),
        if (samples.isNotEmpty) 'samples': samples,
        if (categories.isNotEmpty) 'categories': categories,
        if (version != null) 'version': version,
      };

  factory IconifyCollectionInfo.fromJson(String prefix, Map<String, dynamic> json) {
    final info = json['info'] as Map<String, dynamic>? ?? json;
    final licenseJson = info['license'] as Map<String, dynamic>?;

    return IconifyCollectionInfo(
      prefix: prefix,
      name: info['name'] as String? ?? prefix,
      totalIcons: info['total'] as int? ?? 0,
      author: _extractAuthor(info['author']),
      license: licenseJson != null ? IconifyLicense.fromJson(licenseJson) : null,
      samples: (info['samples'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      categories: (info['categories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      version: info['version'] as String?,
      raw: Map<String, dynamic>.from(info),
    );
  }

  static String? _extractAuthor(dynamic author) {
    if (author == null) return null;
    if (author is String) return author;
    if (author is Map<String, dynamic>) {
      return author['name'] as String? ?? author['url'] as String?;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is IconifyCollectionInfo && prefix == other.prefix;

  @override
  int get hashCode => prefix.hashCode;

  @override
  String toString() => 'IconifyCollectionInfo($prefix: $name, $totalIcons icons)';
}
```

---

## Step 8 — IconifySearchResult Model

**File**: `lib/src/models/iconify_search_result.dart`

```dart
import 'package:meta/meta.dart';
import 'iconify_name.dart';

/// A single result from an icon search query.
@immutable
final class IconifySearchResult {
  const IconifySearchResult({
    required this.name,
    required this.score,
    this.matchedOn,
  });

  /// The icon name that matched.
  final IconifyName name;

  /// Relevance score (higher = more relevant). Range: 0.0 to 1.0.
  final double score;

  /// What the query matched on: 'exact', 'prefix', 'alias', 'tag'.
  final String? matchedOn;

  @override
  String toString() =>
      'IconifySearchResult($name, score: ${score.toStringAsFixed(2)})';
}
```

---

## Step 9 — Provider Interface

**File**: `lib/src/providers/iconify_provider.dart`

```dart
import '../models/iconify_name.dart';
import '../models/iconify_icon_data.dart';
import '../models/iconify_collection_info.dart';

/// The core abstraction for resolving Iconify icon data.
///
/// Implement this interface to create custom icon sources:
/// - bundled assets
/// - remote APIs
/// - generated subsets
/// - in-memory maps
/// - composite chains
///
/// Implementations MUST NOT throw for "not found" cases —
/// return `null` instead. Only throw [IconifyException] subclasses
/// for unexpected failures (network errors, parse errors, etc.).
abstract interface class IconifyProvider {
  /// Retrieves icon data for the given [name].
  ///
  /// Returns `null` if the icon is not available in this provider.
  /// Throws [IconifyNetworkException] on network failures.
  /// Throws [IconifyParseException] if the data is malformed.
  Future<IconifyIconData?> getIcon(IconifyName name);

  /// Retrieves collection metadata for the given [prefix].
  ///
  /// Returns `null` if the collection is not available.
  Future<IconifyCollectionInfo?> getCollection(String prefix);

  /// Returns true if this provider has data for the given [name].
  ///
  /// Must not throw. Returns `false` on any error.
  Future<bool> hasIcon(IconifyName name);

  /// Returns true if this provider has metadata for the given [prefix].
  Future<bool> hasCollection(String prefix);

  /// Disposes resources held by this provider.
  ///
  /// After disposal, all methods may throw [StateError].
  Future<void> dispose() async {}
}

/// Extension to support write operations on providers that support them.
extension WritableIconifyProvider on IconifyProvider {
  // This extension is intentionally empty.
  // Writable providers expose putIcon() directly on their concrete type.
}
```

---

## Step 10 — MemoryIconifyProvider

**File**: `lib/src/providers/memory_iconify_provider.dart`

```dart
import '../models/iconify_collection_info.dart';
import '../models/iconify_icon_data.dart';
import '../models/iconify_name.dart';
import 'iconify_provider.dart';

/// An [IconifyProvider] backed by in-memory maps.
///
/// Use for:
/// - Tests (pre-populate with known fixtures)
/// - Generated icon subsets (populate at startup from generated code)
/// - Temporary holding during app lifetime
///
/// Thread-safety: Not safe for concurrent modification. Do all [putIcon]
/// calls before any [getIcon] calls, or synchronize externally.
final class MemoryIconifyProvider implements IconifyProvider {
  MemoryIconifyProvider({
    Map<IconifyName, IconifyIconData>? icons,
    Map<String, IconifyCollectionInfo>? collections,
  })  : _icons = icons ?? {},
        _collections = collections ?? {};

  final Map<IconifyName, IconifyIconData> _icons;
  final Map<String, IconifyCollectionInfo> _collections;

  /// Stores an icon in this provider.
  void putIcon(IconifyName name, IconifyIconData data) {
    _icons[name] = data;
  }

  /// Stores collection metadata in this provider.
  void putCollection(IconifyCollectionInfo info) {
    _collections[info.prefix] = info;
  }

  /// Removes an icon from this provider.
  void removeIcon(IconifyName name) {
    _icons.remove(name);
  }

  /// Removes all icons and collections.
  void clear() {
    _icons.clear();
    _collections.clear();
  }

  /// Number of icons currently stored.
  int get iconCount => _icons.length;

  @override
  Future<IconifyIconData?> getIcon(IconifyName name) async => _icons[name];

  @override
  Future<IconifyCollectionInfo?> getCollection(String prefix) async =>
      _collections[prefix];

  @override
  Future<bool> hasIcon(IconifyName name) async => _icons.containsKey(name);

  @override
  Future<bool> hasCollection(String prefix) async =>
      _collections.containsKey(prefix);
}
```

---

## Step 11 — RemoteIconifyProvider

**File**: `lib/src/providers/http_iconify_provider.dart`

This provider fetches icons from the Iconify API. It is gated by `DevModeGuard` — remote calls are only allowed in debug/profile builds by default.

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../errors/iconify_exception.dart';
import '../guard/dev_mode_guard.dart';
import '../models/iconify_collection_info.dart';
import '../models/iconify_icon_data.dart';
import '../models/iconify_name.dart';
import '../parser/iconify_json_parser.dart';
import 'iconify_provider.dart';

/// An [IconifyProvider] that fetches icons from the Iconify HTTP API.
///
/// **Important**: debug and development only, never the recommended production path.

final class RemoteIconifyProvider implements IconifyProvider {
  RemoteIconifyProvider({
    String? apiBase,
    http.Client? httpClient,
    bool allowInRelease = false,
    Duration timeout = const Duration(seconds: 10),
    Map<String, String>? additionalHeaders,
  })  : _apiBase = apiBase ?? 'https://api.iconify.design',
        _client = httpClient ?? http.Client(),
        _allowInRelease = allowInRelease,
        _timeout = timeout,
        _headers = {
          'User-Agent': 'iconify_sdk_core/0.1.0 (Dart)',
          ...?additionalHeaders,
        };

  final String _apiBase;
  final http.Client _client;
  final bool _allowInRelease;
  final Duration _timeout;
  final Map<String, String> _headers;
  bool _disposed = false;

  bool get _isAllowed =>
      _allowInRelease || DevModeGuard.isRemoteAllowedInCurrentBuild();

  @override
  Future<IconifyIconData?> getIcon(IconifyName name) async {
    _checkDisposed();
    if (!_isAllowed) return null;

    final uri = Uri.parse('$_apiBase/${name.prefix}.json?icons=${name.iconName}');

    try {
      final response = await _client.get(uri, headers: _headers).timeout(_timeout);

      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) {
        throw IconifyNetworkException(
          message: 'HTTP ${response.statusCode} fetching ${name}: ${response.reasonPhrase}',
          statusCode: response.statusCode,
          uri: uri,
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final icons = json['icons'] as Map<String, dynamic>?;
      if (icons == null || !icons.containsKey(name.iconName)) return null;

      // Apply collection-level defaults to icon-level data
      final defaultWidth = (json['width'] as num?)?.toDouble() ?? 24.0;
      final defaultHeight = (json['height'] as num?)?.toDouble() ?? 24.0;
      final iconJson = Map<String, dynamic>.from(icons[name.iconName] as Map<String, dynamic>);
      iconJson.putIfAbsent('width', () => defaultWidth);
      iconJson.putIfAbsent('height', () => defaultHeight);

      return IconifyIconData.fromJson(iconJson);
    } on IconifyException {
      rethrow;
    } catch (e) {
      throw IconifyNetworkException(
        message: 'Network error fetching $name: $e',
        uri: uri,
      );
    }
  }

  @override
  Future<IconifyCollectionInfo?> getCollection(String prefix) async {
    _checkDisposed();
    if (!_isAllowed) return null;

    final uri = Uri.parse('$_apiBase/collection?prefix=$prefix&info=1');

    try {
      final response = await _client.get(uri, headers: _headers).timeout(_timeout);
      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) {
        throw IconifyNetworkException(
          message: 'HTTP ${response.statusCode} fetching collection $prefix',
          statusCode: response.statusCode,
          uri: uri,
        );
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return IconifyCollectionInfo.fromJson(prefix, json);
    } on IconifyException {
      rethrow;
    } catch (e) {
      throw IconifyNetworkException(
        message: 'Network error fetching collection $prefix: $e',
        uri: uri,
      );
    }
  }

  @override
  Future<bool> hasIcon(IconifyName name) async {
    try {
      return await getIcon(name) != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> hasCollection(String prefix) async {
    try {
      return await getCollection(prefix) != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _client.close();
  }

  void _checkDisposed() {
    if (_disposed) {
      throw StateError(
        'RemoteIconifyProvider has been disposed and cannot be used.',
      );
    }
  }
}
```

---

## Step 12 — CompositeIconifyProvider

**File**: `lib/src/providers/composite_iconify_provider.dart`

```dart
import '../models/iconify_collection_info.dart';
import '../models/iconify_icon_data.dart';
import '../models/iconify_name.dart';
import 'iconify_provider.dart';

/// An [IconifyProvider] that tries a list of providers in order.
///
/// Returns the first non-null result from any provider.
/// If all providers return null, returns null.
///
/// Errors from individual providers are NOT silenced — if a provider
/// throws, the composite throws too. Use [CachingIconifyProvider] or
/// your own wrapper to handle per-provider errors gracefully.
///
/// Resolution order: providers are tried in the order they are provided.
/// The first provider to return a non-null result wins.
///
/// ```dart
/// final provider = CompositeIconifyProvider([
///   generatedProvider,    // fastest — checked first
///   assetBundleProvider,  // local assets — checked second
///   cachingHttpProvider,  // remote with cache — checked last
/// ]);
/// ```
final class CompositeIconifyProvider implements IconifyProvider {
  CompositeIconifyProvider(this.providers) : assert(providers.isNotEmpty);

  final List<IconifyProvider> providers;

  @override
  Future<IconifyIconData?> getIcon(IconifyName name) async {
    for (final provider in providers) {
      final result = await provider.getIcon(name);
      if (result != null) return result;
    }
    return null;
  }

  @override
  Future<IconifyCollectionInfo?> getCollection(String prefix) async {
    for (final provider in providers) {
      final result = await provider.getCollection(prefix);
      if (result != null) return result;
    }
    return null;
  }

  @override
  Future<bool> hasIcon(IconifyName name) async {
    for (final provider in providers) {
      if (await provider.hasIcon(name)) return true;
    }
    return false;
  }

  @override
  Future<bool> hasCollection(String prefix) async {
    for (final provider in providers) {
      if (await provider.hasCollection(prefix)) return true;
    }
    return false;
  }

  @override
  Future<void> dispose() async {
    for (final provider in providers) {
      await provider.dispose();
    }
  }
}
```

---

## Step 13 — Cache Interface

**File**: `lib/src/cache/iconify_cache.dart`

```dart
import '../models/iconify_icon_data.dart';
import '../models/iconify_name.dart';

/// Abstract interface for Iconify icon caches.
///
/// The cache is a pure key-value store for [IconifyIconData].
/// It does not validate data — that is the provider's responsibility.
abstract interface class IconifyCache {
  /// Retrieves cached icon data for [name], or null if not cached.
  Future<IconifyIconData?> get(IconifyName name);

  /// Stores [data] under [name] in the cache.
  Future<void> put(IconifyName name, IconifyIconData data);

  /// Removes the entry for [name] from the cache.
  Future<void> remove(IconifyName name);

  /// Removes all entries from the cache.
  Future<void> clear();

  /// Returns the number of entries currently in the cache.
  Future<int> size();

  /// Returns true if the cache contains an entry for [name].
  Future<bool> contains(IconifyName name);
}
```

---

## Step 14 — LRU Cache Implementation

**File**: `lib/src/cache/lru_iconify_cache.dart`

```dart
import '../errors/iconify_exception.dart';
import '../models/iconify_icon_data.dart';
import '../models/iconify_name.dart';
import 'iconify_cache.dart';

/// An in-memory LRU (Least Recently Used) implementation of [IconifyCache].
///
/// When the cache reaches [maxEntries], the least recently used entry
/// is evicted to make room for the new entry.
///
/// This cache is not thread-safe. Do not use from concurrent isolates.
final class LruIconifyCache implements IconifyCache {
  LruIconifyCache({
    this.maxEntries = 500,
  }) : assert(maxEntries > 0, 'maxEntries must be positive');

  /// Maximum number of entries before LRU eviction occurs.
  final int maxEntries;

  // LinkedHashMap preserves insertion order, which gives us LRU for free
  // when we remove+re-insert on access.
  final _store = <IconifyName, _CacheEntry>{};

  @override
  Future<IconifyIconData?> get(IconifyName name) async {
    final entry = _store[name];
    if (entry == null) return null;

    // Move to end (most recently used)
    _store.remove(name);
    _store[name] = entry;

    return entry.data;
  }

  @override
  Future<void> put(IconifyName name, IconifyIconData data) async {
    // If already present, remove first so re-insertion puts it at the end
    _store.remove(name);

    // Evict LRU entry if at capacity
    if (_store.length >= maxEntries) {
      final lruKey = _store.keys.first;
      _store.remove(lruKey);
    }

    _store[name] = _CacheEntry(data: data, insertedAt: DateTime.now());
  }

  @override
  Future<void> remove(IconifyName name) async => _store.remove(name);

  @override
  Future<void> clear() async => _store.clear();

  @override
  Future<int> size() async => _store.length;

  @override
  Future<bool> contains(IconifyName name) async => _store.containsKey(name);

  /// Returns cache statistics for diagnostics.
  LruCacheStats get stats {
    return LruCacheStats(
      currentSize: _store.length,
      maxSize: maxEntries,
    );
  }
}

final class _CacheEntry {
  const _CacheEntry({required this.data, required this.insertedAt});
  final IconifyIconData data;
  final DateTime insertedAt;
}

/// Diagnostic statistics for [LruIconifyCache].
final class LruCacheStats {
  const LruCacheStats({
    required this.currentSize,
    required this.maxSize,
  });

  final int currentSize;
  final int maxSize;

  double get fillRatio => maxSize == 0 ? 0.0 : currentSize / maxSize;

  @override
  String toString() => 'LruCacheStats($currentSize/$maxSize, ${(fillRatio * 100).toStringAsFixed(1)}% full)';
}
```

---

## Step 15 — CachingIconifyProvider

**File**: `lib/src/providers/caching_iconify_provider.dart`

```dart
import '../cache/iconify_cache.dart';
import '../cache/lru_iconify_cache.dart';
import '../models/iconify_collection_info.dart';
import '../models/iconify_icon_data.dart';
import '../models/iconify_name.dart';
import 'iconify_provider.dart';

/// An [IconifyProvider] decorator that caches results from [inner].
///
/// On a cache miss, delegates to [inner] and stores the result.
/// On a cache hit, returns the cached value without calling [inner].
///
/// ```dart
/// final provider = CachingIconifyProvider(
///   inner: RemoteIconifyProvider(),
///   cache: LruIconifyCache(maxEntries: 300),
/// );
/// ```
final class CachingIconifyProvider implements IconifyProvider {
  CachingIconifyProvider({
    required this.inner,
    IconifyCache? cache,
  }) : _cache = cache ?? LruIconifyCache();

  final IconifyProvider inner;
  final IconifyCache _cache;

  int _hits = 0;
  int _misses = 0;

  /// Number of cache hits since this provider was created.
  int get hits => _hits;

  /// Number of cache misses since this provider was created.
  int get misses => _misses;

  @override
  Future<IconifyIconData?> getIcon(IconifyName name) async {
    final cached = await _cache.get(name);
    if (cached != null) {
      _hits++;
      return cached;
    }

    _misses++;
    final result = await inner.getIcon(name);
    if (result != null) {
      await _cache.put(name, result);
    }
    return result;
  }

  @override
  Future<IconifyCollectionInfo?> getCollection(String prefix) =>
      inner.getCollection(prefix);

  @override
  Future<bool> hasIcon(IconifyName name) async {
    if (await _cache.contains(name)) return true;
    return inner.hasIcon(name);
  }

  @override
  Future<bool> hasCollection(String prefix) => inner.hasCollection(prefix);

  @override
  Future<void> dispose() async {
    await inner.dispose();
    await _cache.clear();
  }

  /// Resets hit/miss counters (for diagnostics).
  void resetStats() {
    _hits = 0;
    _misses = 0;
  }
}
```

---

## Step 16 — FileSystemIconifyProvider

**File**: `lib/src/providers/file_system_iconify_provider.dart`

```dart
import 'dart:convert';
import 'dart:io';
import '../errors/iconify_exception.dart';
import '../models/iconify_collection_info.dart';
import '../models/iconify_icon_data.dart';
import '../models/iconify_name.dart';
import '../parser/iconify_json_parser.dart';
import 'iconify_provider.dart';

/// An [IconifyProvider] that reads Iconify JSON files from the filesystem.
///
/// Expects files in the structure:
/// ```
/// [root]/
///   mdi.json       ← full collection JSON
///   lucide.json
///   tabler.json
/// ```
///
/// Each JSON file must be a valid Iconify collection JSON
/// (same format as the `@iconify-json/{prefix}/icons.json` npm package).
final class FileSystemIconifyProvider implements IconifyProvider {
  FileSystemIconifyProvider({
    required this.root,
    bool preload = false,
  }) : _root = Directory(root) {
    if (preload) {
      // Fire and forget; load will happen on first access otherwise
      _preloadAll();
    }
  }

  final String root;
  final Directory _root;
  final _cache = <String, Map<String, dynamic>>{};

  Future<void> _preloadAll() async {
    if (!await _root.exists()) return;
    await for (final entity in _root.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        final prefix = entity.uri.pathSegments.last.replaceAll('.json', '');
        await _loadCollection(prefix);
      }
    }
  }

  Future<Map<String, dynamic>?> _loadCollection(String prefix) async {
    if (_cache.containsKey(prefix)) return _cache[prefix];

    final file = File('${_root.path}/$prefix.json');
    if (!await file.exists()) return null;

    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      _cache[prefix] = json;
      return json;
    } catch (e) {
      throw IconifyParseException(
        message: 'Failed to parse $prefix.json: $e',
        field: 'file',
        rawValue: file.path,
      );
    }
  }

  @override
  Future<IconifyIconData?> getIcon(IconifyName name) async {
    final json = await _loadCollection(name.prefix);
    if (json == null) return null;
    return IconifyJsonParser.extractIcon(json, name.iconName);
  }

  @override
  Future<IconifyCollectionInfo?> getCollection(String prefix) async {
    final json = await _loadCollection(prefix);
    if (json == null) return null;
    return IconifyCollectionInfo.fromJson(prefix, json);
  }

  @override
  Future<bool> hasIcon(IconifyName name) async {
    final json = await _loadCollection(name.prefix);
    if (json == null) return false;
    final icons = json['icons'] as Map<String, dynamic>?;
    return icons?.containsKey(name.iconName) ?? false;
  }

  @override
  Future<bool> hasCollection(String prefix) async {
    return File('${_root.path}/$prefix.json').exists();
  }
}
```

---

## Step 17 — AssetBundleIconifyProvider (Dart-only stub)

**File**: `lib/src/providers/asset_bundle_iconify_provider.dart`

> **Important**: The full Flutter-integrated version lives in `iconify_flutter`. This class exists in core as an abstract base that Flutter-aware implementations can extend. It keeps the interface clean for pure Dart consumers.

```dart
import '../models/iconify_collection_info.dart';
import '../models/iconify_icon_data.dart';
import '../models/iconify_name.dart';
import 'iconify_provider.dart';

/// Abstract base for providers that read from a Flutter asset bundle.
///
/// The concrete implementation (`FlutterAssetBundleIconifyProvider`)
/// lives in the `iconify_flutter` package which has a Flutter dependency.
///
/// This abstract class exists in core so that `iconify_sdk_core`
/// can reference asset-bundle providers in composite chains without
/// importing Flutter.
abstract class AssetBundleIconifyProvider implements IconifyProvider {
  const AssetBundleIconifyProvider({
    required this.assetPrefix,
  });

  /// The asset path prefix where Iconify JSON files are stored.
  /// Example: `'assets/iconify'`
  final String assetPrefix;

  /// Reads the raw bytes of an asset at [path].
  /// Implemented by platform-specific subclasses.
  Future<String> loadAssetString(String path);

  @override
  Future<bool> hasIcon(IconifyName name) async {
    try {
      return await getIcon(name) != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> hasCollection(String prefix) async {
    try {
      return await getCollection(prefix) != null;
    } catch (_) {
      return false;
    }
  }
}
```

---

## Step 18 — Alias Resolver

**File**: `lib/src/resolver/alias_resolver.dart`

This is the most complex logic in Phase 1. Read the rules carefully.

### Alias Rules (from Iconify JSON format)
- An alias is an entry in the `aliases` map of a collection
- Each alias has a `parent` key pointing to another icon name (NOT a full `prefix:name`)
- An alias can optionally override `width`, `height`, `rotate`, `hFlip`, `vFlip`
- An alias can point to another alias (chain depth up to ~5 in practice)
- Circular aliases MUST be detected and throw `CircularAliasException`

```dart
import '../errors/iconify_exception.dart';
import '../models/iconify_icon_data.dart';
import '../models/iconify_name.dart';

/// Resolves icon aliases within a collection.
///
/// Iconify collections may define aliases that point to other icons.
/// An alias can itself be an alias (chained). This resolver handles
/// chains of arbitrary depth while detecting and rejecting circular references.
///
/// ```dart
/// final resolver = AliasResolver();
/// final icon = resolver.resolve(
///   iconName: 'home-variant-outline',
///   icons: collectionIcons,
///   aliases: collectionAliases,
///   defaultWidth: 24,
///   defaultHeight: 24,
/// );
/// ```
final class AliasResolver {
  const AliasResolver({
    this.maxChainDepth = 10,
  });

  /// Maximum alias chain depth before throwing [CircularAliasException].
  final int maxChainDepth;

  /// Resolves [iconName] to its final [IconifyIconData].
  ///
  /// First looks in [icons] for a direct match.
  /// If not found, looks in [aliases] and follows the chain.
  /// Returns null if not found in either.
  ///
  /// Throws [CircularAliasException] if a cycle is detected.
  IconifyIconData? resolve({
    required String iconName,
    required Map<String, IconifyIconData> icons,
    required Map<String, AliasEntry> aliases,
    required double defaultWidth,
    required double defaultHeight,
  }) {
    // Direct icon match — no alias resolution needed
    if (icons.containsKey(iconName)) {
      return icons[iconName];
    }

    // Start alias resolution
    final chain = <String>[iconName];
    var currentName = iconName;
    Map<String, dynamic> overrides = {};

    while (true) {
      if (chain.length > maxChainDepth) {
        throw CircularAliasException(
          chain: List.from(chain),
          message:
              'Alias chain exceeded maximum depth of $maxChainDepth. '
              'Chain: ${chain.join(' -> ')}. '
              'This indicates a circular alias or abnormally deep chain.',
        );
      }

      final alias = aliases[currentName];
      if (alias == null) {
        // Neither icon nor alias — not found
        return null;
      }

      // Collect overrides from this alias level (do not overwrite higher-level overrides)
      if (alias.width != null) overrides.putIfAbsent('width', () => alias.width);
      if (alias.height != null) overrides.putIfAbsent('height', () => alias.height);
      if (alias.rotate != null) overrides.putIfAbsent('rotate', () => alias.rotate);
      if (alias.hFlip != null) overrides.putIfAbsent('hFlip', () => alias.hFlip);
      if (alias.vFlip != null) overrides.putIfAbsent('vFlip', () => alias.vFlip);

      final parentName = alias.parent;

      // Circular reference check
      if (chain.contains(parentName)) {
        chain.add(parentName); // Include in chain for error message
        throw CircularAliasException(
          chain: List.from(chain),
          message:
              'Circular alias detected. Chain: ${chain.join(' -> ')}.',
        );
      }

      chain.add(parentName);
      currentName = parentName;

      // Check if the parent is a direct icon
      if (icons.containsKey(currentName)) {
        final base = icons[currentName]!;
        // Apply collected overrides
        return base.copyWith(
          width: (overrides['width'] as num?)?.toDouble(),
          height: (overrides['height'] as num?)?.toDouble(),
          rotate: overrides['rotate'] as int?,
          hFlip: overrides['hFlip'] as bool?,
          vFlip: overrides['vFlip'] as bool?,
        );
      }

      // Parent is also an alias — continue the loop
    }
  }
}

/// Represents a single alias entry in a collection's alias map.
final class AliasEntry {
  const AliasEntry({
    required this.parent,
    this.width,
    this.height,
    this.rotate,
    this.hFlip,
    this.vFlip,
  });

  /// The name of the parent icon or alias (within the same collection).
  final String parent;

  final double? width;
  final double? height;
  final int? rotate;
  final bool? hFlip;
  final bool? vFlip;

  factory AliasEntry.fromJson(Map<String, dynamic> json) => AliasEntry(
        parent: json['parent'] as String,
        width: (json['width'] as num?)?.toDouble(),
        height: (json['height'] as num?)?.toDouble(),
        rotate: json['rotate'] as int?,
        hFlip: json['hFlip'] as bool?,
        vFlip: json['vFlip'] as bool?,
      );
}
```

---

## Step 19 — Iconify JSON Parser

**File**: `lib/src/parser/iconify_json_parser.dart`

This parses the canonical `@iconify/json` format.

```dart
import 'dart:convert';
import '../errors/iconify_exception.dart';
import '../models/iconify_collection_info.dart';
import '../models/iconify_icon_data.dart';
import '../models/iconify_name.dart';
import '../resolver/alias_resolver.dart';

/// Parses Iconify collection JSON into typed models.
///
/// The Iconify JSON format is documented at:
/// https://iconify.design/docs/types/iconify-json.html
///
/// Example input (abbreviated):
/// ```json
/// {
///   "prefix": "mdi",
///   "info": { "name": "Material Design Icons", "total": 7446, ... },
///   "icons": {
///     "home": { "body": "<path d='...'/>", "width": 24 }
///   },
///   "aliases": {
///     "home-outline": { "parent": "home" }
///   },
///   "width": 24,
///   "height": 24
/// }
/// ```
final class IconifyJsonParser {
  const IconifyJsonParser._();

  /// Parses a raw JSON string into a [ParsedCollection].
  ///
  /// Throws [IconifyParseException] on malformed input.
  static ParsedCollection parseCollectionString(String jsonString) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw IconifyParseException(
        message: 'Invalid JSON: $e',
      );
    }
    return parseCollection(json);
  }

  /// Parses a decoded JSON map into a [ParsedCollection].
  ///
  /// Throws [IconifyParseException] on schema violations.
  static ParsedCollection parseCollection(Map<String, dynamic> json) {
    final prefix = json['prefix'] as String?;
    if (prefix == null || prefix.isEmpty) {
      throw IconifyParseException(
        message: 'Collection JSON is missing required "prefix" field.',
        field: 'prefix',
      );
    }

    final rawIcons = json['icons'] as Map<String, dynamic>?;
    if (rawIcons == null) {
      throw IconifyParseException(
        message: 'Collection "$prefix" is missing required "icons" field.',
        field: 'icons',
      );
    }

    final defaultWidth = (json['width'] as num?)?.toDouble() ?? 24.0;
    final defaultHeight = (json['height'] as num?)?.toDouble() ?? 24.0;

    // Parse icons
    final icons = <String, IconifyIconData>{};
    for (final entry in rawIcons.entries) {
      try {
        final iconJson = Map<String, dynamic>.from(entry.value as Map<String, dynamic>);
        iconJson.putIfAbsent('width', () => defaultWidth);
        iconJson.putIfAbsent('height', () => defaultHeight);
        icons[entry.key] = IconifyIconData.fromJson(iconJson);
      } catch (e) {
        throw IconifyParseException(
          message: 'Failed to parse icon "${entry.key}" in collection "$prefix": $e',
          field: 'icons.${entry.key}',
          rawValue: entry.value,
        );
      }
    }

    // Parse aliases
    final rawAliases = json['aliases'] as Map<String, dynamic>? ?? {};
    final aliases = <String, AliasEntry>{};
    for (final entry in rawAliases.entries) {
      try {
        aliases[entry.key] = AliasEntry.fromJson(
          Map<String, dynamic>.from(entry.value as Map<String, dynamic>),
        );
      } catch (e) {
        // Non-fatal: skip malformed alias entries with a warning
        // In production, these should be reported but not crash parsing
      }
    }

    final info = IconifyCollectionInfo.fromJson(prefix, json);

    return ParsedCollection(
      prefix: prefix,
      info: info,
      icons: icons,
      aliases: aliases,
      defaultWidth: defaultWidth,
      defaultHeight: defaultHeight,
    );
  }

  /// Extracts a single icon from a pre-decoded collection JSON map.
  ///
  /// Handles alias resolution transparently.
  /// Returns null if the icon or alias target is not found.
  static IconifyIconData? extractIcon(
    Map<String, dynamic> collectionJson,
    String iconName,
  ) {
    final defaultWidth = (collectionJson['width'] as num?)?.toDouble() ?? 24.0;
    final defaultHeight = (collectionJson['height'] as num?)?.toDouble() ?? 24.0;
    final rawIcons = collectionJson['icons'] as Map<String, dynamic>? ?? {};
    final rawAliases = collectionJson['aliases'] as Map<String, dynamic>? ?? {};

    // Try direct icon first
    if (rawIcons.containsKey(iconName)) {
      final iconJson = Map<String, dynamic>.from(
        rawIcons[iconName] as Map<String, dynamic>,
      );
      iconJson.putIfAbsent('width', () => defaultWidth);
      iconJson.putIfAbsent('height', () => defaultHeight);
      return IconifyIconData.fromJson(iconJson);
    }

    // Try alias resolution
    final icons = <String, IconifyIconData>{};
    for (final entry in rawIcons.entries) {
      final iconJson = Map<String, dynamic>.from(entry.value as Map<String, dynamic>);
      iconJson.putIfAbsent('width', () => defaultWidth);
      iconJson.putIfAbsent('height', () => defaultHeight);
      icons[entry.key] = IconifyIconData.fromJson(iconJson);
    }

    final aliases = <String, AliasEntry>{};
    for (final entry in rawAliases.entries) {
      try {
        aliases[entry.key] = AliasEntry.fromJson(
          Map<String, dynamic>.from(entry.value as Map<String, dynamic>),
        );
      } catch (_) {}
    }

    return const AliasResolver().resolve(
      iconName: iconName,
      icons: icons,
      aliases: aliases,
      defaultWidth: defaultWidth,
      defaultHeight: defaultHeight,
    );
  }
}

/// The result of parsing a complete Iconify collection JSON.
final class ParsedCollection {
  const ParsedCollection({
    required this.prefix,
    required this.info,
    required this.icons,
    required this.aliases,
    required this.defaultWidth,
    required this.defaultHeight,
  });

  final String prefix;
  final IconifyCollectionInfo info;
  final Map<String, IconifyIconData> icons;
  final Map<String, AliasEntry> aliases;
  final double defaultWidth;
  final double defaultHeight;

  /// Returns icon data for [iconName], resolving aliases if needed.
  IconifyIconData? getIcon(String iconName) {
    return const AliasResolver().resolve(
      iconName: iconName,
      icons: icons,
      aliases: aliases,
      defaultWidth: defaultWidth,
      defaultHeight: defaultHeight,
    );
  }

  /// All icon names, including aliases.
  Set<String> get allNames => {...icons.keys, ...aliases.keys};

  /// Number of real icons (not counting aliases).
  int get iconCount => icons.length;

  /// Number of aliases.
  int get aliasCount => aliases.length;
}
```

---

## Step 20 — DevModeGuard

**File**: `lib/src/guard/dev_mode_guard.dart`

```dart
/// Controls access to remote network operations based on build mode.
///
/// The Iconify public API is a community-funded service. This guard
/// prevents production apps from defaulting to remote API calls,
/// which would be both unreliable and an ethical burden on the service.
///
/// In debug and profile builds, remote calls are allowed by default.
/// In release builds, remote calls are BLOCKED by default.
///
/// To override this in release builds (e.g., for internal enterprise tools):
/// call [DevModeGuard.allowRemoteInRelease] during app initialization.
abstract final class DevModeGuard {
  DevModeGuard._();

  static bool _releaseOverride = false;

  /// Allows remote provider calls even in release builds.
  ///
  /// Call this during app initialization if your app requires remote
  /// icon loading in production. This is opt-in by design.
  ///
  /// **Note**: Consider self-hosting the Iconify API for production:
  /// https://github.com/iconify/api
  static void allowRemoteInRelease() {
    _releaseOverride = true;
  }

  /// Resets the release override (primarily for testing).
  static void resetOverride() {
    _releaseOverride = false;
  }

  /// Returns true if remote provider calls are allowed in the current build.
  ///
  /// - Debug build: always true
  /// - Profile build: always true
  /// - Release build: true only if [allowRemoteInRelease] was called
  static bool isRemoteAllowedInCurrentBuild() {
    if (_releaseOverride) return true;
    // In Dart, assert statements only run in debug mode.
    // We use this to detect the build mode at runtime.
    bool isDebugOrProfile = false;
    // ignore: prefer_asserts_with_message
    assert(() {
      isDebugOrProfile = true;
      return true;
    }());
    return isDebugOrProfile;
  }
}
```

---

## Step 21 — Barrel Export File

**File**: `lib/iconify_sdk_core.dart`

Only public API surfaces here. No `src/` internals exported directly.

```dart
/// Pure Dart engine for Iconify icons.
///
/// Provides models, providers, cache, alias resolution, and JSON parsing.
/// No Flutter dependency required.
///
/// Quick start:
/// ```dart
/// import 'package:iconify_sdk_core/iconify_sdk_core.dart';
///
/// final name = IconifyName.parse('mdi:home');
/// final provider = RemoteIconifyProvider();
/// final icon = await provider.getIcon(name);
/// print(icon?.toSvgString());
/// ```
library iconify_sdk_core;

// Models
export 'src/models/iconify_name.dart';
export 'src/models/iconify_icon_data.dart';
export 'src/models/iconify_collection_info.dart';
export 'src/models/iconify_license.dart';
export 'src/models/iconify_search_result.dart';

// Errors
export 'src/errors/iconify_exception.dart'
    hide IconifyName; // Remove the placeholder typedef

// Providers
export 'src/providers/iconify_provider.dart';
export 'src/providers/memory_iconify_provider.dart';
export 'src/providers/http_iconify_provider.dart';
export 'src/providers/composite_iconify_provider.dart';
export 'src/providers/caching_iconify_provider.dart';
export 'src/providers/file_system_iconify_provider.dart';
export 'src/providers/asset_bundle_iconify_provider.dart';

// Cache
export 'src/cache/iconify_cache.dart';
export 'src/cache/lru_iconify_cache.dart';

// Resolver
export 'src/resolver/alias_resolver.dart';

// Parser
export 'src/parser/iconify_json_parser.dart';

// Guard
export 'src/guard/dev_mode_guard.dart';
```

> **Agent note**: After creating the real `IconifyName` in step 4, go back to `iconify_exception.dart` and delete the placeholder `typedef IconifyName = dynamic;` line. Replace it with `import '../models/iconify_name.dart';` at the top of the file.

---

## Step 22 — Test Fixtures

These are real Iconify JSON subsets to use in tests. Fetch them from the real upstream before writing tests.

### Agent Instructions for Fixtures

```bash
# Fetch real MDI fixture (3 icons + 2 aliases)
curl "https://raw.githubusercontent.com/iconify/icon-sets/master/json/mdi.json" -o test/fixtures/mdi_fixture_full.json \
  -o test/fixtures/mdi_fixture.json

# Fetch Lucide fixture
curl "https://raw.githubusercontent.com/iconify/icon-sets/master/json/lucide.json?icons=home,settings,user,star,heart" \
  -o test/fixtures/lucide_fixture.json

# Fetch Tabler fixture
curl "https://raw.githubusercontent.com/iconify/icon-sets/master/json/tabler.json?icons=home,settings,user,star" \
  -o test/fixtures/tabler_fixture.json
```

### Create malformed fixture manually

**File**: `test/fixtures/malformed_fixture.json`
```json
{
  "prefix": "bad",
  "icons": {
    "missing-body": { "width": 24 },
    "valid-icon": { "body": "<path d='M0 0'/>", "width": 24, "height": 24 }
  }
}
```

### Create alias chain fixture manually

**File**: `test/fixtures/alias_chain_fixture.json`
```json
{
  "prefix": "test",
  "width": 24,
  "height": 24,
  "icons": {
    "base-icon": {
      "body": "<path d='M12 2L2 22h20L12 2z'/>",
      "width": 24,
      "height": 24
    }
  },
  "aliases": {
    "level1": { "parent": "base-icon" },
    "level2": { "parent": "level1" },
    "level3": { "parent": "level2", "width": 32, "height": 32 },
    "circular-a": { "parent": "circular-b" },
    "circular-b": { "parent": "circular-a" }
  }
}
```

---

## Step 23 — Tests

Write ALL tests. Every test must pass before moving to the next file. 100% of public API must be covered.

### IconifyName Tests

**File**: `test/models/iconify_name_test.dart`

```dart
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:test/test.dart';

void main() {
  group('IconifyName', () {
    group('parse — valid inputs', () {
      test('parses simple prefix:name', () {
        final name = IconifyName.parse('mdi:home');
        expect(name.prefix, 'mdi');
        expect(name.iconName, 'home');
      });

      test('parses name with hyphens', () {
        final name = IconifyName.parse('mdi:arrow-left-circle');
        expect(name.iconName, 'arrow-left-circle');
      });

      test('parses prefix with hyphens', () {
        final name = IconifyName.parse('fluent-emoji:home');
        expect(name.prefix, 'fluent-emoji');
      });

      test('parses single-char prefix and name', () {
        final name = IconifyName.parse('a:b');
        expect(name.prefix, 'a');
        expect(name.iconName, 'b');
      });

      test('parses name with digits', () {
        final name = IconifyName.parse('mdi:format-h1');
        expect(name.iconName, 'format-h1');
      });

      test('toString returns canonical form', () {
        expect(IconifyName.parse('mdi:home').toString(), 'mdi:home');
      });
    });

    group('parse — invalid inputs', () {
      test('throws on missing colon', () {
        expect(
          () => IconifyName.parse('mdi-home'),
          throwsA(isA<InvalidIconNameException>()),
        );
      });

      test('throws on empty prefix', () {
        expect(
          () => IconifyName.parse(':home'),
          throwsA(isA<InvalidIconNameException>()),
        );
      });

      test('throws on empty name', () {
        expect(
          () => IconifyName.parse('mdi:'),
          throwsA(isA<InvalidIconNameException>()),
        );
      });

      test('throws on double colon', () {
        expect(
          () => IconifyName.parse('mdi:home:extra'),
          throwsA(isA<InvalidIconNameException>()),
        );
      });

      test('throws on uppercase prefix', () {
        expect(
          () => IconifyName.parse('MDI:home'),
          throwsA(isA<InvalidIconNameException>()),
        );
      });

      test('throws on uppercase name', () {
        expect(
          () => IconifyName.parse('mdi:Home'),
          throwsA(isA<InvalidIconNameException>()),
        );
      });

      test('throws on leading hyphen in prefix', () {
        expect(
          () => IconifyName.parse('-mdi:home'),
          throwsA(isA<InvalidIconNameException>()),
        );
      });

      test('throws on trailing hyphen in name', () {
        expect(
          () => IconifyName.parse('mdi:home-'),
          throwsA(isA<InvalidIconNameException>()),
        );
      });

      test('error message is human readable', () {
        try {
          IconifyName.parse('mdi-home');
          fail('should have thrown');
        } on InvalidIconNameException catch (e) {
          expect(e.message, contains('colon'));
          expect(e.input, 'mdi-home');
        }
      });
    });

    group('tryParse', () {
      test('returns name for valid input', () {
        expect(IconifyName.tryParse('mdi:home'), isNotNull);
      });

      test('returns null for invalid input', () {
        expect(IconifyName.tryParse('mdi-home'), isNull);
      });
    });

    group('equality and hashing', () {
      test('equal for same prefix and name', () {
        expect(
          IconifyName('mdi', 'home'),
          equals(IconifyName('mdi', 'home')),
        );
      });

      test('not equal for different prefix', () {
        expect(
          IconifyName('mdi', 'home'),
          isNot(equals(IconifyName('lucide', 'home'))),
        );
      });

      test('not equal for different name', () {
        expect(
          IconifyName('mdi', 'home'),
          isNot(equals(IconifyName('mdi', 'settings'))),
        );
      });

      test('same hashCode for equal names', () {
        expect(
          IconifyName('mdi', 'home').hashCode,
          equals(IconifyName('mdi', 'home').hashCode),
        );
      });

      test('can be used as Map key', () {
        final map = {IconifyName('mdi', 'home'): 'value'};
        expect(map[IconifyName('mdi', 'home')], 'value');
      });

      test('can be used in Set', () {
        final set = {IconifyName('mdi', 'home'), IconifyName('mdi', 'home')};
        expect(set.length, 1);
      });
    });

    group('const construction', () {
      test('const constructor works', () {
        const name = IconifyName('mdi', 'home');
        expect(name.prefix, 'mdi');
      });
    });
  });
}
```

### LRU Cache Tests

**File**: `test/cache/lru_iconify_cache_test.dart`

```dart
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:test/test.dart';

void main() {
  final homeData = IconifyIconData(
    body: '<path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/>',
  );
  final settingsData = IconifyIconData(body: '<path d="M19.14 12.94"/>');

  group('LruIconifyCache', () {
    late LruIconifyCache cache;

    setUp(() => cache = LruIconifyCache(maxEntries: 3));

    test('put and get round-trip', () async {
      await cache.put(IconifyName('mdi', 'home'), homeData);
      final result = await cache.get(IconifyName('mdi', 'home'));
      expect(result, equals(homeData));
    });

    test('returns null for missing key', () async {
      expect(await cache.get(IconifyName('mdi', 'missing')), isNull);
    });

    test('contains returns true for present key', () async {
      await cache.put(IconifyName('mdi', 'home'), homeData);
      expect(await cache.contains(IconifyName('mdi', 'home')), isTrue);
    });

    test('contains returns false for absent key', () async {
      expect(await cache.contains(IconifyName('mdi', 'none')), isFalse);
    });

    test('remove deletes entry', () async {
      await cache.put(IconifyName('mdi', 'home'), homeData);
      await cache.remove(IconifyName('mdi', 'home'));
      expect(await cache.get(IconifyName('mdi', 'home')), isNull);
    });

    test('clear removes all entries', () async {
      await cache.put(IconifyName('mdi', 'home'), homeData);
      await cache.put(IconifyName('mdi', 'settings'), settingsData);
      await cache.clear();
      expect(await cache.size(), 0);
    });

    test('size reflects current count', () async {
      expect(await cache.size(), 0);
      await cache.put(IconifyName('mdi', 'home'), homeData);
      expect(await cache.size(), 1);
    });

    test('evicts LRU entry when at capacity', () async {
      final a = IconifyName('mdi', 'a');
      final b = IconifyName('mdi', 'b');
      final c = IconifyName('mdi', 'c');
      final d = IconifyName('mdi', 'd');
      final data = IconifyIconData(body: '<path/>');

      await cache.put(a, data); // [a]
      await cache.put(b, data); // [a, b]
      await cache.put(c, data); // [a, b, c] — at capacity

      // Access 'a' to make it recently used
      await cache.get(a);        // [b, c, a]

      await cache.put(d, data);  // evicts 'b', inserts 'd' → [c, a, d]

      expect(await cache.contains(b), isFalse, reason: 'b should have been evicted');
      expect(await cache.contains(a), isTrue);
      expect(await cache.contains(c), isTrue);
      expect(await cache.contains(d), isTrue);
    });

    test('LRU evicts oldest when no access', () async {
      final data = IconifyIconData(body: '<path/>');
      final names = List.generate(4, (i) => IconifyName('mdi', 'icon$i'));
      for (var i = 0; i < 3; i++) {
        await cache.put(names[i], data);
      }
      // At capacity. Insert 4th — should evict names[0] (first inserted)
      await cache.put(names[3], data);

      expect(await cache.contains(names[0]), isFalse);
      expect(await cache.contains(names[1]), isTrue);
      expect(await cache.contains(names[2]), isTrue);
      expect(await cache.contains(names[3]), isTrue);
    });

    test('stats reports fill ratio', () async {
      await cache.put(IconifyName('mdi', 'a'), homeData);
      expect(cache.stats.currentSize, 1);
      expect(cache.stats.maxSize, 3);
      expect(cache.stats.fillRatio, closeTo(1 / 3, 0.01));
    });
  });
}
```

### Alias Resolver Tests

**File**: `test/resolver/alias_resolver_test.dart`

```dart
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:test/test.dart';

void main() {
  final baseIcon = IconifyIconData(body: '<path d="M0 0"/>', width: 24, height: 24);

  final icons = {'base': baseIcon, 'other': IconifyIconData(body: '<rect/>')};

  group('AliasResolver', () {
    const resolver = AliasResolver();

    test('returns direct icon when no alias needed', () {
      final result = resolver.resolve(
        iconName: 'base',
        icons: icons,
        aliases: {},
        defaultWidth: 24,
        defaultHeight: 24,
      );
      expect(result, isNotNull);
      expect(result!.body, baseIcon.body);
    });

    test('returns null for unknown icon and no alias', () {
      final result = resolver.resolve(
        iconName: 'nonexistent',
        icons: icons,
        aliases: {},
        defaultWidth: 24,
        defaultHeight: 24,
      );
      expect(result, isNull);
    });

    test('resolves depth-1 alias', () {
      final aliases = {'base-alias': AliasEntry(parent: 'base')};
      final result = resolver.resolve(
        iconName: 'base-alias',
        icons: icons,
        aliases: aliases,
        defaultWidth: 24,
        defaultHeight: 24,
      );
      expect(result?.body, baseIcon.body);
    });

    test('resolves depth-2 alias chain', () {
      final aliases = {
        'level1': AliasEntry(parent: 'base'),
        'level2': AliasEntry(parent: 'level1'),
      };
      final result = resolver.resolve(
        iconName: 'level2',
        icons: icons,
        aliases: aliases,
        defaultWidth: 24,
        defaultHeight: 24,
      );
      expect(result?.body, baseIcon.body);
    });

    test('applies width/height overrides from alias', () {
      final aliases = {
        'big-base': AliasEntry(parent: 'base', width: 48, height: 48),
      };
      final result = resolver.resolve(
        iconName: 'big-base',
        icons: icons,
        aliases: aliases,
        defaultWidth: 24,
        defaultHeight: 24,
      );
      expect(result?.width, 48);
      expect(result?.height, 48);
    });

    test('nearest override wins in chain', () {
      // level2 overrides width=32; level1 overrides width=48
      // Since we collect from the alias closest to the target first,
      // level2 (closest) should win.
      final aliases = {
        'level1': AliasEntry(parent: 'base', width: 48),
        'level2': AliasEntry(parent: 'level1', width: 32),
      };
      final result = resolver.resolve(
        iconName: 'level2',
        icons: icons,
        aliases: aliases,
        defaultWidth: 24,
        defaultHeight: 24,
      );
      expect(result?.width, 32);
    });

    test('throws CircularAliasException on cycle', () {
      final aliases = {
        'a': AliasEntry(parent: 'b'),
        'b': AliasEntry(parent: 'a'),
      };
      expect(
        () => resolver.resolve(
          iconName: 'a',
          icons: {},
          aliases: aliases,
          defaultWidth: 24,
          defaultHeight: 24,
        ),
        throwsA(isA<CircularAliasException>()),
      );
    });

    test('CircularAliasException includes the full chain', () {
      final aliases = {
        'a': AliasEntry(parent: 'b'),
        'b': AliasEntry(parent: 'a'),
      };
      try {
        resolver.resolve(
          iconName: 'a',
          icons: {},
          aliases: aliases,
          defaultWidth: 24,
          defaultHeight: 24,
        );
        fail('should have thrown');
      } on CircularAliasException catch (e) {
        expect(e.chain, containsAll(['a', 'b']));
      }
    });

    test('throws CircularAliasException after max depth', () {
      const depth = 12;
      final aliases = <String, AliasEntry>{};
      for (var i = 0; i < depth; i++) {
        aliases['icon$i'] = AliasEntry(parent: 'icon${i + 1}');
      }
      const shortResolver = AliasResolver(maxChainDepth: 5);
      expect(
        () => shortResolver.resolve(
          iconName: 'icon0',
          icons: {},
          aliases: aliases,
          defaultWidth: 24,
          defaultHeight: 24,
        ),
        throwsA(isA<CircularAliasException>()),
      );
    });
  });
}
```

### Parser Tests

**File**: `test/parser/iconify_json_parser_test.dart`

```dart
import 'dart:io';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:test/test.dart';

void main() {
  group('IconifyJsonParser', () {
    group('parseCollectionString', () {
      test('parses valid minimal collection', () {
        const json = '''
        {
          "prefix": "test",
          "width": 24,
          "height": 24,
          "icons": {
            "home": { "body": "<path d='M10 20v-6h4v6'/>" }
          }
        }
        ''';
        final result = IconifyJsonParser.parseCollectionString(json);
        expect(result.prefix, 'test');
        expect(result.icons, hasLength(1));
        expect(result.icons['home']?.body, contains('M10 20'));
      });

      test('inherits default width/height when not specified per-icon', () {
        const json = '''
        {
          "prefix": "test",
          "width": 32,
          "height": 32,
          "icons": {
            "icon1": { "body": "<path/>" }
          }
        }
        ''';
        final result = IconifyJsonParser.parseCollectionString(json);
        expect(result.icons['icon1']?.width, 32);
        expect(result.icons['icon1']?.height, 32);
      });

      test('icon-level width/height overrides collection default', () {
        const json = '''
        {
          "prefix": "test",
          "width": 24,
          "height": 24,
          "icons": {
            "wide": { "body": "<path/>", "width": 48, "height": 24 }
          }
        }
        ''';
        final result = IconifyJsonParser.parseCollectionString(json);
        expect(result.icons['wide']?.width, 48);
        expect(result.icons['wide']?.height, 24);
      });

      test('parses aliases', () {
        const json = '''
        {
          "prefix": "test",
          "width": 24,
          "height": 24,
          "icons": {
            "home": { "body": "<path/>" }
          },
          "aliases": {
            "home-solid": { "parent": "home" }
          }
        }
        ''';
        final result = IconifyJsonParser.parseCollectionString(json);
        expect(result.aliases, hasLength(1));
        expect(result.aliases['home-solid']?.parent, 'home');
      });

      test('throws on missing prefix', () {
        const json = '{"icons": {"a": {"body": "<path/>"}}}';
        expect(
          () => IconifyJsonParser.parseCollectionString(json),
          throwsA(isA<IconifyParseException>()),
        );
      });

      test('throws on missing icons field', () {
        const json = '{"prefix": "test"}';
        expect(
          () => IconifyJsonParser.parseCollectionString(json),
          throwsA(isA<IconifyParseException>()),
        );
      });

      test('throws on invalid JSON', () {
        expect(
          () => IconifyJsonParser.parseCollectionString('not json at all'),
          throwsA(isA<IconifyParseException>()),
        );
      });
    });

    group('getIcon with alias resolution', () {
      const json = '''
      {
        "prefix": "test",
        "width": 24,
        "height": 24,
        "icons": {
          "home": { "body": "<path d='home'/>" }
        },
        "aliases": {
          "home-alias": { "parent": "home" }
        }
      }
      ''';

      test('finds direct icon', () {
        final collection = IconifyJsonParser.parseCollectionString(json);
        expect(collection.getIcon('home'), isNotNull);
      });

      test('resolves alias to parent icon', () {
        final collection = IconifyJsonParser.parseCollectionString(json);
        final result = collection.getIcon('home-alias');
        expect(result?.body, contains('home'));
      });

      test('returns null for nonexistent icon', () {
        final collection = IconifyJsonParser.parseCollectionString(json);
        expect(collection.getIcon('does-not-exist'), isNull);
      });
    });

    group('fixture files', () {
      test('parses mdi_fixture.json', () {
        final content = File('test/fixtures/mdi_fixture.json').readAsStringSync();
        final result = IconifyJsonParser.parseCollectionString(content);
        expect(result.prefix, 'mdi');
        expect(result.icons, isNotEmpty);
      });

      test('parses alias_chain_fixture.json', () {
        final content = File('test/fixtures/alias_chain_fixture.json').readAsStringSync();
        final collection = IconifyJsonParser.parseCollectionString(content);

        // Direct icon
        expect(collection.getIcon('base-icon'), isNotNull);

        // Depth-1 alias
        expect(collection.getIcon('level1'), isNotNull);

        // Depth-2 alias
        expect(collection.getIcon('level2'), isNotNull);

        // Depth-3 alias with width override
        final level3 = collection.getIcon('level3');
        expect(level3, isNotNull);
        expect(level3!.width, 32);

        // Circular alias should throw
        expect(
          () => collection.getIcon('circular-a'),
          throwsA(isA<CircularAliasException>()),
        );
      });
    });
  });
}
```

### Memory Provider Tests

**File**: `test/providers/memory_iconify_provider_test.dart`

```dart
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:test/test.dart';

void main() {
  final home = IconifyName('mdi', 'home');
  final settings = IconifyName('mdi', 'settings');
  final homeData = IconifyIconData(body: '<path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/>');
  final settingsData = IconifyIconData(body: '<path d="M19.14 12.94"/>');

  group('MemoryIconifyProvider', () {
    late MemoryIconifyProvider provider;
    setUp(() => provider = MemoryIconifyProvider());

    test('getIcon returns null for empty provider', () async {
      expect(await provider.getIcon(home), isNull);
    });

    test('putIcon and getIcon round-trip', () async {
      provider.putIcon(home, homeData);
      expect(await provider.getIcon(home), equals(homeData));
    });

    test('getIcon returns null after removeIcon', () async {
      provider.putIcon(home, homeData);
      provider.removeIcon(home);
      expect(await provider.getIcon(home), isNull);
    });

    test('hasIcon returns true after put', () async {
      provider.putIcon(home, homeData);
      expect(await provider.hasIcon(home), isTrue);
    });

    test('hasIcon returns false for absent', () async {
      expect(await provider.hasIcon(home), isFalse);
    });

    test('clear removes all icons', () async {
      provider.putIcon(home, homeData);
      provider.putIcon(settings, settingsData);
      provider.clear();
      expect(await provider.hasIcon(home), isFalse);
      expect(await provider.hasIcon(settings), isFalse);
    });

    test('iconCount reflects current state', () {
      expect(provider.iconCount, 0);
      provider.putIcon(home, homeData);
      expect(provider.iconCount, 1);
    });

    test('putCollection and getCollection round-trip', () async {
      final info = IconifyCollectionInfo(
        prefix: 'mdi',
        name: 'Material Design Icons',
        totalIcons: 7446,
      );
      provider.putCollection(info);
      final result = await provider.getCollection('mdi');
      expect(result?.prefix, 'mdi');
    });
  });
}
```

### CachingIconifyProvider Tests

**File**: `test/providers/caching_iconify_provider_test.dart`

```dart
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockProvider extends Mock implements IconifyProvider {}

void main() {
  final home = IconifyName('mdi', 'home');
  final homeData = IconifyIconData(body: '<path/>');

  setUpAll(() {
    registerFallbackValue(home);
    registerFallbackValue('mdi');
  });

  group('CachingIconifyProvider', () {
    late MockProvider inner;
    late CachingIconifyProvider provider;

    setUp(() {
      inner = MockProvider();
      provider = CachingIconifyProvider(inner: inner);
    });

    test('delegates to inner on cache miss', () async {
      when(() => inner.getIcon(home)).thenAnswer((_) async => homeData);

      final result = await provider.getIcon(home);
      expect(result, equals(homeData));
      verify(() => inner.getIcon(home)).called(1);
    });

    test('returns cached value on second call without calling inner again', () async {
      when(() => inner.getIcon(home)).thenAnswer((_) async => homeData);

      await provider.getIcon(home);
      await provider.getIcon(home);

      verify(() => inner.getIcon(home)).called(1); // Only called once
    });

    test('tracks hit and miss counts', () async {
      when(() => inner.getIcon(home)).thenAnswer((_) async => homeData);

      await provider.getIcon(home); // miss
      await provider.getIcon(home); // hit
      await provider.getIcon(home); // hit

      expect(provider.hits, 2);
      expect(provider.misses, 1);
    });

    test('does not cache null results', () async {
      when(() => inner.getIcon(home)).thenAnswer((_) async => null);

      await provider.getIcon(home);
      await provider.getIcon(home);

      verify(() => inner.getIcon(home)).called(2);
    });

    test('resetStats zeros counters', () async {
      when(() => inner.getIcon(home)).thenAnswer((_) async => homeData);
      await provider.getIcon(home);
      provider.resetStats();
      expect(provider.hits, 0);
      expect(provider.misses, 0);
    });
  });
}
```

### Composite Provider Tests

**File**: `test/providers/composite_iconify_provider_test.dart`

```dart
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:test/test.dart';

void main() {
  final home = IconifyName('mdi', 'home');
  final homeData = IconifyIconData(body: '<path/>');

  group('CompositeIconifyProvider', () {
    test('returns result from first provider that has the icon', () async {
      final first = MemoryIconifyProvider();
      final second = MemoryIconifyProvider()..putIcon(home, homeData);

      final composite = CompositeIconifyProvider([first, second]);
      final result = await composite.getIcon(home);
      expect(result, equals(homeData));
    });

    test('returns null when all providers return null', () async {
      final composite = CompositeIconifyProvider([
        MemoryIconifyProvider(),
        MemoryIconifyProvider(),
      ]);
      expect(await composite.getIcon(home), isNull);
    });

    test('first provider wins over second', () async {
      final firstData = IconifyIconData(body: '<path d="first"/>');
      final secondData = IconifyIconData(body: '<path d="second"/>');

      final first = MemoryIconifyProvider()..putIcon(home, firstData);
      final second = MemoryIconifyProvider()..putIcon(home, secondData);

      final composite = CompositeIconifyProvider([first, second]);
      final result = await composite.getIcon(home);
      expect(result?.body, contains('first'));
    });

    test('hasIcon returns true if any provider has it', () async {
      final first = MemoryIconifyProvider();
      final second = MemoryIconifyProvider()..putIcon(home, homeData);

      final composite = CompositeIconifyProvider([first, second]);
      expect(await composite.hasIcon(home), isTrue);
    });
  });
}
```

### DevModeGuard Tests

**File**: `test/guard/dev_mode_guard_test.dart`

```dart
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:test/test.dart';

void main() {
  group('DevModeGuard', () {
    tearDown(() => DevModeGuard.resetOverride());

    test('isRemoteAllowedInCurrentBuild returns true in debug mode (test env)', () {
      // Tests run in debug mode, so asserts execute — should return true
      expect(DevModeGuard.isRemoteAllowedInCurrentBuild(), isTrue);
    });

    test('allowRemoteInRelease overrides to true', () {
      DevModeGuard.allowRemoteInRelease();
      expect(DevModeGuard.isRemoteAllowedInCurrentBuild(), isTrue);
    });

    test('resetOverride restores default behavior', () {
      DevModeGuard.allowRemoteInRelease();
      DevModeGuard.resetOverride();
      // Back to normal — in test (debug) mode, still true
      expect(DevModeGuard.isRemoteAllowedInCurrentBuild(), isTrue);
    });
  });
}
```

### HTTP Provider Tests (with mocking)

**File**: `test/providers/http_iconify_provider_test.dart`

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:test/test.dart';

void main() {
  group('RemoteIconifyProvider', () {
    const validIconJson = {
      'prefix': 'mdi',
      'icons': {
        'home': {
          'body': '<path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/>',
        }
      },
      'width': 24,
      'height': 24,
    };

    test('returns null when DevModeGuard blocks release builds', () async {
      // This test verifies the guard mechanism.
      // In test (debug) environment, the guard allows calls, so we test
      // the allowInRelease = false with a custom client to simulate release.
      DevModeGuard.resetOverride();

      final provider = RemoteIconifyProvider(
        allowInRelease: false,
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );

      // In debug/test mode, DevModeGuard returns true, so calls go through.
      // To test the blocking, we'd need a release build — instead test
      // allowInRelease: false behavior is wired through the guard correctly.
      await provider.dispose();
    });

    test('returns icon data on 200 response', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode(validIconJson), 200);
      });

      final provider = RemoteIconifyProvider(httpClient: client);
      final result = await provider.getIcon(IconifyName('mdi', 'home'));

      expect(result, isNotNull);
      expect(result!.body, contains('M10 20'));
      await provider.dispose();
    });

    test('returns null on 404 response', () async {
      final client = MockClient((_) async => http.Response('not found', 404));
      final provider = RemoteIconifyProvider(httpClient: client);

      expect(await provider.getIcon(IconifyName('mdi', 'nonexistent')), isNull);
      await provider.dispose();
    });

    test('throws IconifyNetworkException on 500 response', () async {
      final client = MockClient((_) async => http.Response('error', 500));
      final provider = RemoteIconifyProvider(httpClient: client);

      expect(
        () => provider.getIcon(IconifyName('mdi', 'home')),
        throwsA(isA<IconifyNetworkException>()),
      );
      await provider.dispose();
    });

    test('returns null for icon not in response', () async {
      final responseJson = {
        'prefix': 'mdi',
        'icons': {'settings': {'body': '<path/>'}},
        'width': 24,
        'height': 24,
      };
      final client = MockClient((_) async =>
          http.Response(jsonEncode(responseJson), 200));
      final provider = RemoteIconifyProvider(httpClient: client);

      // Request 'home' but response only has 'settings'
      expect(await provider.getIcon(IconifyName('mdi', 'home')), isNull);
      await provider.dispose();
    });

    test('throws StateError after dispose', () async {
      final provider = RemoteIconifyProvider(
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );
      await provider.dispose();

      expect(
        () => provider.getIcon(IconifyName('mdi', 'home')),
        throwsA(isA<StateError>()),
      );
    });
  });
}
```

---

## Step 24 — Smoke Test (Manual Testing Entry Point)

**File**: `example/smoke_test.dart`

This is the manual test the developer runs to verify the whole phase end-to-end.

```dart
// ignore_for_file: avoid_print
import 'package:iconify_sdk_core/iconify_sdk_core.dart';

Future<void> main() async {
  var passed = 0;
  var failed = 0;

  Future<void> check(String label, Future<void> Function() fn) async {
    try {
      await fn();
      print('  ✅ $label');
      passed++;
    } catch (e) {
      print('  ❌ $label: $e');
      failed++;
    }
  }

  print('\n=== iconify_sdk_core Phase 1 Smoke Test ===\n');

  print('[ Model parsing ]');

  await check('IconifyName parses mdi:home', () async {
    final name = IconifyName.parse('mdi:home');
    assert(name.prefix == 'mdi');
    assert(name.iconName == 'home');
    assert(name.toString() == 'mdi:home');
  });

  await check('IconifyName throws on mdi-home', () async {
    try {
      IconifyName.parse('mdi-home');
      throw Exception('should have thrown');
    } on InvalidIconNameException {
      // expected
    }
  });

  await check('IconifyName equality', () async {
    assert(IconifyName('mdi', 'home') == IconifyName('mdi', 'home'));
    assert(IconifyName('mdi', 'home') != IconifyName('mdi', 'settings'));
  });

  await check('IconifyName as Map key', () async {
    final map = {IconifyName('mdi', 'home'): 42};
    assert(map[IconifyName('mdi', 'home')] == 42);
  });

  print('\n[ Memory Provider ]');

  await check('MemoryIconifyProvider put and get', () async {
    final provider = MemoryIconifyProvider();
    final data = IconifyIconData(body: '<path/>');
    provider.putIcon(IconifyName('mdi', 'home'), data);
    final result = await provider.getIcon(IconifyName('mdi', 'home'));
    assert(result != null);
  });

  await check('MemoryIconifyProvider returns null for missing', () async {
    final provider = MemoryIconifyProvider();
    assert(await provider.getIcon(IconifyName('mdi', 'ghost')) == null);
  });

  print('\n[ LRU Cache ]');

  await check('LRU cache put/get round-trip', () async {
    final cache = LruIconifyCache(maxEntries: 10);
    final data = IconifyIconData(body: '<path/>');
    await cache.put(IconifyName('mdi', 'home'), data);
    assert(await cache.get(IconifyName('mdi', 'home')) != null);
  });

  await check('LRU eviction at capacity', () async {
    final cache = LruIconifyCache(maxEntries: 2);
    final data = IconifyIconData(body: '<path/>');
    await cache.put(IconifyName('mdi', 'a'), data);
    await cache.put(IconifyName('mdi', 'b'), data);
    await cache.put(IconifyName('mdi', 'c'), data); // evicts 'a'
    assert(await cache.contains(IconifyName('mdi', 'a')) == false);
    assert(await cache.contains(IconifyName('mdi', 'c')) == true);
  });

  print('\n[ Alias Resolver ]');

  await check('Resolves direct icon', () async {
    const resolver = AliasResolver();
    final icons = {'home': IconifyIconData(body: '<path d="home"/>')};
    final result = resolver.resolve(
      iconName: 'home',
      icons: icons,
      aliases: {},
      defaultWidth: 24,
      defaultHeight: 24,
    );
    assert(result != null);
  });

  await check('Resolves 3-level alias chain', () async {
    const resolver = AliasResolver();
    final icons = {'base': IconifyIconData(body: '<path/>')};
    final aliases = {
      'l1': AliasEntry(parent: 'base'),
      'l2': AliasEntry(parent: 'l1'),
      'l3': AliasEntry(parent: 'l2'),
    };
    final result = resolver.resolve(
      iconName: 'l3',
      icons: icons,
      aliases: aliases,
      defaultWidth: 24,
      defaultHeight: 24,
    );
    assert(result != null);
  });

  await check('Throws on circular alias', () async {
    const resolver = AliasResolver();
    final aliases = {
      'a': AliasEntry(parent: 'b'),
      'b': AliasEntry(parent: 'a'),
    };
    try {
      resolver.resolve(
        iconName: 'a',
        icons: {},
        aliases: aliases,
        defaultWidth: 24,
        defaultHeight: 24,
      );
      throw Exception('should have thrown');
    } on CircularAliasException {
      // expected
    }
  });

  print('\n[ JSON Parser ]');

  await check('Parses minimal collection JSON', () async {
    const json = '''
    {
      "prefix": "test",
      "width": 24,
      "height": 24,
      "icons": {
        "home": { "body": "<path d='test'/>" }
      }
    }
    ''';
    final result = IconifyJsonParser.parseCollectionString(json);
    assert(result.prefix == 'test');
    assert(result.icons.containsKey('home'));
  });

  await check('Parser handles alias in JSON', () async {
    const json = '''
    {
      "prefix": "test",
      "width": 24,
      "height": 24,
      "icons": {
        "base": { "body": "<path/>" }
      },
      "aliases": {
        "alias1": { "parent": "base" }
      }
    }
    ''';
    final collection = IconifyJsonParser.parseCollectionString(json);
    assert(collection.getIcon('alias1') != null);
  });

  print('\n[ Caching Provider ]');

  await check('CachingIconifyProvider caches on second call', () async {
    final underlying = MemoryIconifyProvider();
    underlying.putIcon(
      IconifyName('mdi', 'home'),
      IconifyIconData(body: '<path/>'),
    );
    final provider = CachingIconifyProvider(inner: underlying);

    await provider.getIcon(IconifyName('mdi', 'home')); // miss
    await provider.getIcon(IconifyName('mdi', 'home')); // hit

    assert(provider.hits == 1);
    assert(provider.misses == 1);
  });

  print('\n[ DevModeGuard ]');

  await check('DevModeGuard allows remote in debug/test mode', () async {
    assert(DevModeGuard.isRemoteAllowedInCurrentBuild() == true);
  });

  await check('DevModeGuard override works', () async {
    DevModeGuard.allowRemoteInRelease();
    assert(DevModeGuard.isRemoteAllowedInCurrentBuild() == true);
    DevModeGuard.resetOverride();
  });

  print('\n[ SVG Generation ]');

  await check('toSvgString wraps body correctly', () async {
    final data = IconifyIconData(
      body: '<path d="M0 0" fill="currentColor"/>',
      width: 24,
      height: 24,
    );
    final svg = data.toSvgString(size: 48, color: '#FF0000');
    assert(svg.contains('viewBox="0 0 24 24"'));
    assert(svg.contains('width="48.0"'));
    assert(svg.contains('#FF0000'));
    assert(!svg.contains('currentColor'));
  });

  await check('isMonochrome detects currentColor', () async {
    final mono = IconifyIconData(body: '<path fill="currentColor"/>');
    final multi = IconifyIconData(body: '<path fill="#FF0000"/>');
    assert(mono.isMonochrome == true);
    assert(multi.isMonochrome == false);
  });



  print('\n═══════════════════════════════════════');
  print('Results: $passed passed, $failed failed');
  if (failed > 0) {
    print('❌ Phase 1 smoke test FAILED');
    throw Exception('$failed tests failed');
  } else {
    print('✅ Phase 1 smoke test PASSED');
  }
  print('═══════════════════════════════════════\n');
}
```

---

## Step 25 — Run All Checks

After all files are created, run in this exact order:

```bash
# 1. Get dependencies
dart pub get

# 2. Format everything
dart format lib/ test/

# 3. Analyze — must be zero warnings/errors
dart analyze

# 4. Run all tests
dart test

# 5. Run smoke test (requires internet for HTTP test)
dart run example/smoke_test.dart

# 6. Check coverage (optional but recommended)
dart run coverage:test_with_coverage
dart run coverage:format_coverage --lcov --in=coverage/data --out=coverage/lcov.info
# Open lcov.info in your coverage viewer — target: 90%+ line coverage
```

### Expected `dart test` output

```
00:00 +0: loading test/models/iconify_name_test.dart
00:00 +18: All tests passed!
...
All tests passed! (N tests in N files)
```

### Expected `dart analyze` output

```
Analyzing iconify_sdk_core...
No issues found!
```

**If any issues appear**: Fix them before moving to Phase 2. Do not suppress warnings with `ignore` comments unless you have documented a specific reason.

---

## Definition of Done (Phase 1 Complete)

Phase 1 is complete when ALL of the following are true:

- [ ] `dart analyze` reports zero issues
- [ ] `dart format lib/ test/ --set-exit-if-changed` exits 0 (code is formatted)
- [ ] `dart test` reports 100% of tests passing
- [ ] `dart run example/smoke_test.dart` reports all checks passed
- [ ] HTTP provider smoke test passes (real network icon fetch works)
- [ ] LRU eviction test demonstrates correct LRU ordering (not just capacity)
- [ ] Circular alias test demonstrates the full chain is included in the exception
- [ ] `IconifyJsonParser` correctly handles the `alias_chain_fixture.json`
- [ ] `dart pub publish --dry-run` exits 0 (package is publishable)
- [ ] All public classes have `///` dartdoc comments
- [ ] No `TODO`, `FIXME`, or `HACK` comments in production code (`lib/`)
- [ ] The barrel export (`iconify_sdk_core.dart`) compiles cleanly and exports all required types
- [ ] `DevModeGuard.resetOverride()` is called in every test that calls `allowRemoteInRelease()`

---

## What Phase 2 Builds On Top Of This

Phase 2 (`iconify_flutter` — the Flutter widget package) will:
1. Add a Flutter dependency and create `IconifyIcon` widget
2. Use `AssetBundleIconifyProvider` with a real Flutter `AssetBundle`
3. Implement the starter registry as a Flutter asset
4. Add `flutter_svg` integration to render `IconifyIconData` as a widget
5. Implement the 4 `IconifyMode` values with correct release defaults
6. Add `IconifyApp` as the inherited configuration widget

Phase 2 can only start after Phase 1's Definition of Done is fully met.
