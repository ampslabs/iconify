# iconify_sdk — v2 Roadmap

> Version: 2.0 | Starts after: v1 shipped (all Phase 0–6 complete)
> Focus: Performance · Security · Bundle Size · Ecosystem Expansion · Developer Experience
> Packages: `iconify_sdk_core` · `iconify_sdk` · `iconify_sdk_builder` · `iconify_sdk_cli`

---

## Reading Guide
- `[AGENT]` = Tasks Gemini CLI / Claude Code can perform.
- `[HUMAN]` = Requires manual action (device testing, publishing, legal review).
- `[CI]` = Automated pipeline.
- `🔴 CRITICAL` = Blocking risk or security issue — do not defer.
- `🟡 HIGH` = Major impact, prioritise early in the phase.
- `🟢 NICE` = Good to have, schedule when capacity allows.

---

## Phase Overview

| Phase | Name | Primary Goal | Estimated Duration |
|---|---|---|---|
| A | Living Cache | Eliminate starter assets from production bundle | 2–3 weeks |
| B | Security Hardening | SVG sanitization, supply chain integrity | 3–4 weeks |
| C | Performance | Binary format, lazy parsing, parallel loading | 3–4 weeks |
| D | Bundle Intelligence | Deep pruning, compression, font fallback | 2–3 weeks |
| E | Ecosystem Expansion | New icon sets, Figma bridge, custom SVG import | 3–4 weeks |
| F | Developer Experience | VS Code extension, debug overlay, watch mode | 4–5 weeks |
| G | v2 Launch | Docs, migration guide, pub.dev v2 publish | 2 weeks |

---

---

# Phase A — Living Cache

> **Goal:** The production app bundle contains exactly the icons the app uses. Nothing else. The starter assets currently bundled as Flutter package assets are eliminated from production entirely.
>
> **Problem being solved:** Flutter package assets are never tree-shaken. Every app currently ships the full 200KB starter registry regardless of which icons it uses. An app using only `mdi:home` and `lucide:settings` still pays for 550+ icons.
>
> **Exit Criteria:** A production Flutter app using 10 icons ships only those 10 icon bodies. `flutter build --analyze-size` confirms zero starter asset footprint.

---

## A.1 — Remove Starter Assets from Flutter Asset Registration

- [ ] `[AGENT]` Remove starter JSON files from `pubspec.yaml` assets declaration in `iconify_sdk`
  - [ ] Starter files stay on disk inside the package's pub cache directory — they are now a dev-only file system resource, not a Flutter asset
  - [ ] `AssetBundleIconifyProvider` for starter is replaced with `FileSystemIconifyProvider` pointed at resolved pub cache path
- [ ] `[AGENT]` Implement `PubCachePathResolver` in `iconify_sdk_core`
  - [ ] Resolves absolute path to `iconify_sdk` package inside the current project's `.dart_tool/package_config.json`
  - [ ] Returns `null` on Flutter web (web dev falls through to remote)
  - [ ] Cached after first resolution — no repeated file reads
- [ ] `[AGENT]` Update `ProviderChainBuilder` dev chain to use `FileSystemIconifyProvider(root: resolvedStarterPath)` at L3
- [ ] `[AGENT]` Verify `flutter build apk --release` no longer includes any `assets/iconify/starter/` files in the APK
- [ ] `[HUMAN]` Confirm APK size reduction using `flutter build apk --analyze-size`

---

## A.2 — Living Cache File (`used_icons.json`)

- [ ] `[AGENT]` Design `used_icons.json` schema
  - [ ] Top-level: `{ "schemaVersion": 1, "generated": "<ISO timestamp>", "icons": { "<prefix:name>": { ...IconifyIconData } } }`
  - [ ] One flat map — no per-collection nesting (simplifies read/write)
  - [ ] Includes `source` field per icon: `"starter"` | `"remote"` | `"synced"` | `"custom"` (for diagnostics)
- [ ] `[AGENT]` Implement `LivingCacheProvider` in `iconify_sdk_core`
  - [ ] Reads from `assets/iconify/used_icons.json` in the project root (not pub cache)
  - [ ] In Flutter context: reads via `rootBundle` (it IS a registered Flutter asset — the only one)
  - [ ] In CLI context: reads via `dart:io`
  - [ ] On first use, if file does not exist: creates it with empty icons map
  - [ ] Thread-safe write: debounce 500ms, batch concurrent writes into one file write
  - [ ] `addIcon(IconifyName, IconifyIconData)` — appends to in-memory map + schedules flush
  - [ ] `flush()` — writes current map to disk atomically (write to `.tmp`, then rename)
- [ ] `[AGENT]` Register `assets/iconify/used_icons.json` in `iconify_sdk/pubspec.yaml` assets block
  - [ ] Add a default empty `used_icons.json` to the package's `lib/assets/` so it exists at project init
  - [ ] `iconify init` copies this file into the user's `assets/iconify/` directory
- [ ] `[AGENT]` Update `ProviderChainBuilder` dev chain to slot `LivingCacheProvider` at L2
  - [ ] Dev chain (after this change): `[GeneratedIcons(L1), LivingCache(L2), StarterFS(L3), Remote(L4)]`
  - [ ] Prod chain: `[GeneratedIcons(L1), LivingCache(L2)]` — starter and remote completely absent

---

## A.3 — Write-Back from Remote

- [ ] `[AGENT]` Update `RemoteIconifyProvider` to accept optional `LivingCacheProvider` dependency
  - [ ] On successful fetch: calls `livingCache.addIcon(name, data)` before returning data
  - [ ] This makes remote self-eliminating: first request goes to network, every subsequent request (even across hot reloads and fresh `flutter run`) is served from `used_icons.json`
  - [ ] `writeBackEnabled` flag — default `true` in dev, `false` in release (no-op in release since remote is blocked)
- [ ] `[AGENT]` Add dev console hint on first remote fetch:
  - [ ] `[iconify] 'mdi:home' fetched remotely → written to assets/iconify/used_icons.json`
  - [ ] After 10 unique collections fetched remotely: `[iconify] 10 collections auto-cached. Run iconify sync to pin versions.`
  - [ ] Uses `debugPrint` — stripped in release builds

---

## A.4 — Prune Pass

> Removes icons from `used_icons.json` that no longer appear in source. Keeps the file lean as the app evolves.

- [ ] `[AGENT]` Implement `iconify prune` CLI command in `iconify_sdk_cli`
  - [ ] Scans all Dart source files for `IconifyIcon('...')` usage (reuses `IconNameScanner` from builder)
  - [ ] Loads current `used_icons.json`
  - [ ] Computes set difference: icons in JSON that have no corresponding source reference
  - [ ] `--dry-run` flag: prints what would be removed without modifying the file
  - [ ] Default: interactive confirmation listing icons to remove, then writes pruned file
  - [ ] `--force` flag: skips confirmation (for CI)
  - [ ] Reports: `Removed 12 icons. used_icons.json reduced from 48KB to 21KB.`
- [ ] `[AGENT]` Add `prune` as a pre-step recommendation in the `doctor` command output when stale icons detected
- [ ] `[CI]` Add `iconify prune --dry-run --force` as an optional CI check that exits non-zero if pruning would change anything (enforces clean state)

---

## A.5 — `iconify add` Command (Explicit Icon Management)

> Alternative to purely implicit write-back. Lets developers explicitly declare which icons they want available.

- [ ] `[AGENT]` Implement `iconify add <prefix:name> [<prefix:name>...]` CLI command
  - [ ] Fetches icon data from local synced files or starter — falls back to GitHub raw
  - [ ] Writes directly into `used_icons.json` without needing to run the app first
  - [ ] Useful for CI/offline environments and for adding icons before writing the widget code
  - [ ] `--collection mdi` flag: adds all icons from a local synced collection

---

## A.6 — Phase A Exit Gate

- [ ] Production APK contains zero starter registry bytes (verified with `--analyze-size`)
- [ ] App using N icons ships only those N icon SVG bodies in `used_icons.json`
- [ ] `iconify prune` removes stale icons correctly
- [ ] Write-back survives hot reload (icons written once, not re-fetched on reload)
- [ ] `used_icons.json` is valid JSON after all operations (atomic write prevents corruption)
- [ ] Web dev flow works: web gets no `FileSystemIconifyProvider`, falls through to remote correctly

---

---

# Phase B — Security Hardening

> **Goal:** An app using iconify_sdk cannot be compromised by malicious SVG content in custom sets or tampered upstream data. Supply chain is pinned and verifiable.
>
> **Exit Criteria:** A corpus of 50 known-malicious SVG payloads are all sanitized correctly. Sync verifies SHA before writing. License enforcement is opt-out in the generate path.

---

## B.1 — SVG Sanitizer

> 🔴 **CRITICAL** — custom set support (planned in Phase E) opens an injection vector. Sanitizer must land before custom sets.

- [ ] `[AGENT]` Implement `SvgSanitizer` in `iconify_sdk_core`
  - [ ] Input: raw SVG body string (the `body` field from `IconifyIconData`)
  - [ ] Output: sanitized SVG body string, or throws `SvgSanitizationException` if irrecoverable
  - [ ] Strip: `<script>` elements and all children
  - [ ] Strip: `<foreignObject>` elements and all children
  - [ ] Strip: all event handler attributes (`on*`: `onclick`, `onload`, `onerror`, `onmouseover`, etc.)
  - [ ] Strip: `href` and `xlink:href` attributes containing `javascript:` or `data:` URI schemes
  - [ ] Strip: `<use>` elements with external `href` (only allow `#localId` references)
  - [ ] Strip: CSS `expression()`, `url(javascript:...)`, `url(data:...)` inside `style` attributes
  - [ ] Preserve: all valid SVG structural elements (`<path>`, `<g>`, `<rect>`, `<circle>`, `<defs>`, `<clipPath>`, `<mask>`, `<linearGradient>`, etc.)
  - [ ] Preserve: `currentColor` references (required for monochrome theming)
  - [ ] `SanitizerMode.strict` — throws on any stripped element (for validated official sets)
  - [ ] `SanitizerMode.lenient` — strips silently, logs warning in debug mode (default for custom sets)
- [ ] `[AGENT]` Apply sanitizer in `IconifyJsonParser.extractIcon()` — every icon body passes through sanitizer before being returned
  - [ ] Official starter sets: `SanitizerMode.strict` (should never have dangerous content — fail loudly if they do)
  - [ ] Remote-fetched icons: `SanitizerMode.lenient`
  - [ ] Custom sets: `SanitizerMode.lenient`
- [ ] `[AGENT]` Build SVG sanitizer fuzz corpus at `test/security/malicious_svgs/`
  - [ ] `xss_script_tag.svg` — inline `<script>` block
  - [ ] `xss_event_handler.svg` — `<rect onclick="alert(1)">`
  - [ ] `xss_href_javascript.svg` — `<a href="javascript:alert(1)">`
  - [ ] `xss_foreignobject.svg` — `<foreignObject><script>...</script></foreignObject>`
  - [ ] `xss_css_expression.svg` — `style="fill:expression(alert(1))"`
  - [ ] `xss_data_uri.svg` — `href="data:text/html,<script>alert(1)</script>"`
  - [ ] `xss_use_external.svg` — `<use href="https://evil.com/icons.svg#payload"/>`
  - [ ] `xss_xml_entity.svg` — XXE attempt via DOCTYPE
  - [ ] `benign_currentcolor.svg` — must survive sanitization unchanged
  - [ ] `benign_gradient.svg` — must survive sanitization unchanged
  - [ ] `benign_clippath.svg` — must survive sanitization unchanged
- [ ] `[AGENT]` Write `test/security/svg_sanitizer_test.dart` — all 11 corpus files tested
  - [ ] Malicious files: output contains none of the injected content
  - [ ] Benign files: output is byte-identical to input
- [ ] `[CI]` Add security test suite as a separate required CI job

---

## B.2 — Supply Chain Integrity

- [ ] `[AGENT]` Implement SHA-256 verification in `iconify sync`
  - [ ] After downloading `{prefix}.json` from GitHub raw, record the SHA-256 of the file contents in `iconify.lock`
  - [ ] `iconify.lock` format: `{ "mdi": { "sha256": "abc123...", "syncedAt": "...", "commitRef": "..." } }`
  - [ ] On subsequent sync: verify current lock SHA matches what was previously written before overwriting
  - [ ] `--no-verify` flag for explicit bypass (with a loud warning)
- [ ] `[AGENT]` Implement `iconify verify` CLI command
  - [ ] Re-downloads the current upstream version and compares SHA against `iconify.lock`
  - [ ] Reports: `✅ mdi: unchanged` / `⚠️ lucide: upstream changed since last sync (run iconify sync to update)`
  - [ ] Useful in CI to detect silent upstream mutations
- [ ] `[AGENT]` Pin `iconify/icon-sets` to a specific git commit SHA in sync
  - [ ] `iconify sync --pin` records the exact GitHub commit SHA at time of download
  - [ ] `iconify sync --commit=abc123` syncs from a specific historical commit
  - [ ] This makes synced data reproducible across machines and time

---

## B.3 — License Enforcement in Generate Path

- [ ] `[AGENT]` Make `iconify generate` emit a warning (not just `iconify licenses`) when attribution-required icons are in `used_icons.json`
  - [ ] Warning includes the exact attribution text required per license
  - [ ] `--strict-licenses` flag: exits non-zero on any attribution-required icon (for CI enforcement)
- [ ] `[AGENT]` Add `ICON_ATTRIBUTION.md` auto-generation to `iconify generate`
  - [ ] Produces a markdown file listing every icon in `used_icons.json` that requires attribution, with the required attribution text
  - [ ] `--attribution-output=path` flag to control destination
- [ ] `[CI]` Add `iconify generate --strict-licenses` as a recommended CI gate in the docs

---

## B.4 — Phase B Exit Gate

- [ ] All 11 malicious SVG corpus files sanitized with no injection content surviving
- [ ] All 3 benign SVG corpus files survive sanitization byte-identical
- [ ] `iconify.lock` written on every sync with correct SHA-256
- [ ] `iconify verify` correctly detects a tampered upstream file
- [ ] `iconify generate` warns on attribution-required icons
- [ ] `dart analyze` zero issues across all packages

---

---

# Phase C — Performance

> **Goal:** Icon resolution under 1ms for cached icons. Cold-start parsing of large collections under 100ms. Zero jank on first render.
>
> **Exit Criteria:** All benchmarks documented. No performance regressions vs v1 baseline.

---

## C.1 — Binary Icon Format

> The biggest single performance win. JSON parsing is the dominant cost for large collections at startup.

- [ ] `[AGENT]` Design binary format spec `docs/binary-format-spec.md`
  - [ ] Magic bytes: `0x49 0x43 0x4F 0x4E` ("ICON")
  - [ ] Version byte: `0x01`
  - [ ] Header: icon count (uint32), string table offset (uint32)
  - [ ] String table: all strings (body, prefix, name) stored once with length-prefixed encoding
  - [ ] Icon records: fixed-size header (width uint16, height uint16, flags uint8) + string table references
  - [ ] No JSON parser required — direct memory read
- [ ] `[AGENT]` Implement `BinaryIconFormat` encoder/decoder in `iconify_sdk_core`
  - [ ] `encode(ParsedCollection) → Uint8List`
  - [ ] `decode(Uint8List) → ParsedCollection`
  - [ ] `decodeIcon(Uint8List, String iconName) → IconifyIconData?` — single-icon extraction without decoding whole collection
- [ ] `[AGENT]` Implement `BinaryIconifyProvider` in `iconify_sdk_core`
  - [ ] Reads `.iconbin` files instead of `.json`
  - [ ] Lazy decodes — only parses headers on load, decodes icon body on demand
- [ ] `[AGENT]` Add `iconify generate --format=binary` flag to CLI
  - [ ] Produces `.iconbin` files in `assets/iconify/` alongside or instead of JSON
- [ ] `[AGENT]` Benchmark JSON vs binary parse time
  - [ ] MDI full collection (~7,500 icons): target < 20ms binary vs ~150ms JSON
  - [ ] Single icon lookup: target < 0.1ms binary vs ~2ms JSON
  - [ ] Document results in `docs/performance-baseline.md`

---

## C.2 — Lazy SVG Parsing

- [ ] `[AGENT]` Decouple icon data storage from SVG `Picture` object lifecycle
  - [ ] `IconifyIconData.body` stores raw string — this is already the case
  - [ ] `flutter_svg` `SvgPicture` parsing happens on first render only
  - [ ] Cache `Picture` objects (not strings) in a separate `PictureCache` keyed by `(name, color, size)`
  - [ ] `PictureCache` is separate from `LruIconifyCache` (different lifecycle — Pictures are Flutter objects, icon data is pure Dart)
- [ ] `[AGENT]` Implement `PictureCache` in `iconify_sdk`
  - [ ] `maxEntries` default 200 (Pictures are heavier than strings)
  - [ ] Eviction: LRU
  - [ ] `dispose()` calls `picture.dispose()` on evicted entries (prevents memory leak)
  - [ ] Exposed via `IconifyDiagnostics` for monitoring

---

## C.3 — Parallel Collection Loading

- [ ] `[AGENT]` Update `FileSystemIconifyProvider` to support parallel preload
  - [ ] `preload: true` now uses `Future.wait()` across all collections instead of sequential loading
  - [ ] `preloadPrefixes: ['mdi', 'lucide']` — selective preload of specific collections
  - [ ] Preloading happens on a background isolate via `compute()`
- [ ] `[AGENT]` Add `IconifyApp.preload(prefixes: [...])` convenience method
  - [ ] Called in `initState` of the root widget — starts preloading before any `IconifyIcon` widget is built
  - [ ] Optional — app works without it, just with slightly more latency on first icon per collection

---

## C.4 — Web: SVG Sprite Sheet

> The HTML renderer on Flutter web renders individual SVG strings poorly and benefits significantly from a single sprite.

- [ ] `[AGENT]` Implement `iconify generate --format=sprite` flag
  - [ ] Produces a single `icons.sprite.svg` combining all icons as `<symbol id="prefix-name">` elements
  - [ ] Each symbol uses `viewBox` from the source icon's width/height
- [ ] `[AGENT]` Implement `SpriteIconifyProvider` in `iconify_sdk`
  - [ ] Loads `icons.sprite.svg` as a single asset
  - [ ] Renders via `<svg><use href="#mdi-home"/></svg>` pattern
  - [ ] Only activated on `kIsWeb && !isCanvasKit` (HTML renderer detection)
- [ ] `[HUMAN]` Test sprite rendering on Flutter web HTML renderer
- [ ] `[HUMAN]` Test sprite rendering on Flutter web CanvasKit (should fall back to normal path)

---

## C.5 — Micro-Benchmarks

- [ ] `[AGENT]` Expand benchmark suite in `packages/core/benchmark/`
  - [ ] `name_parse_bench.dart` — 100k `IconifyName.parse()` iterations
  - [ ] `lru_cache_bench.dart` — 100k get/put with 500-entry cache
  - [ ] `json_parse_bench.dart` — full MDI collection parse
  - [ ] `binary_parse_bench.dart` — full MDI collection binary decode
  - [ ] `alias_resolve_bench.dart` — 10k alias chains depth-5
  - [ ] `single_icon_lookup_bench.dart` — single icon from 7,500-icon collection, JSON vs binary
- [ ] `[CI]` Run benchmarks on every PR, post results as a comment
- [ ] `[CI]` Fail CI if any benchmark regresses > 20% vs the baseline in `docs/performance-baseline.md`

---

## C.6 — Phase C Exit Gate

- [ ] Binary format encodes and decodes round-trip losslessly for MDI, Lucide, Heroicons
- [ ] Binary single-icon lookup is ≥ 10x faster than JSON equivalent (benchmarked)
- [ ] `PictureCache.dispose()` verified to not leak Flutter `Picture` objects
- [ ] Parallel preload bench shows ≥ 2x improvement over sequential for 5+ collections
- [ ] All benchmarks documented in `docs/performance-baseline.md`

---

---

# Phase D — Bundle Intelligence

> **Goal:** The `used_icons.json` file in production is as small as possible. Body data is compressed. Apps that only use monochrome icons get an optional font-based path that is 30-40% smaller.
>
> **Exit Criteria:** A real-world app with 50 icons ships ≤ 15KB of icon data.

---

## D.1 — Body Compression

> SVG path data is highly repetitive. Simple compression drops file size 40–60%.

- [ ] `[AGENT]` Add optional GZIP compression for `used_icons.json` and binary format
  - [ ] `iconify generate --compress` flag — produces `used_icons.json.gz` (or `.iconbin.gz`)
  - [ ] `LivingCacheProvider` auto-detects `.gz` extension and decompresses via `dart:io` `GZipDecoder`
  - [ ] Flutter web: use `dart:js_interop` `DecompressionStream` (Web Compression Streams API)
- [ ] `[AGENT]` Benchmark compression ratios on real sets
  - [ ] MDI 50-icon subset: target 40–60% reduction
  - [ ] Report raw vs compressed sizes in `docs/performance-baseline.md`

---

## D.2 — Icon Font Fallback (Monochrome Apps)

> If every icon an app uses is monochrome (uses `currentColor`), an auto-generated icon font is smaller and renders faster than equivalent SVG bodies.

- [ ] `[AGENT]` Implement `iconify generate --format=font` flag
  - [ ] Takes all monochrome icons in `used_icons.json`
  - [ ] Converts SVG path data to glyph outlines using `dart:ffi` bindings to `fonttools` or a pure-Dart path-to-glyph converter
  - [ ] Produces a `.ttf` font file registered as a Flutte
