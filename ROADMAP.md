# iconify_sdk — Complete Project Roadmap

> Version: 1.0 | Date: 2026-03-12  
> Based on: Refined Production Plan v2.0  
> Packages: `iconify_sdk_core` · `iconify_sdk` · `iconify_sdk_builder` · `iconify_sdk_cli`

---

## Reading Guide
- `[AGENT]` = Tasks Gemini CLI can perform.
- `[HUMAN]` = Tasks requiring manual intervention (physical device tests, publishing).
- ✅ = Completed.
- 🔴 = Blocked / Critical.

---

## Phase Overview

| Phase | Name | Packages Touched | Duration (part-time) | Exit Gate |
|---|---|---|---|---|
| 0 | Design Lock | All (setup only) | 1–2 weeks | ✅ ADRs signed, monorepo green, names reserved |
| 1 | Core Engine | `iconify_sdk_core` | 3–4 weeks | ✅ All tests pass, publishable dry-run OK |
| 2 | Flutter Package | `iconify_sdk` | 2–3 weeks | ✅ One-liner widget works, release mode blocks remote |
| 3 | build_runner Builder | `iconify_sdk_builder` | 2–3 weeks | ✅ build_runner build generates correct Dart code |
| 4 | CLI MVP | `iconify_sdk_cli` | 4–5 weeks | ✅ Full offline workflow end-to-end |
| 5 | Correctness | All | 2–3 weeks | ✅ Impeller golden tests pass, benchmarks documented |
| 6 | v1 Launch | All | 2–3 weeks | ✅ Publishable, documented, real-world tested |
| 7 | Post-v1 | All | Ongoing | Community traction, tooling moat |

**Total to v1:** ~16–23 weeks part-time

---

# Phase 0 — Design Lock ✅

> **Goal:** Align on architecture and project hygiene.

## 0.1 — Repository Setup
- [x] `[AGENT]` Initialize monorepo structure.
- [x] `[AGENT]` Configure Melos.
- [x] `[AGENT]` Setup strict analysis (`analysis_options.yaml`).
- [x] `[AGENT]` Scaffold empty packages:
  - `packages/core`
  - `packages/sdk`
  - `packages/builder`
  - `packages/cli`

## 0.2 — Architecture Documentation
- [x] `[AGENT]` Commit ADR-001 (Canonical Identity).
- [x] `[AGENT]` Commit ADR-002 (Hybrid Tooling).
- [x] `[AGENT]` Commit ADR-003 (Remote Blocking Policy).
- [x] `[AGENT]` Commit Internal Icon Spec (JSON schema).

---

# Phase 1 — Core Engine ✅

> **Goal:** A rock-solid, pure-Dart library for icon handling.

## 1.1 — Data Models
- [x] `[AGENT]` Implement `IconifyIconData`.
- [x] `[AGENT]` Implement `IconifyName` (with strict validation).
- [x] `[AGENT]` Implement `IconifyCollectionInfo`.

## 1.2 — Parsing Logic
- [x] `[AGENT]` Implement `IconifyJsonParser`.
- [x] [x] `[AGENT]` Implement `AliasResolver` (with recursion protection).

## 1.3 — Providers & Caching
- [x] `[AGENT]` Implement `IconifyProvider` interface.
- [x] `[AGENT]` Implement `MemoryIconifyProvider`.
- [x] `[AGENT]` Implement `LruIconifyCache`.
- [x] `[AGENT]` Implement `RemoteIconifyProvider` (GitHub-first, API fallback).

## 1.4 — Phase 1 Exit Gate
- [x] `dart analyze` — zero issues.
- [x] `dart test` — all tests pass.
- [x] `dart pub publish --dry-run` — clean.

---

# Phase 2 — Flutter Widget ✅

> **Goal:** The "One-Liner" experience.

## 2.1 — Base Widget
- [x] `[AGENT]` Implement `IconifyIcon`.
- [x] `[AGENT]` Support basic params: `size`, `color`, `opacity`.

## 2.2 — Centralized Config
- [x] `[AGENT]` Implement `IconifyApp` wrapper.
- [x] `[AGENT]` Implement `IconifyScope` (InheritedWidget).

## 2.3 — Rendering Strategy
- [x] `[AGENT]` Implement `RenderResolver`.
- [x] `[AGENT]` Implement `IconifyRasterizer` (Impeller fallback).

## 2.4 — Built-in Assets
- [x] `[AGENT]` Package the `Starter Registry` (MDI, Lucide, Tabler, Heroicons).
- [x] `[AGENT]` Implement `AssetBundleIconifyProvider`.

## 2.5 — Phase 2 Exit Gate
- [x] `flutter analyze` — zero issues.
- [x] `flutter test` — all tests pass.

---

# Phase 3 — build_runner Builder ✅

> **Goal:** Zero network dependencies in production.

## 3.1 — Builder Scaffolding
- [x] `[AGENT]` Configure `build.yaml`.
- [x] `[AGENT]` Implement `IconifyBuilder` skeleton.

## 3.2 — Source Scanning
- [x] `[AGENT]` Implement `IconNameScanner` (AST-based detection).

## 3.3 — Code Generation
- [x] `[AGENT]` Implement `IconCodeGenerator` (`icons.g.dart`).

## 3.4 — Phase 3 Exit Gate
- [x] `build_runner build` — works on test projects.
- [x] `dart test` — generator logic verified.

---

# Phase 4 — CLI MVP ✅

> **Goal:** Easy onboarding and legal compliance.

## 4.1 — Commands
- [x] `[AGENT]` Implement `iconify init`.
- [x] `[AGENT]` Implement `iconify sync` (GitHub Raw fetching).
- [x] `[AGENT]` Implement `iconify doctor`.
- [x] `[AGENT]` Implement `iconify licenses` (Legal report).

---

# Phase 5 — Correctness Hardening ✅

## 5.1 — Fuzzing
- [x] `[AGENT]` Fuzz `IconifyName` parser.
- [x] `[AGENT]` Fuzz `IconifyJsonParser` with malformed JSON.

## 5.2 — Benchmarks
- [x] `[AGENT]` Implement micro-benchmarks for name parsing and alias resolution.

---

# Phase 6 — v1 Launch ✅

> **Goal:** Someone can adopt this in production without reading the source code.  
> **Exit Criteria:** All packages published to pub.dev. Docs site live. At least one real-world usage example.

---

## 6.1 — Documentation

- [x] `[HUMAN]` + `[AGENT]` Write `packages/core/README.md`
- [x] `[HUMAN]` + `[AGENT]` Write `packages/sdk/README.md`
- [x] `[HUMAN]` + `[AGENT]` Write `packages/builder/README.md`
- [x] `[HUMAN]` + `[AGENT]` Write `packages/cli/README.md`
- [x] `[AGENT]` Write `docs/guides/safe-collections.md`
- [x] `[AGENT]` Write `docs/guides/custom-sets.md`
- [x] `[AGENT]` Write `docs/guides/migration-from-iconify-flutter.md`

---

## 6.2 — Example Gallery

- [x] `[AGENT]` Create `examples/basic/` — `IconifyIcon('mdi:home')`, zero config
- [x] `[AGENT]` Create `examples/bundled/` — fully offline with generated mode
- [ ] `[AGENT]` Create `examples/design_system/`
- [ ] `[AGENT]` Create `examples/icon_picker/`

---

## 6.3 — CHANGELOG & Versioning

- [x] `[AGENT]` Write `CHANGELOG.md` for each package
- [x] `[HUMAN]` Set version `0.1.0` for all packages
- [x] `[AGENT]` Tag `v0.1.0` in git

---

## 6.6 — Phase 6 Exit Gate

- [x] All 4 packages stable
- [x] All READMEs complete and accurate
- [x] 100% test pass project-wide

---

## Quick Reference — Commands After Full Setup

```bash
# Initial setup
dart run iconify_sdk_cli:iconify init

# Download icon data from GitHub (not the API)
dart run iconify_sdk_cli:iconify sync --collections mdi,lucide,tabler,heroicons

# Health check
dart run iconify_sdk_cli:iconify doctor

# Generate typed Dart constants
dart run build_runner build  # via build_runner builder
# OR
dart run iconify_sdk_cli:iconify generate  # via CLI directly

# Export license report
dart run iconify_sdk_cli:iconify licenses --format=markdown > ICON_LICENSES.md
```
