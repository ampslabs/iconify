# Phase 2 — Flutter Package (`iconify_sdk`)

> **Goal**: Deliver a production-ready Flutter package that provides the `IconifyIcon` widget. It must handle rendering correctly across all platforms (including Impeller), enforce the "Ethical API" policy (blocked in release), and provide a seamless first-run experience via the Starter Registry.
> **Package**: `packages/sdk` (exported as `iconify_sdk`)

---

## 2.1 — Package Scaffolding & Baseline
**Objective**: Prepare the Flutter package environment with correct dependencies and directory structure.

- [ ] **2.1.1: Pubspec Finalization**
  - [ ] Add `flutter_svg: ^2.0.0` (core rendering engine).
  - [ ] Add `meta: ^1.15.0` (for `@immutable` and annotations).
  - [ ] Add `path: ^1.9.0` (for asset path manipulation).
  - [ ] Add `dev_dependencies`: `flutter_test`, `mocktail`, `alchemist` (for golden tests).
- [ ] **2.1.2: Directory Architecture**
  - [ ] `lib/src/config/`: Configuration models and inherited widgets.
  - [ ] `lib/src/provider/`: Flutter-specific providers (AssetBundle).
  - [ ] `lib/src/registry/`: Starter registry logic and assets.
  - [ ] `lib/src/render/`: Impeller detection and rendering strategies.
  - [ ] `lib/src/widget/`: The user-facing widgets (`IconifyIcon`, `IconifyApp`).
- [ ] **2.1.3: Asset Registration**
  - [ ] Register `packages/iconify_sdk/assets/iconify/starter/` in `pubspec.yaml`.

---

## 2.2 — Platform & Rendering Layer
**Objective**: Resolve the Impeller `colorFilter` bug identified in Refined Plan v2.0.

- [ ] **2.2.1: Impeller Detector**
  - [ ] Implement `ImpellerDetector` utility.
  - [ ] Logic: Check `PlatformDispatcher.instance.views.first.platformDispatcher.isImpellerEnabled` (where available) or fallback to iOS-default logic.
- [ ] **2.2.2: Rasterization Engine**
  - [ ] Implement `IconifyRasterizer`.
  - [ ] Logic: Use `vg.loadPicture()` to render SVG to `ui.Image`.
  - [ ] Support `devicePixelRatio` to ensure sharp icons on high-DPI screens.
  - [ ] Implement an internal `ImageProvider` cache for rasterized results.
- [ ] **2.2.3: Rendering Strategy Logic**
  - [ ] Implement `resolveRenderStrategy()` helper.
  - [ ] If `RenderStrategy.auto`:
    - [ ] If `color` provided AND Impeller detected → `rasterized`.
    - [ ] Else → `svgDirect`.

---

## 2.3 — Configuration & Scope
**Objective**: Implement the mechanism for global configuration and provider injection.

- [ ] **2.3.1: IconifyMode & Config Models**
  - [ ] Create `IconifyMode` enum: `auto`, `offline`, `generated`, `remoteAllowed`.
  - [ ] Create `IconifyConfig` immutable class.
- [ ] **2.3.2: IconifyScope (InheritedWidget)**
  - [ ] Implement `IconifyScope` to provide a `CompositeIconifyProvider` to the tree.
  - [ ] Provide `of` and `maybeOf` static methods.
- [ ] **2.3.3: Provider Chain Builder**
  - [ ] Implement logic to build the chain based on mode and `kDebugMode`:
    - **Debug/Profile**: `[Memory, Starter, Remote (if opted in)]`.
    - **Release**: `[Memory, Starter, Generated (if exists)]` (Remote BLOCKED).

---

## 2.4 — Data Layer (Flutter Specifics)
**Objective**: Connect the core engine to Flutter's asset system.

- [ ] **2.4.1: FlutterAssetBundleIconifyProvider**
  - [ ] Implement concrete class extending `AssetBundleIconifyProvider`.
  - [ ] Use `rootBundle` or a custom `AssetBundle` for string loading.
  - [ ] Implement caching of parsed JSON to avoid redundant I/O.
- [ ] **2.4.2: Starter Registry Runtime**
  - [ ] Implement `StarterRegistry` singleton.
  - [ ] Logic: Lazily load `starter_manifest.json` from the SDK's own assets.
  - [ ] Provide metadata for all 200+ collections even if icons aren't bundled.

---

## 2.5 — The IconifyIcon Widget
**Objective**: The primary user-facing API.

- [ ] **2.5.1: Widget Implementation**
  - [ ] Support `IconifyIcon('mdi:home')` and `IconifyIcon.name(IconifyName)`.
  - [ ] Parameters: `size`, `color`, `opacity`, `semanticLabel`, `renderStrategy`.
  - [ ] Logic: Resolve icon from `IconifyScope` via `FutureBuilder` or `StatefulWidget` lifecycle.
- [ ] **2.5.2: Placeholder & Error Handling**
  - [ ] Default loading state (shimmer or empty box).
  - [ ] Default error state: `IconifyErrorWidget` (colored box with glyph).
  - [ ] Debug mode: Print actionable "hint" when an icon is missing (e.g., "Run iconify_sdk_cli sync").

---

## 2.6 — DX & Global Entry Point
**Objective**: Make the one-liner setup possible.

- [ ] **2.6.1: IconifyApp**
  - [ ] Create a "Global Provider" widget that developers wrap their `MaterialApp` with.
  - [ ] Handle automatic initialization of the default provider chain.
- [ ] **2.6.2: Barrel Exports**
  - [ ] Export `IconifyIcon`, `IconifyApp`, `IconifyConfig`, `RenderStrategy`.
  - [ ] Ensure core models (like `IconifyName`) are also reachable.

---

## 2.7 — Testing & Verification (Production Quality)
**Objective**: 100% reliability across renderers.

- [ ] **2.7.1: Widget Tests**
  - [ ] Test `IconifyIcon` with `MemoryIconifyProvider`.
  - [ ] Test color application.
  - [ ] Test fallback/error builders.
- [ ] **2.7.2: Golden Tests (Alchemist)**
  - [ ] Create golden scenarios for:
    - [ ] Monochrome vs Multicolor.
    - [ ] Custom sizes.
    - [ ] Color overrides.
- [ ] **2.7.3: Impeller Verification (Manual Gate)**
  - [ ] **Critical**: Run tests on physical iOS device.
  - [ ] Compare `svgDirect` vs `rasterized` output under Impeller.

---

## Exit Criteria Checklist
- [ ] `flutter analyze` zero issues.
- [ ] `flutter test` 100% passing.
- [ ] Golden tests verified on physical device (Impeller workaround confirmed).
- [ ] `RemoteIconifyProvider` verified to be blocked in release builds.
- [ ] `IconifyIcon('mdi:home')` renders a Material home icon with zero config.
- [ ] README.md includes "Impeller & Performance" section.
