# iconify_sdk — Complete Project Roadmap

> Version: 1.0 | Date: 2026-03-12  
> Based on: Refined Production Plan v2.0  
> Packages: `iconify_sdk_core` · `iconify_sdk` · `iconify_sdk_builder` · `iconify_sdk_cli`

---

## Reading This Document

- **Phases** are sequential — do not start a phase until the previous one's exit criteria are met
- **Tasks** within a phase can often be parallelized
- **Subtasks** are atomic units of work (one subtask = one focused coding session)
- `[AGENT]` = Claude Code agent handles this
- `[HUMAN]` = requires human decision or manual action
- `[CI]` = automated pipeline handles this
- `🔴 CRITICAL` = blocking risk; must not be deferred

---

## Package Dependency Graph

```
iconify_sdk_core        (pure Dart, no Flutter)
        ↑
iconify_sdk             (Flutter widgets, depends on core)
        ↑
iconify_sdk_builder     (build_runner, depends on core — NO Flutter dep)
        ↑
iconify_sdk_cli         (Dart CLI, depends on core — NO Flutter dep)
```

Build order is strict: core → flutter → builder → cli.  
Builder and CLI are siblings; either can be built after `iconify_sdk` is stable.

---

## Phase Overview

| Phase | Name | Packages Touched | Duration (part-time) | Exit Gate |
|---|---|---|---|---|
| 0 | Design Lock | All (setup only) | 1–2 weeks | ADRs signed, monorepo green, names reserved |
| 1 | Core Engine | `iconify_sdk_core` | 3–4 weeks | ✅ All tests pass, publishable dry-run OK |
| 2 | Flutter Package | `iconify_sdk` | 2–3 weeks | One-liner widget works, release mode blocks remote |
| 3 | build_runner Builder | `iconify_sdk_builder` | 2–3 weeks | `build_runner build` generates correct Dart code |
| 4 | CLI MVP | `iconify_sdk_cli` | 4–5 weeks | Full offline workflow end-to-end |
| 5 | Correctness | All | 2–3 weeks | Impeller golden tests pass on real devices |
| 6 | v1 Launch | All | 2–3 weeks | Publishable, documented, real-world tested |
| 7 | Post-v1 | All | Ongoing | Community traction, tooling moat |

**Total to v1:** ~16–23 weeks part-time

---

---

# Phase 0 — Design Lock

> **Goal:** Everything decided on paper before a single line of production code is written.  
> **Exit Criteria:** All ADRs merged, monorepo skeleton builds, all four package names reserved on pub.dev, CI runs on every PR.

---

## 0.1 — Package Name Reservation

- [x] `[HUMAN]` Create a pub.dev account (or use existing)
- [x] `[HUMAN]` Reserve `iconify_sdk_core` on pub.dev (publish a 0.0.1 placeholder)
- [x] `[HUMAN]` Reserve `iconify_sdk` on pub.dev
- [x] `[HUMAN]` Reserve `iconify_sdk_builder` on pub.dev
- [x] `[HUMAN]` Reserve `iconify_sdk_cli` on pub.dev
- [x] `[HUMAN]` Verify all four names are claimed and show your account as publisher

---

## 0.2 — Repository Setup

- [x] `[HUMAN]` Create GitHub repository: `iconify_sdk` (public)
- [x] `[AGENT]` Scaffold monorepo root with `pubspec.yaml` using Dart pub workspaces
- [x] `[AGENT]` Create `melos:` configuration block in root `pubspec.yaml`
- [x] `[AGENT]` Create empty package skeletons for all four packages (pubspec only, no code)
- [x] `[AGENT]` Create root `.gitignore` covering: `.dart_tool/`, `build/`, `*.g.dart`, `.flutter-plugins`, `pubspec.lock` (for packages), coverage output
- [x] `[AGENT]` Create root `analysis_options.yaml` with strict settings shared across all packages
- [x] `[AGENT]` Run `dart pub get` from root — verify zero errors
- [ ] `[HUMAN]` Push initial commit to `main`

---

## 0.3 — CI Skeleton

- [x] `[AGENT]` Create `.github/workflows/ci.yml` with:
  - [x] Trigger: pull_request + push to main
  - [x] Job: `analyze` — runs `dart analyze` across all packages
  - [x] Job: `format` — runs `dart format --set-exit-if-changed`
  - [x] Job: `test` — runs `dart test` in each package
  - [x] Matrix: Dart stable + Dart beta
- [x] `[AGENT]` Create `.github/workflows/publish.yml` (dry-run only for now)
  - [x] Trigger: push to `release/*` branch
  - [x] Job: `dart pub publish --dry-run` for each package
- [ ] `[HUMAN]` Verify CI runs green on first push

---

## 0.4 — Architecture Decision Records (ADRs)

Create `user-docs/adr/` directory. Each ADR is a markdown file.

- [x] `[HUMAN]` + `[AGENT]` Write **ADR-001**: Why `prefix:name` is the canonical identity (not generated constant names)
- [x] `[HUMAN]` + `[AGENT]` Write **ADR-002**: Why CLI + build_runner hybrid over CLI-only
- [x] `[HUMAN]` + `[AGENT]` Write **ADR-003**: Why release builds block remote by default (Iconify API ethics + reliability)
- [x] `[HUMAN]` + `[AGENT]` Write **ADR-004**: Rendering strategy — flutter_svg + Impeller fallback design
- [x] `[HUMAN]` + `[AGENT]` Write **ADR-005**: Why GitHub raw JSON is the CLI data source (not the Iconify HTTP API)
- [x] `[HUMAN]` + `[AGENT]` Write **ADR-006**: Three-package architecture rationale (core / flutter / builder+cli)
- [x] `[HUMAN]` + `[AGENT]` Write **ADR-007**: Starter registry contents and size budget
- [ ] `[HUMAN]` Review and approve all ADRs before Phase 1 starts

---

## 0.5 — Schema & Contract Definitions

- [x] `[HUMAN]` + `[AGENT]` Define and document `iconify.yaml` schema v1 (all fields, types, defaults)
  - [x] `sets:` — list of `prefix:name` patterns to include
  - [x] `output:` — path for generated Dart file
  - [x] `data_dir:` — local snapshot directory
  - [x] `mode:` — auto / offline / generated / remoteAllowed
  - [x] `license_policy:` — permissive / warn / strict
  - [x] `custom_sets:` — list of local JSON file paths
  - [x] `fail_on_missing:` — bool
- [x] `[AGENT]` Write JSON Schema for `iconify.yaml` (for IDE validation)
- [x] `[AGENT]` Write the normalized internal icon schema (schemaVersion, collections, icons, aliases, license)
- [ ] `[HUMAN]` Sign off on both schemas — no changes after Phase 1 starts without an ADR

---

## 0.6 — Starter Registry Definition

- [x] `[HUMAN]` Approve starter registry contents:
  - MDI top-150 icons by usage
  - Lucide top-100 icons
  - Tabler top-100 icons
  - Heroicons all (~300)
  - Collection metadata for all 208 sets (names + license only)
- [x] `[HUMAN]` Set size budget: under 200KB uncompressed
- [x] `[AGENT]` Create `data/starter/` directory with placeholder README

---

## 0.7 — License Research

- [x] `[HUMAN]` Compile the "safe collections" list (MIT/Apache/ISC, no attribution required)
- [x] `[HUMAN]` Compile the "attribution required" list (CC BY, CC BY-SA, custom)
- [x] `[HUMAN]` Compile the "do not bundle" list (GPL, non-commercial)
- [x] `[AGENT]` Write `docs/license-guide.md` with the three lists
- [ ] `[HUMAN]` Review and approve `license-guide.md`

---

## 0.8 — Phase 0 Exit Gate

- [x] All four package names reserved on pub.dev
- [x] Monorepo builds with `dart pub get` from root
- [x] CI passes on first real commit
- [x] All 7 ADRs written and approved
- [x] `iconify.yaml` schema v1 locked
- [x] `docs/license-guide.md` published in repo

---

---

# Phase 1 — Core Engine (`iconify_sdk_core`)

> **Goal:** Production-ready pure Dart package. Zero Flutter dependency. All providers, cache, alias resolution, and JSON parsing fully tested.  
> **Exit Criteria:** `dart analyze` zero issues, 100% tests passing, `dart pub publish --dry-run` clean.

---

## 1.1 — Package Scaffolding

- [x] `[AGENT]` Create `packages/core/pubspec.yaml`
  - [x] Dependencies: `http: ^1.2.0`, `meta: ^1.15.0`
  - [x] Dev dependencies: `test: ^1.25.0`, `mocktail: ^1.0.4`, `lints: ^4.0.0`, `http: ^1.2.0` (for `MockClient`)
  - [x] SDK: `>=3.3.0 <4.0.0`
- [x] `[AGENT]` Create `packages/core/analysis_options.yaml` with strict mode
- [x] `[AGENT]` Create directory structure: `lib/src/models/`, `lib/src/errors/`, `lib/src/providers/`, `lib/src/cache/`, `lib/src/resolver/`, `lib/src/parser/`, `lib/src/guard/`
- [x] `[AGENT]` Create `test/` mirror structure + `test/fixtures/`
- [x] `[AGENT]` Run `dart pub get` — verify clean

---

## 1.2 — Error Hierarchy

- [x] `[AGENT]` Create `lib/src/errors/iconify_exception.dart`
  - [x] `sealed class IconifyException` with `message` field
  - [x] `final class InvalidIconNameException` — includes `input` field
  - [x] `final class IconNotFoundException` — includes `name` + optional `suggestion`
  - [x] `final class CollectionNotFoundException` — includes `prefix` + `wasRemoteAttempted`
  - [x] `final class IconifyNetworkException` — includes `statusCode?` + `uri?`
  - [x] `final class IconifyLicenseException` — includes `prefix`
  - [x] `final class IconifyParseException` — includes `field?` + `rawValue?`
  - [x] `final class CircularAliasException` — includes `chain` (full chain list)
  - [x] `final class IconifyCacheException` — includes `cause?`
- [x] `[AGENT]` Write `test/errors/iconify_exception_test.dart`
  - [x] Test: each exception type is a subtype of `IconifyException`
  - [x] Test: `toString()` is non-empty and informative for each type
  - [x] Test: pattern matching works across all subtypes
- [x] `[CI]` `dart test test/errors/` — must pass

---

## 1.3 — Models

### 1.3.1 — IconifyName

- [x] `[AGENT]` Create `lib/src/models/iconify_name.dart`
  - [x] `@immutable final class IconifyName`
  - [x] `const` constructor `IconifyName(prefix, iconName)` — no validation (for generated code use)
  - [x] `factory IconifyName.parse(String value)` — full validation, descriptive error messages
  - [x] `static IconifyName? tryParse(String value)` — null on failure
  - [x] Regex: prefix `^[a-z0-9][a-z0-9\-]*[a-z0-9]$|^[a-z0-9]$`
  - [x] Regex: name same pattern
  - [x] Max length: 64 chars per part
  - [x] `==` and `hashCode` by value
  - [x] `toString()` returns `prefix:iconName`
- [x] `[AGENT]` Write `test/models/iconify_name_test.dart`
  - [x] Valid: simple, hyphens, digits, single-char
  - [x] Invalid: no colon, double colon, uppercase, leading/trailing hyphen, empty parts, too long
  - [x] Error messages contain helpful context
  - [x] Equality: same value equals, different value not equal
  - [x] Map key usage 
  - [x] Set deduplication
  - [x] `tryParse` returns null on bad input
- [x] `[CI]` Tests pass

### 1.3.2 — IconifyLicense

- [x] `[AGENT]` Create `lib/src/models/iconify_license.dart`
  - [x] Fields: `title?`, `spdx?`, `url?`, `requiresAttribution`
  - [x] `isKnownCommercialFriendly` getter — checks against known safe SPDX list
  - [x] `fromJson` / `toJson`
  - [x] `copyWith`
  - [x] Value equality
- [x] `[AGENT]` Write `test/models/iconify_license_test.dart`
  - [x] MIT/Apache/ISC are commercial friendly
  - [x] CC-BY-4.0 is NOT commercial friendly
  - [x] null spdx is NOT commercial friendly
  - [x] fromJson/toJson round-trip

### 1.3.3 — IconifyIconData

- [x] `[AGENT]` Create `lib/src/models/iconify_icon_data.dart`
  - [x] Fields: `body`, `width`, `height`, `aliases`, `hidden`, `rotate`, `hFlip`, `vFlip`, `raw`
  - [x] Defaults: width=24, height=24, all flags false
  - [x] `isMonochrome` getter — checks body for `currentColor`
  - [x] `isSquare` getter
  - [x] `toSvgString({size?, color?})` — wraps body in full SVG element
  - [x] `fromJson` / `toJson`
  - [x] `copyWith`
  - [x] Value equality by body + width + height
- [x] `[AGENT]` Write `test/models/iconify_icon_data_test.dart`
  - [x] `isMonochrome` true when body has `currentColor`
  - [x] `isMonochrome` false when body has explicit color
  - [x] `toSvgString` produces valid SVG string
  - [x] `toSvgString` with color replaces `currentColor`
  - [x] `toSvgString` does not replace color in non-monotone icon
  - [x] `fromJson` inherits defaults for missing fields
  - [x] `copyWith` produces new instance with changed field

### 1.3.4 — IconifyCollectionInfo

- [x] `[AGENT]` Create `lib/src/models/iconify_collection_info.dart`
  - [x] Fields: `prefix`, `name`, `totalIcons`, `author?`, `license?`, `samples`, `categories`, `tags`, `version?`, `raw`
  - [x] `requiresAttribution` delegate to license
  - [x] `isKnownCommercialFriendly` delegate to license
  - [x] `fromJson(prefix, json)` — handles both flat and nested `info:` structure
  - [x] `toJson`
  - [x] Equality by prefix
- [x] `[AGENT]` Write `test/models/iconify_collection_info_test.dart`
  - [x] Parses flat JSON structure
  - [x] Parses nested `info:` JSON structure
  - [x] `author` handles string and object forms
  - [x] `requiresAttribution` delegates correctly

### 1.3.5 — IconifySearchResult

- [x] `[AGENT]` Create `lib/src/models/iconify_search_result.dart`
  - [x] Fields: `name`, `score`, `matchedOn?`

---

## 1.4 — Provider Interface

- [x] `[AGENT]` Create `lib/src/providers/iconify_provider.dart`
  - [x] `abstract interface class IconifyProvider`
  - [x] `Future<IconifyIconData?> getIcon(IconifyName name)`
  - [x] `Future<IconifyCollectionInfo?> getCollection(String prefix)`
  - [x] `Future<bool> hasIcon(IconifyName name)`
  - [x] `Future<bool> hasCollection(String prefix)`
  - [x] `Future<void> dispose()` — default no-op implementation
  - [x] Dartdoc: null = not found, throw only on unexpected failure

---

## 1.5 — MemoryIconifyProvider

- [x] `[AGENT]` Create `lib/src/providers/memory_iconify_provider.dart`
  - [x] Backed by `Map<IconifyName, IconifyIconData>` and `Map<String, IconifyCollectionInfo>`
  - [x] `putIcon(name, data)` — public write method
  - [x] `putCollection(info)` — public write method
  - [x] `removeIcon(name)`
  - [x] `clear()`
  - [x] `iconCount` getter
- [x] `[AGENT]` Write `test/providers/memory_iconify_provider_test.dart`
  - [x] put + get round-trip
  - [x] returns null for missing key
  - [x] hasIcon true/false
  - [x] removeIcon deletes
  - [x] clear empties everything
  - [x] iconCount reflects state

---

## 1.6 — Cache

### 1.6.1 — Cache Interface

- [x] `[AGENT]` Create `lib/src/cache/iconify_cache.dart`
  - [x] `abstract interface class IconifyCache`
  - [x] `get`, `put`, `remove`, `clear`, `size`, `contains`

### 1.6.2 — LRU Cache

- [x] `[AGENT]` Create `lib/src/cache/lru_iconify_cache.dart`
  - [x] `LinkedHashMap`-based LRU (remove + re-insert on access = move to end)
  - [x] `maxEntries` constructor param, default 500
  - [x] Evicts least-recently-used entry when at capacity
  - [x] `LruCacheStats` class: `currentSize`, `maxSize`, `fillRatio`
  - [x] `stats` getter
- [x] `[AGENT]` Write `test/cache/lru_iconify_cache_test.dart`
  - [x] put + get
  - [x] null for missing
  - [x] contains true/false
  - [x] remove
  - [x] clear
  - [x] size
  - [x] evicts LRU when at capacity (access pattern matters)
  - [x] accessed entry is not evicted over never-accessed entry
  - [x] stats fill ratio

---

## 1.7 — CachingIconifyProvider

- [x] `[AGENT]` Create `lib/src/providers/caching_iconify_provider.dart`
  - [x] Decorator wrapping any `IconifyProvider`
  - [x] Default cache: `LruIconifyCache()`
  - [x] Tracks `hits` and `misses`
  - [x] `resetStats()`
  - [x] Does NOT cache null results (prevents caching "not found")
- [x] `[AGENT]` Write `test/providers/caching_iconify_provider_test.dart` with `mocktail`
  - [x] Cache miss delegates to inner
  - [x] Cache hit does NOT call inner second time
  - [x] hit/miss counters increment correctly
  - [x] null results not cached
  - [x] resetStats works
  - [x] dispose clears cache and disposes inner

---

## 1.8 — CompositeIconifyProvider

- [x] `[AGENT]` Create `lib/src/providers/composite_iconify_provider.dart`
  - [x] Tries providers in order, returns first non-null
  - [x] Throws if `providers` is empty
  - [x] Propagates exceptions from providers (does not swallow)
  - [x] `dispose()` disposes all providers
- [x] `[AGENT]` Write `test/providers/composite_iconify_provider_test.dart`
  - [x] First provider wins over second when both have icon
  - [x] Falls through to second when first returns null
  - [x] Returns null when all return null
  - [x] hasIcon true if any provider has it

---

## 1.9 — RemoteIconifyProvider

> ⚠️ **Renamed from `HttpIconifyProvider`**. This is a dev/debug escape hatch only. Not the production data path.

- [x] `[AGENT]` Create `lib/src/providers/remote_iconify_provider.dart`
  - [x] Class-level dartdoc: opens with WARNING — not for production use, self-host for production
  - [x] Default `apiBase`: `https://api.iconify.design`
  - [x] `allowInRelease` constructor param — default `false`
  - [x] Gated by `DevModeGuard.isRemoteAllowedInCurrentBuild()` — returns null if blocked
  - [x] `User-Agent` header: `iconify_sdk_core/{version} (Dart)`
  - [x] On 404: return null
  - [x] On non-200: throw `IconifyNetworkException` with status + uri
  - [x] On network error: throw `IconifyNetworkException`
  - [x] Applies collection-level width/height defaults to per-icon data
  - [x] `dispose()` closes http client + sets disposed flag
  - [x] `StateError` if called after dispose
- [x] `[AGENT]` Write `test/providers/remote_iconify_provider_test.dart` — **mocked client only, no real network calls**
  - [x] Returns icon data on 200 response
  - [x] Returns null on 404
  - [x] Throws `IconifyNetworkException` on 500
  - [x] Returns null for icon name not in response
  - [x] `StateError` after dispose
  - [x] Returns null when DevModeGuard blocks (simulate release mode via `allowInRelease: false`)

---

## 1.10 — FileSystemIconifyProvider

- [x] `[AGENT]` Create `lib/src/providers/file_system_iconify_provider.dart`
  - [x] Constructor: `root` directory path, optional `preload` flag
  - [x] Reads `{root}/{prefix}.json` files
  - [x] Lazy load per-collection (cache parsed JSON in memory after first read)
  - [x] `preload: true` loads all JSON files in the directory at construction
  - [x] `IconifyParseException` on malformed JSON
- [x] `[AGENT]` Write `test/providers/file_system_iconify_provider_test.dart`
  - [x] Returns null for missing collection
  - [x] Reads and parses valid JSON file
  - [x] Returns correct icon from parsed file
  - [x] Returns null for missing icon in valid collection
  - [x] Throws `IconifyParseException` for malformed JSON file

---

## 1.11 — AssetBundleIconifyProvider (abstract stub)

- [x] `[AGENT]` Create `lib/src/providers/asset_bundle_iconify_provider.dart`
  - [x] `abstract class AssetBundleIconifyProvider implements IconifyProvider`
  - [x] `assetPrefix` field
  - [x] `Future<String> loadAssetString(String path)` — abstract, implemented in `iconify_sdk`
  - [x] Default implementations of `hasIcon` and `hasCollection`
  - [x] Dartdoc: "concrete implementation in `iconify_sdk` package"

---

## 1.12 — DevModeGuard

- [x] `[AGENT]` Create `lib/src/guard/dev_mode_guard.dart`
  - [x] `abstract final class DevModeGuard` (non-instantiable)
  - [x] `isRemoteAllowedInCurrentBuild()` — uses `assert()` trick to detect debug mode
  - [x] `allowRemoteInRelease()` — explicit opt-in override
  - [x] `resetOverride()` — for tests only
  - [x] Dartdoc: explains why this exists (API ethics, reliability)
- [x] `[AGENT]` Write `test/guard/dev_mode_guard_test.dart`
  - [x] Returns true in test/debug mode
  - [x] `allowRemoteInRelease` forces true
  - [x] `resetOverride` restores default behavior
  - [x] tearDown always calls `resetOverride`

---

## 1.13 — Alias Resolver

- [x] `[AGENT]` Create `lib/src/resolver/alias_resolver.dart`
  - [x] `final class AliasResolver` with `maxChainDepth` (default 10)
  - [x] `resolve({iconName, icons, aliases, defaultWidth, defaultHeight})` — returns `IconifyIconData?`
  - [x] Direct icon match: no alias lookup
  - [x] Alias resolution: follow `parent` chain
  - [x] Collect overrides: nearest alias wins (width, height, rotate, hFlip, vFlip)
  - [x] Circular detection: check `chain.contains(parentName)` before adding
  - [x] Depth limit: throw `CircularAliasException` when chain > `maxChainDepth`
  - [x] `final class AliasEntry` with `parent`, optional override fields, `fromJson`
- [x] `[AGENT]` Write `test/resolver/alias_resolver_test.dart`
  - [x] Returns direct icon with no alias
  - [x] Returns null for unknown icon and no alias
  - [x] Resolves depth-1 alias
  - [x] Resolves depth-2 alias chain
  - [x] Resolves depth-3 alias chain
  - [x] Applies width/height override from alias
  - [x] Nearest alias wins when multiple overrides in chain
  - [x] `CircularAliasException` on two-node cycle
  - [x] `CircularAliasException` includes full chain in exception
  - [x] `CircularAliasException` on chain exceeding maxChainDepth

---

## 1.14 — Iconify JSON Parser

- [x] `[AGENT]` Create `lib/src/parser/iconify_json_parser.dart`
  - [x] `final class IconifyJsonParser` (no instances)
  - [x] `static ParsedCollection parseCollectionString(String jsonString)` — parses raw JSON string
  - [x] `static ParsedCollection parseCollection(Map<String, dynamic> json)` — parses decoded map
  - [x] `static IconifyIconData? extractIcon(Map<String, dynamic> collectionJson, String iconName)` — single-icon extraction with alias resolution
  - [x] Applies collection-level `width`/`height` defaults to icons missing those fields
  - [x] Skips malformed alias entries (non-fatal, logs warning)
  - [x] Throws `IconifyParseException` on: missing `prefix`, missing `icons`, invalid JSON
  - [x] `final class ParsedCollection` with `prefix`, `info`, `icons`, `aliases`, `defaultWidth`, `defaultHeight`
  - [x] `ParsedCollection.getIcon(iconName)` — resolves aliases
  - [x] `ParsedCollection.allNames` — all icon + alias names
  - [x] `ParsedCollection.iconCount` / `aliasCount`
- [x] `[AGENT]` Write `test/parser/iconify_json_parser_test.dart`
  - [x] Parses minimal valid collection
  - [x] Inherits default width/height for icons missing those fields
  - [x] Icon-level width/height overrides collection default
  - [x] Parses aliases map
  - [x] `getIcon` finds direct icon
  - [x] `getIcon` resolves alias to parent
  - [x] `getIcon` returns null for unknown name
  - [x] Throws `IconifyParseException` on missing `prefix`
  - [x] Throws `IconifyParseException` on missing `icons`
  - [x] Throws `IconifyParseException` on invalid JSON string
  - [x] Parses `mdi_fixture.json` from disk
  - [x] Parses `alias_chain_fixture.json` — verifies chain resolution + circular detection

---

## 1.15 — Test Fixtures

- [x] `[HUMAN]` Download real collection JSON files from GitHub raw (NOT the Iconify API):
  ```bash
  # Full collections — trim to needed icons after download
  curl "https://raw.githubusercontent.com/iconify/icon-sets/master/json/mdi.json" -o /tmp/mdi_full.json
  curl "https://raw.githubusercontent.com/iconify/icon-sets/master/json/lucide.json" -o /tmp/lucide_full.json
  curl "https://raw.githubusercontent.com/iconify/icon-sets/master/json/tabler.json" -o /tmp/tabler_full.json
  ```
- [x] `[AGENT]` Create `test/fixtures/mdi_fixture.json` — hand-trimmed to 10 icons + 3 aliases from downloaded MDI
- [x] `[AGENT]` Create `test/fixtures/lucide_fixture.json` — hand-trimmed to 5 icons
- [x] `[AGENT]` Create `test/fixtures/alias_chain_fixture.json` — custom file with: direct icon, depth-1 alias, depth-2 alias, depth-3 alias with override, circular pair
- [x] `[AGENT]` Create `test/fixtures/malformed_fixture.json` — missing `body` field on one icon, missing `prefix`

---

## 1.16 — Barrel Export

- [x] `[AGENT]` Create `lib/iconify_sdk_core.dart`
  - [x] Export all public types from all modules
  - [x] No `src/` internals exposed directly
  - [x] Library-level dartdoc with quick-start example

---

## 1.17 — Smoke Test

- [x] `[AGENT]` Create `example/smoke_test.dart`
  - [x] Covers: name parsing, invalid name error, memory provider round-trip, LRU eviction, alias resolution, circular alias, JSON parsing with alias, caching provider hit/miss counts, SVG string generation, DevModeGuard behavior
  - [x] Outputs `✅` / `❌` per check
  - [x] **NO live network calls** — all provider tests use local fixtures
  - [x] Exits non-zero if any check fails
- [x] `[HUMAN]` Run `dart run example/smoke_test.dart` — all checks green

---

## 1.18 — Phase 1 Exit Gate

- [x] `dart analyze` — zero issues
- [x] `dart format lib/ test/ --set-exit-if-changed` — exits 0
- [x] `dart test` — 100% passing, no skipped tests
- [x] `dart run example/smoke_test.dart` — all checks green
- [x] `dart pub publish --dry-run` — exits 0
- [x] All public APIs have `///` dartdoc
- [x] Zero `TODO` / `FIXME` / `HACK` in `lib/`
- [x] `DevModeGuard.resetOverride()` called in tearDown of every relevant test
- [x] No import of `package:flutter/*` anywhere in the package

---

---

# Phase 2 — Flutter Package (`iconify_sdk`)

> **Goal:** The one-liner `IconifyIcon('mdi:home')` works. Release builds make zero network calls by default. Starter registry ships with the package.  
> **Exit Criteria:** Widget renders in all 4 modes. Impeller color path tested on real device. Release mode verified to block remote.

---

## 2.1 — Package Scaffolding

- [ ] `[AGENT]` Create `packages/iconify_sdk/pubspec.yaml`
  - [ ] Flutter SDK dependency
  - [ ] Dependencies: `iconify_sdk_core`, `flutter_svg: ^2.0.0`, `meta: ^1.15.0`
  - [ ] Dev: `flutter_test`, `mocktail`, `alchemist` (golden testing)
- [ ] `[AGENT]` Create directory structure: `lib/src/widget/`, `lib/src/provider/`, `lib/src/config/`, `lib/src/registry/`, `lib/src/render/`
- [ ] `[AGENT]` Create `assets/iconify/starter/` directory for bundled registry files
- [ ] `[AGENT]` Register assets in `pubspec.yaml`: `assets/iconify/starter/`

---

## 2.2 — Flutter Asset Bundle Provider

- [ ] `[AGENT]` Create `lib/src/provider/flutter_asset_bundle_iconify_provider.dart`
  - [ ] Extends `AssetBundleIconifyProvider` from core
  - [ ] Implements `loadAssetString(path)` using Flutter's `rootBundle` or injected `AssetBundle`
  - [ ] Caches parsed JSON in memory after first load
  - [ ] Uses `IconifyJsonParser.parseCollection` internally
- [ ] `[AGENT]` Write widget tests for asset bundle provider using Flutter test `TestAssetBundle`

---

## 2.3 — Starter Registry

- [ ] `[AGENT]` Create tooling script `tools/build_starter_registry.dart` that:
  - [ ] Downloads top-N icons from MDI, Lucide, Tabler, Heroicons via GitHub raw
  - [ ] Builds trimmed JSON files under `assets/iconify/starter/`
  - [ ] Outputs a `starter_manifest.json` with collection metadata for all 208 sets
  - [ ] Validates total asset size stays under 200KB
- [ ] `[HUMAN]` Run `dart run tools/build_starter_registry.dart` and verify output
- [ ] `[HUMAN]` Review + commit the generated `assets/iconify/starter/` files
- [ ] `[AGENT]` Create `lib/src/registry/starter_registry.dart`
  - [ ] Loads starter JSON files from asset bundle at first use
  - [ ] Returns `MemoryIconifyProvider` pre-populated from starter data
  - [ ] Returns collection metadata from `starter_manifest.json`
  - [ ] Singleton pattern with lazy initialization

---

## 2.4 — IconifyMode & Configuration

- [ ] `[AGENT]` Create `lib/src/config/iconify_mode.dart`
  ```dart
  enum IconifyMode { auto, offline, generated, remoteAllowed }
  ```
- [ ] `[AGENT]` Create `lib/src/config/iconify_config.dart`
  - [ ] Fields: `mode`, `customProviders`, `cacheMaxEntries`, `remoteApiBase`
  - [ ] `IconifyConfig.defaults()` factory
- [ ] `[AGENT]` Create `lib/src/config/iconify_inherited_widget.dart`
  - [ ] `class IconifyScope extends InheritedWidget`
  - [ ] Holds resolved `CompositeIconifyProvider` based on mode + build type
  - [ ] `IconifyScope.of(context)` static accessor
  - [ ] `IconifyScope.maybeOf(context)` static accessor

---

## 2.5 — Mode-Based Provider Chain

- [ ] `[AGENT]` Create `lib/src/config/provider_chain_builder.dart`
  - [ ] `buildProviderChain(IconifyConfig config, BuildMode buildMode)` — returns `CompositeIconifyProvider`
  - [ ] `auto` mode in debug: `[memory, starterRegistry, generatedIfPresent, remoteIfDebug]`
  - [ ] `auto` mode in release: `[memory, starterRegistry, generatedIfPresent]` — NO remote
  - [ ] `offline` mode: `[memory, generatedIfPresent, starterRegistry]` — NO remote ever
  - [ ] `generated` mode: `[generatedIfPresent]` — strict, fails loudly if generated not present
  - [ ] `remoteAllowed` mode: same as auto but remote allowed in all build modes
- [ ] `[AGENT]` Write unit tests for provider chain builder

---

## 2.6 — IconifyApp Widget

- [ ] `[AGENT]` Create `lib/src/widget/iconify_app.dart`
  - [ ] `class IconifyApp extends StatefulWidget`
  - [ ] Constructor: `child` (required), `config` (optional, defaults to `IconifyConfig.defaults()`)
  - [ ] Initializes provider chain based on config + detected build mode
  - [ ] Provides `IconifyScope` to widget tree
  - [ ] Exposes `IconifyApp.configure(mode: ...)` static convenience method
  - [ ] Dartdoc: show before/after upgrade example (from auto to generated mode)
- [ ] `[AGENT]` Write widget tests for `IconifyApp`
  - [ ] Children can access `IconifyScope.of(context)`
  - [ ] Default config uses auto mode
  - [ ] Dispose cleans up provider chain

---

## 2.7 — Rendering Layer

### 2.7.1 — Render Strategy

- [ ] `[AGENT]` Create `lib/src/render/render_strategy.dart`
  ```dart
  enum RenderStrategy { svgDirect, rasterized, auto }
  ```

### 2.7.2 — Impeller Detection

- [ ] `[AGENT]` Create `lib/src/render/impeller_detector.dart`
  - [ ] Detects whether Impeller is the active renderer at runtime
  - [ ] Uses `FlutterView` + `PlatformDispatcher` to infer renderer where possible
  - [ ] Fallback: assume Impeller on iOS (safe assumption post Flutter 3.10)
  - [ ] `isImpellerActive` static getter with caching

### 2.7.3 — SVG Renderer Widget

- [ ] `[AGENT]` Create `lib/src/render/iconify_svg_renderer.dart`
  - [ ] Receives `IconifyIconData`, `size`, `color?`, `renderStrategy`
  - [ ] `svgDirect` path: `SvgPicture.string()` via flutter_svg
  - [ ] `rasterized` path: renders SVG to `ui.Image`, returns as `RawImage`
    - [ ] Cache rasterized results by `(iconName, color, size, devicePixelRatio)`
    - [ ] Uses `compute()` isolate for large batches
  - [ ] `auto` path: uses `svgDirect` by default; falls back to `rasterized` when color override is requested AND Impeller is active
  - [ ] `🔴 CRITICAL` — test color override with Impeller on a real iOS device before merging

---

## 2.8 — IconifyIcon Widget

- [ ] `[AGENT]` Create `lib/src/widget/iconify_icon.dart`
  - [ ] `class IconifyIcon extends StatefulWidget`
  - [ ] Primary constructor: `IconifyIcon(String identifier)` — parses `prefix:name`
  - [ ] Named constructor: `IconifyIcon.name(IconifyName name)`
  - [ ] Parameters: `size`, `color`, `renderStrategy`, `errorBuilder`, `loadingBuilder`, `semanticLabel`
  - [ ] State: `FutureBuilder`-based icon resolution from nearest `IconifyScope`
  - [ ] Loading state: configurable `loadingBuilder` or default shimmer
  - [ ] Error state: configurable `errorBuilder` with `IconifyException` context
  - [ ] Uses `IconifyScope.of(context).getIcon(name)`
  - [ ] Does not rebuild if icon identity and size are the same
  - [ ] `const`-constructable when all params are const
- [ ] `[AGENT]` Write widget tests
  - [ ] Renders with valid icon in memory provider
  - [ ] Shows loading widget while future is pending
  - [ ] Shows error widget on `IconNotFoundException`
  - [ ] `IconifyIcon.name()` constructor works

---

## 2.9 — Error Messages & Dev Hints

- [ ] `[AGENT]` Create `lib/src/widget/iconify_error_widget.dart`
  - [ ] Default error widget: colored box with icon glyph + tooltip
  - [ ] In debug mode: prints actionable error to console
  - [ ] Error messages per exception type (see Phase 1 error hierarchy)
- [ ] `[AGENT]` Create `lib/src/config/dev_hints.dart`
  - [ ] In debug mode, after N remote fetches: print once "Run `dart run iconify_sdk_cli generate` to bundle locally"
  - [ ] Threshold: 10 remote fetches (configurable)
  - [ ] Uses `debugPrint` — never in release builds
  - [ ] Tracks per-session, not per-widget

---

## 2.10 — Barrel Export

- [ ] `[AGENT]` Create `lib/iconify_sdk.dart`
  - [ ] Re-exports core public API
  - [ ] Exports: `IconifyIcon`, `IconifyApp`, `IconifyMode`, `IconifyConfig`, `IconifyScope`
  - [ ] Exports: `FlutterAssetBundleIconifyProvider`, `RenderStrategy`

---

## 2.11 — Integration Tests & Golden Tests

- [ ] `[AGENT]` Create `test/widget/iconify_icon_test.dart` — standard widget tests
- [ ] `[AGENT]` Create `test/golden/` directory
  - [ ] `golden_monochrome_default.dart` — monochrome icon, no color
  - [ ] `golden_monochrome_colored.dart` — monochrome icon + color override
  - [ ] `golden_multicolor.dart` — multicolor icon
  - [ ] `golden_error_state.dart` — error widget appearance
  - [ ] `golden_loading_state.dart` — loading widget appearance
- [ ] `[HUMAN]` 🔴 Run golden tests on physical iOS device with Impeller enabled
- [ ] `[HUMAN]` 🔴 Verify `color:` parameter renders correctly with Impeller (check for colorFilter bug)
- [ ] `[HUMAN]` Run golden tests on Android device with `--enable-impeller`
- [ ] `[HUMAN]` Run golden tests on Flutter web (CanvasKit renderer)
- [ ] `[HUMAN]` Run golden tests on Flutter web (HTML renderer) — note any SVG feature differences

---

## 2.12 — Phase 2 Exit Gate

- [ ] `flutter analyze` — zero issues
- [ ] `flutter test` — all tests pass
- [ ] Golden tests approved (all renderers + Impeller)
- [ ] `dart pub publish --dry-run` — clean
- [ ] `IconifyIcon('mdi:home')` works with zero configuration in debug mode
- [ ] Release build makes zero network calls (verify with network traffic monitor)
- [ ] Starter registry under 200KB in assets
- [ ] No `TODO`/`FIXME` in `lib/`

---

---

# Phase 3 — build_runner Builder (`iconify_sdk_builder`)

> **Goal:** `dart run build_runner build` watches source files, finds `IconifyIcon('mdi:home')` patterns, and generates a type-safe `icons.g.dart` with only those icons.  
> **Exit Criteria:** Generated file correct, incremental builds fast, integrates with existing `build_runner` workflows.

---

## 3.1 — Package Scaffolding

- [ ] `[AGENT]` Create `packages/iconify_sdk_builder/pubspec.yaml`
  - [ ] Dependencies: `iconify_sdk_core`, `build: ^2.4.0`, `source_gen: ^1.5.0`
  - [ ] No Flutter dependency
  - [ ] Dev: `build_test: ^2.2.0`, `test: ^1.25.0`

---

## 3.2 — Config Reader

- [ ] `[AGENT]` Create `lib/src/config/iconify_build_config.dart`
  - [ ] Reads `iconify.yaml` from project root
  - [ ] Parses `sets:`, `output:`, `data_dir:`, `mode:` fields
  - [ ] Returns typed `IconifyBuildConfig` model
  - [ ] Validates: `data_dir` exists, `output` path is writeable
- [ ] `[AGENT]` Write tests for config reader with fixture `iconify.yaml` files

---

## 3.3 — Source Scanner

- [ ] `[AGENT]` Create `lib/src/scanner/icon_name_scanner.dart`
  - [ ] Scans Dart source for `IconifyIcon('...')` and `IconifyIcon.name(...)` patterns
  - [ ] Returns `Set<String>` of raw identifier strings found
  - [ ] Uses regex + AST approach (prefer analyzer-based scanning over pure regex)
  - [ ] **Documents known limitations clearly in dartdoc:**
    - Does NOT detect icons assigned to variables before passing
    - Does NOT detect icons in string interpolation
    - Does NOT detect dynamically constructed icon names
    - Does NOT scan non-Dart files
  - [ ] Provides `--verbose` mode that lists all found icon names with their source locations
- [ ] `[AGENT]` Write scanner tests with fixture Dart files
  - [ ] Detects inline `IconifyIcon('mdi:home')`
  - [ ] Detects `const` string usage
  - [ ] Does not false-positive on unrelated strings
  - [ ] Reports source location of each found icon

---

## 3.4 — Code Generator

- [ ] `[AGENT]` Create `lib/src/generator/icon_code_generator.dart`
  - [ ] Takes `Set<IconifyName>` and `Map<IconifyName, IconifyIconData>` as input
  - [ ] Generates `icons.g.dart` with:
    - [ ] `const` `IconifyIconData` constants per icon
    - [ ] `class Icons{Prefix}` namespace classes per collection
    - [ ] `MemoryIconifyProvider` pre-population method
    - [ ] License comment block at top of file
  - [ ] Output is `dart format`-clean
  - [ ] Generated file has `// GENERATED CODE - DO NOT MODIFY BY HAND` header
- [ ] `[AGENT]` Write generator tests
  - [ ] Output is valid Dart syntax
  - [ ] Constants have correct body content
  - [ ] License block is present

---

## 3.5 — Builder Implementation

- [ ] `[AGENT]` Create `lib/src/builder/iconify_builder.dart`
  - [ ] Implements `build` package `Builder` interface
  - [ ] Input: all `.dart` files in the project
  - [ ] Output: single `icons.g.dart` at configured output path
  - [ ] Calls: scanner → loads icon data from local snapshots → generator → writes file
  - [ ] `build_extensions`: `{'.dart': ['.iconify.g.dart']}` or global output
  - [ ] Incremental: only re-generates when icon set changes
- [ ] `[AGENT]` Create `build.yaml` for the package
  - [ ] Registers builder under `iconify_sdk_builder|iconify`
  - [ ] Sets default `runs_before` / `runs_after` relative to `json_serializable`
- [ ] `[AGENT]` Create `lib/builder.dart` — entry point for `build.yaml`
- [ ] `[AGENT]` Write builder tests using `build_test` test utilities
  - [ ] Builder produces output for a project with `IconifyIcon` usages
  - [ ] Builder produces empty output for project with no usages
  - [ ] Builder handles invalid icon names gracefully (warning, not error)

---

## 3.6 — Integration Test

- [ ] `[AGENT]` Create `test/integration/` with a minimal fake Flutter project
  - [ ] `lib/main.dart` with a few `IconifyIcon('mdi:home')` calls
  - [ ] `iconify.yaml` pointing to local fixture data
  - [ ] Run `dart run build_runner build` and verify `icons.g.dart` generated correctly
- [ ] `[HUMAN]` Run integration test end-to-end manually

---

## 3.7 — Phase 3 Exit Gate

- [ ] `dart analyze` — zero issues
- [ ] `dart test` — all tests pass
- [ ] `dart run build_runner build` generates correct `icons.g.dart` for test project
- [ ] Generated file compiles cleanly
- [ ] `dart pub publish --dry-run` — clean
- [ ] Scanner limitations documented in `README.md`

---

---

# Phase 4 — CLI (`iconify_sdk_cli`)

> **Goal:** A developer can go from zero to fully offline, deterministic, production-ready icon set in a few commands.  
> **Exit Criteria:** All 6 commands work end-to-end. App using generated mode runs offline with no network calls.

---

## 4.1 — Package Scaffolding

- [ ] `[AGENT]` Create `packages/iconify_sdk_cli/pubspec.yaml`
  - [ ] Dependencies: `iconify_sdk_core`, `args: ^2.5.0`, `yaml: ^3.1.0`, `http: ^1.2.0`, `path: ^1.9.0`, `archive: ^3.6.0`
  - [ ] No Flutter dependency
  - [ ] Executable: `dart run iconify_sdk_cli`
- [ ] `[AGENT]` Create `bin/iconify_sdk_cli.dart` — main entry point
- [ ] `[AGENT]` Create command structure: `lib/src/commands/`

---

## 4.2 — CLI Framework

- [ ] `[AGENT]` Create `lib/src/cli_runner.dart`
  - [ ] Uses `package:args` `CommandRunner`
  - [ ] Global flags: `--verbose`, `--config` (path to custom `iconify.yaml`)
  - [ ] Subcommands: `init`, `sync`, `generate`, `doctor`, `diff`, `licenses`
  - [ ] Unified error handling: catches `IconifyException` subtypes, prints actionable messages, exits non-zero
- [ ] `[AGENT]` Create `lib/src/config/cli_config_loader.dart`
  - [ ] Finds and parses `iconify.yaml` from cwd upward
  - [ ] Validates against schema v1
  - [ ] Reports missing required fields with line numbers

---

## 4.3 — `init` Command

- [ ] `[AGENT]` Create `lib/src/commands/init_command.dart`
  - [ ] Interactive prompts: which collections to start with, output path, data directory
  - [ ] Generates `iconify.yaml` with sensible defaults
  - [ ] Creates `data/iconify/` directory
  - [ ] Adds `*.g.dart` to `.gitignore` (with confirmation)
  - [ ] Adds `data/iconify/` to `.gitignore` exclusion (data should be committed — with explanation)
  - [ ] Prints next steps on success
- [ ] `[AGENT]` Write tests for init command output
  - [ ] Generated `iconify.yaml` is valid against schema
  - [ ] Does not overwrite existing `iconify.yaml` without `--force`

---

## 4.4 — `sync` Command

> **Data source: GitHub raw JSON — NOT the Iconify API**

- [ ] `[AGENT]` Create `lib/src/commands/sync_command.dart`
  - [ ] Reads `sets:` from `iconify.yaml` to determine which prefixes to download
  - [ ] Downloads `{prefix}.json` from `https://raw.githubusercontent.com/iconify/icon-sets/master/json/{prefix}.json`
  - [ ] Saves to `data_dir/{prefix}.json`
  - [ ] Validates downloaded JSON with `IconifyJsonParser`
  - [ ] `--pin` flag: records exact git commit SHA of `iconify/icon-sets` at download time in a `iconify.lock` file
  - [ ] `--prefix` flag: sync specific collection only
  - [ ] Shows progress: `Syncing mdi... 7446 icons. Done.`
  - [ ] Skips unchanged files (compares ETag or file hash)
  - [ ] `--force` flag: re-downloads even if unchanged
- [ ] `[AGENT]` Create `lib/src/sync/github_icon_set_downloader.dart`
  - [ ] Handles HTTP errors gracefully
  - [ ] Retries on transient failures (up to 3 attempts)
  - [ ] Reports collection name, icon count, license on success
- [ ] `[AGENT]` Write tests for sync with mocked HTTP client
  - [ ] Downloads and saves correctly
  - [ ] Validates JSON after download
  - [ ] Skips unchanged (mock ETag behavior)
  - [ ] Writes correct lock file entry

---

## 4.5 — `generate` Command

- [ ] `[AGENT]` Create `lib/src/commands/generate_command.dart`
  - [ ] Scans source files using the same scanner as `iconify_sdk_builder`
  - [ ] Loads icon data from local `data_dir/` snapshots
  - [ ] Calls code generator to produce `icons.g.dart`
  - [ ] Reports: N icons bundled, N aliases resolved, collections used, total size
  - [ ] `--dry-run` flag: shows what would be generated without writing
  - [ ] `--output` flag: override output path from `iconify.yaml`
  - [ ] Fails with clear error if a scanned icon name is not found in local data (not silently omitted)
  - [ ] `--missing=warn` flag: downgrade failure to warning (for gradual migration)
- [ ] `[AGENT]` Write tests for generate command
  - [ ] Generates correct output from fixture data
  - [ ] Reports correct counts
  - [ ] `--dry-run` produces no file changes
  - [ ] Fails correctly on missing icon

---

## 4.6 — `doctor` Command

- [ ] `[AGENT]` Create `lib/src/commands/doctor_command.dart`
  - [ ] Checks: `iconify.yaml` exists and is valid
  - [ ] Checks: local data snapshots exist for all configured collections
  - [ ] Checks: local data is not stale (compares against `iconify.lock`)
  - [ ] Checks: generated file exists and is up-to-date (hash of inputs vs output)
  - [ ] Checks: all icons scanned from source are present in local data
  - [ ] Checks: attribution-required collections — warns with details
  - [ ] Checks: collections with restrictive licenses in use — warns
  - [ ] Outputs: `✅` / `⚠️` / `❌` per check with actionable fix instructions
  - [ ] Exit code: 0 if all green, 1 if any warnings, 2 if any errors
- [ ] `[AGENT]` Write tests for doctor output with various fixture states

---

## 4.7 — `diff` Command

- [ ] `[AGENT]` Create `lib/src/commands/diff_command.dart`
  - [ ] Compares local snapshot vs latest upstream (fetches metadata only, not full JSON)
  - [ ] Reports: new icons added, icons removed, icons modified, version change
  - [ ] `--prefix` flag: diff specific collection
  - [ ] `--all` flag: diff all configured collections
  - [ ] Does NOT auto-apply changes — output only
- [ ] `[AGENT]` Write tests for diff with mocked upstream responses

---

## 4.8 — `licenses` Command

- [ ] `[AGENT]` Create `lib/src/commands/licenses_command.dart`
  - [ ] Lists all collections in use + their license info
  - [ ] Groups by: ✅ permissive, ⚠️ attribution required, 🔴 restrictive
  - [ ] `--format=json` flag: machine-readable output for CI integration
  - [ ] `--format=markdown` flag: generates `ICON_LICENSES.md` for inclusion in app repo
  - [ ] `--fail-on-attribution` flag: exits non-zero if any attribution-required collections are in use (for strict CI)
- [ ] `[AGENT]` Write tests for license output formatting

---

## 4.9 — `search` Command (Bonus, if time allows)

- [ ] `[AGENT]` Create `lib/src/commands/search_command.dart`
  - [ ] Searches icon names in local synced data
  - [ ] `iconify_sdk_cli search home` — lists matching icons across all synced collections
  - [ ] `--collection mdi` flag: restrict to one collection
  - [ ] `--limit N` flag: max results
  - [ ] Does NOT require network — local data only

---

## 4.10 — End-to-End Integration Test

- [ ] `[AGENT]` Create `test/integration/` with a complete fake Flutter project:
  - `lib/main.dart` using `IconifyIcon('mdi:home')`, `IconifyIcon('lucide:settings')`, `IconifyIcon('tabler:star')`
  - Empty `iconify.yaml`
- [ ] `[HUMAN]` Run through complete workflow manually:
  ```bash
  dart run iconify_sdk_cli init
  dart run iconify_sdk_cli sync --collections mdi,lucide,tabler
  dart run iconify_sdk_cli doctor
  dart run iconify_sdk_cli generate
  dart run iconify_sdk_cli licenses
  dart run iconify_sdk_cli diff
  ```
- [ ] Verify `icons.g.dart` is generated with correct icons
- [ ] Verify `ICON_LICENSES.md` is generated
- [ ] Verify `doctor` passes all checks after full workflow

---

## 4.11 — Phase 4 Exit Gate

- [ ] All 6 commands work end-to-end
- [ ] `dart analyze` — zero issues
- [ ] `dart test` — all tests pass
- [ ] End-to-end integration test passes
- [ ] `dart pub publish --dry-run` — clean
- [ ] Sync command uses GitHub raw source exclusively (confirmed by test mock URLs)
- [ ] `doctor` command correctly warns on attribution-required collections

---

---

# Phase 5 — Correctness Hardening

> **Goal:** No regressions, no surprises on real devices, no legal landmines.  
> **Exit Criteria:** All golden tests approved on real devices. All fuzz inputs handled. Performance baseline established.

---

## 5.1 — Impeller Golden Tests

- [ ] `[AGENT]` Set up golden test matrix in `iconify_sdk`:
  - [ ] `test/golden/impeller/ios/` — iOS Impeller renderer
  - [ ] `test/golden/impeller/android/` — Android Impeller renderer
  - [ ] `test/golden/skia/` — Skia renderer (reference)
- [ ] `[HUMAN]` 🔴 Run golden tests on **physical iOS device** (Impeller default since Flutter 3.10)
  - [ ] Monochrome icon, no color override — must match Skia baseline
  - [ ] Monochrome icon + color override — verify colorFilter renders correctly
  - [ ] Stroke icon + color — verify stroke color applies correctly
  - [ ] Multicolor icon — verify no color corruption
- [ ] `[HUMAN]` 🔴 Run golden tests on **physical Android device** with `--enable-impeller`
  - [ ] Same four tests as iOS
- [ ] `[AGENT]` If Impeller colorFilter bug is hit: implement rasterized fallback path (see ADR-004) and re-test
- [ ] `[HUMAN]` Approve all golden baselines and commit them

---

## 5.2 — Flutter Web Tests

- [ ] `[HUMAN]` Run golden tests in Chrome with CanvasKit renderer
  - [ ] All icon types render correctly
- [ ] `[HUMAN]` Run golden tests in Chrome with HTML renderer
  - [ ] Note any SVG features that degrade
- [ ] `[AGENT]` Document HTML renderer limitations in `docs/platform-notes.md`
- [ ] `[AGENT]` Add `// HTML renderer note` comments in `IconifyIcon` for features with limited web support

---

## 5.3 — Malformed Input Fuzz Testing

- [ ] `[AGENT]` Create `test/fuzz/` directory
- [ ] `[AGENT]` Write `test/fuzz/parser_fuzz_test.dart`
  - [ ] Feed 20+ malformed JSON variants to `IconifyJsonParser`
  - [ ] All must throw `IconifyParseException` — never unhandled exceptions, never crashes
  - [ ] Variants: empty string, null values, wrong types, missing required fields, deeply nested, circular references
- [ ] `[AGENT]` Write `test/fuzz/name_fuzz_test.dart`
  - [ ] Feed 50+ invalid name strings to `IconifyName.parse`
  - [ ] All must throw `InvalidIconNameException`
  - [ ] Variants: empty, whitespace, unicode, emoji, very long strings, SQL injection patterns, path traversal patterns

---

## 5.4 — Alias Chain Edge Cases

- [ ] `[AGENT]` Verify alias chain handling for all documented edge cases:
  - [ ] Chain depth 1 through 9
  - [ ] Chain depth exactly at `maxChainDepth`
  - [ ] Two-node cycle
  - [ ] Three-node cycle
  - [ ] Alias with all override fields set
  - [ ] Alias with no override fields
  - [ ] Alias pointing to non-existent parent
  - [ ] Collection with 0 aliases
  - [ ] Collection with 1000+ aliases (performance check)

---

## 5.5 — Performance Baseline

- [ ] `[AGENT]` Create `test/performance/` benchmarks
  - [ ] `IconifyName.parse` — 100k iterations, must be < 5ms total
  - [ ] `LruIconifyCache.get` — 100k iterations with 500-entry cache, must be < 20ms total
  - [ ] `IconifyJsonParser.parseCollectionString` — MDI full collection, must be < 500ms
  - [ ] `AliasResolver.resolve` — 10k alias chains depth-5, must be < 100ms total
- [ ] `[HUMAN]` Run benchmarks and record baseline in `docs/performance-baseline.md`
- [ ] `[AGENT]` Add benchmark to CI as a non-blocking check (reports but does not fail)

---

## 5.6 — License Audit

- [ ] `[HUMAN]` Run `dart run iconify_sdk_cli licenses` against the starter registry
- [ ] `[HUMAN]` Verify every bundled starter icon set is in the "safe for commercial use" list
- [ ] `[HUMAN]` Verify attribution-required collections are NOT in the starter registry
- [ ] `[AGENT]` Add CI check: `dart run iconify_sdk_cli licenses --fail-on-attribution` against starter registry — must pass

---

## 5.7 — Phase 5 Exit Gate

- [ ] All Impeller golden tests approved on real iOS and Android devices
- [ ] No regressions vs Skia renderer
- [ ] Fuzz tests — zero unhandled exceptions
- [ ] Alias chain edge cases — all handled correctly
- [ ] Performance baseline documented
- [ ] License audit passed — zero attribution-required icons in starter registry

---

---

# Phase 6 — v1 Launch

> **Goal:** Someone can adopt this in production without reading the source code.  
> **Exit Criteria:** All packages published to pub.dev. Docs site live. At least one real-world usage example.

---

## 6.1 — Documentation

- [ ] `[HUMAN]` + `[AGENT]` Write `packages/core/README.md`
  - [ ] What it is, what it does, what it does NOT do
  - [ ] Quick-start code example
  - [ ] All public classes with brief descriptions
  - [ ] Link to full docs site
- [ ] `[HUMAN]` + `[AGENT]` Write `packages/iconify_sdk/README.md`
  - [ ] One-liner usage prominently at the top
  - [ ] The 4 modes explained with examples
  - [ ] Production optimization path (step 1 → step 5)
  - [ ] Impeller note — what works, what doesn't
  - [ ] Platform support matrix
- [ ] `[HUMAN]` + `[AGENT]` Write `packages/iconify_sdk_builder/README.md`
  - [ ] How to add to `dev_dependencies`
  - [ ] `build.yaml` configuration
  - [ ] What the generated code looks like
  - [ ] Known scanner limitations
- [ ] `[HUMAN]` + `[AGENT]` Write `packages/iconify_sdk_cli/README.md`
  - [ ] All 6 commands with examples
  - [ ] Complete workflow walkthrough
  - [ ] `iconify.yaml` reference
- [ ] `[AGENT]` Write `docs/guides/safe-collections.md` — the curated permissive license list
- [ ] `[AGENT]` Write `docs/guides/custom-sets.md` — how to add proprietary icons
- [ ] `[AGENT]` Write `docs/guides/migration-from-iconify-flutter.md` — migrating from the archived package

---

## 6.2 — Example Gallery

- [ ] `[AGENT]` Create `examples/basic/` — `IconifyIcon('mdi:home')`, zero config
- [ ] `[AGENT]` Create `examples/bundled/` — fully offline with generated mode
- [ ] `[AGENT]` Create `examples/design_system/` — shared icon package pattern for teams
- [ ] `[AGENT]` Create `examples/icon_picker/` — searchable icon picker using starter registry
- [ ] `[HUMAN]` Test all examples on iOS, Android, and Flutter web

---

## 6.3 — CHANGELOG & Versioning

- [ ] `[AGENT]` Write `CHANGELOG.md` for each package following Keep a Changelog format
- [ ] `[HUMAN]` Set version `0.1.0` for all packages (intentional: not v1.0.0 yet — gathering real-world feedback first)
- [ ] `[AGENT]` Tag `v0.1.0` in git
- [ ] `[HUMAN]` Set version `1.0.0` after real-world feedback period (Phase 7)

---

## 6.4 — Pub.dev Publishing

- [ ] `[HUMAN]` Run `dart pub publish --dry-run` for all four packages — all must pass
- [ ] `[HUMAN]` Verify all packages have `pubspec.yaml` fields: `description`, `repository`, `issue_tracker`, `documentation`
- [ ] `[HUMAN]` Publish `iconify_sdk_core` first
- [ ] `[HUMAN]` Publish `iconify_sdk` after core is live
- [ ] `[HUMAN]` Publish `iconify_sdk_builder`
- [ ] `[HUMAN]` Publish `iconify_sdk_cli`
- [ ] `[HUMAN]` Verify all four packages appear correctly on pub.dev

---

## 6.5 — Community & Announcement

- [ ] `[HUMAN]` Post on r/FlutterDev
- [ ] `[HUMAN]` Post on Flutter Discord
- [ ] `[HUMAN]` Comment on the original Iconify GitHub issue #336 (the one requesting an official Flutter package)
- [ ] `[HUMAN]` Create GitHub Discussions for: feedback, feature requests, collection requests
- [ ] `[HUMAN]` Set up issue templates: bug report, feature request, collection request

---

## 6.6 — Phase 6 Exit Gate

- [ ] All 4 packages published on pub.dev
- [ ] All READMEs complete and accurate
- [ ] All examples run on iOS + Android + Web
- [ ] GitHub Discussions open
- [ ] Issue templates in place

---

---

# Phase 7 — Post-v1 Moat

> **Goal:** Community grows, alternatives become less appealing, moat widens.  
> Ongoing — no fixed timeline. Prioritize based on community feedback.

---

## 7.1 — Debug Tooling

- [ ] `[AGENT]` `IconifyDiagnostics.instance` — exposes runtime stats
  - [ ] Cache hit rate
  - [ ] Remote fetch count
  - [ ] Unresolved icon names
  - [ ] Top collections by usage
- [ ] `[AGENT]` Debug overlay widget: shows per-icon cache status on hover
- [ ] `[AGENT]` Flutter DevTools extension: icon inspector panel

---

## 7.2 — VS Code Extension

- [ ] `[HUMAN]` Research VS Code extension API for SVG preview on hover
- [ ] `[AGENT]` Build `iconify-flutter-intellisense` VS Code extension
  - [ ] Show SVG preview when hovering over `'mdi:home'` string in Dart code
  - [ ] Autocomplete icon names from local snapshot data
  - [ ] Jump to icon definition in upstream source
- [ ] `[HUMAN]` Publish to VS Code Marketplace

---

## 7.3 — Binary Registry Format

- [ ] `[AGENT]` Design compact binary format for icon data (smaller than JSON, faster to parse)
- [ ] `[AGENT]` `iconify_sdk_cli generate --format=binary` — generates `.bin` registry instead of Dart source
- [ ] `[AGENT]` Binary provider in core that reads `.bin` format
- [ ] Benchmark: binary vs JSON parse time at startup

---

## 7.4 — Design Tool Bridge

- [ ] `[HUMAN]` Research Figma plugin API for reading Iconify plugin selections
- [ ] `[AGENT]` Build Figma → `iconify.yaml` export: export used icon names from a Figma file
- [ ] `[AGENT]` CLI command: `iconify_sdk_cli import-figma --token={figma_token} --file={file_id}`

---

## 7.5 — Icon Picker Component

- [ ] `[AGENT]` `IconifyIconPicker` widget
  - [ ] Searchable, paginated grid
  - [ ] Filters by collection, license, style (outline/filled)
  - [ ] Works with starter registry offline
  - [ ] Callback: `onSelected(IconifyName name)`
- [ ] Ship as optional `iconify_sdk_picker` package

---

## 7.6 — Custom Set Tooling

- [ ] `[AGENT]` `iconify_sdk_cli import-svg --dir=assets/icons/ --prefix=brand`
  - [ ] Converts a directory of SVG files into an `iconify.yaml`-compatible JSON collection
  - [ ] Normalizes SVG paths to Iconify format
  - [ ] Reports `currentColor` detection result per icon

---

## 7.7 — v1.0.0 Stable

- [ ] `[HUMAN]` Gather 4+ weeks of real-world production feedback
- [ ] `[HUMAN]` Fix all P0 and P1 bugs from community feedback
- [ ] `[HUMAN]` Conduct API stability review — anything changing before 1.0 must change now
- [ ] `[HUMAN]` Tag and publish `v1.0.0` for all four packages
- [ ] `[HUMAN]` Write v1.0.0 announcement post

---

---

## Dependency Matrix

| Package | Depends On | Used By |
|---|---|---|
| `iconify_sdk_core` | `http`, `meta` | Everyone |
| `iconify_sdk` | `core`, `flutter_svg`, Flutter SDK | App developers |
| `iconify_sdk_builder` | `core`, `build`, `source_gen` | App dev dependencies |
| `iconify_sdk_cli` | `core`, `args`, `yaml`, `path` | App dev dependencies |

---

## Risk Register

| Risk | Severity | Mitigation |
|---|---|---|
| flutter_svg Impeller colorFilter bug not fixed | 🔴 HIGH | Rasterized fallback path (ADR-004). Test on real device in Phase 2. |
| Iconify changes their JSON format | 🟡 MEDIUM | Parser is isolated. Schema version in normalized model. |
| flutter_svg abandonment (original author passed) | 🟡 MEDIUM | Community fork being maintained. Track in governance docs. Re-evaluate at v1.0. |
| GitHub raw URL structure changes | 🟠 LOW | Pin to specific commit SHA via iconify.lock. Self-host mirror as fallback. |
| Pub.dev name squatting (original archived names) | 🟡 MEDIUM | Reserve all 4 names in Phase 0.1 before any public announcement. |
| License violation by package users | 🟠 LOW | `doctor` command + `licenses` command + docs. Cannot fully prevent, can warn loudly. |
| Build time regression from builder | 🟠 LOW | Builder only runs on change. Incremental. Benchmark in Phase 3. |

---

## Quick Reference — Commands After Full Setup

```bash
# Initial setup
dart run iconify_sdk_cli init

# Download icon data from GitHub (not the API)
dart run iconify_sdk_cli sync --collections mdi,lucide,tabler,heroicons

# Health check
dart run iconify_sdk_cli doctor

# Generate typed Dart constants
dart run build_runner build  # via build_runner builder
# OR
dart run iconify_sdk_cli generate  # via CLI directly

# Check what changed upstream
dart run iconify_sdk_cli diff

# Export license report
dart run iconify_sdk_cli licenses --format=markdown > ICON_LICENSES.md
```