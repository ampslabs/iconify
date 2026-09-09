# Contributing to iconify_sdk

Thanks for your interest in contributing! This monorepo contains the Flutter SDK, its pure-Dart core engine, the code generator, and the CLI.

## Repository Layout

```
packages/
  core/       iconify_sdk_core    — pure Dart engine (models, providers, binary format)
  sdk/        iconify_sdk         — Flutter package with the IconifyIcon widget
  builder/    iconify_sdk_builder — build_runner code generator
  cli/        iconify_sdk_cli     — command-line tool (iconify)
examples/     runnable sample apps (basic, bundled, gallery)
docs/         specifications, guides, and decision records (ADR)
```

## Local Setup

1. **Install Flutter** (stable channel) and ensure `dart` is on your `PATH`.
2. **Activate Melos** (used for multi-package tasks):

```bash
dart pub global activate melos
export PATH="$PATH:$HOME/.pub-cache/bin"
melos bootstrap
```

`melos bootstrap` wires up all packages and runs `pub get` across the workspace.

## Development Commands

Scripts are defined in the `melos:` block of the root `pubspec.yaml`:

```bash
melos run analyze          # Static analysis over every package
melos bootstrap            # Install/resolve all package dependencies
melos run format           # Verify formatting (CI gate)
melos run test             # Run tests for every package
melos run test:pure        # Run pure Dart tests only
melos run test:flutter     # Run Flutter tests only
```

All of these are enforced in CI on the `main` branch, so please run them before pushing.

## Making Changes

- Follow the existing conventions in the code you touch. The codebase uses `lints`/`flutter_lints` with `--fatal-infos` in CI, so **warnings and infos are treated as errors**.
- Keep the pure-Dart core (`packages/core`) free of Flutter imports — it must stay usable from the CLI and server contexts.
- When you add, remove, or change public APIs, update any affected docs in `docs/` (ADRs, specs, guides) in the same PR.
- Update `CHANGELOG.md` entries per package and bump versions via Melos when making a release:

```bash
melos version
```

## Testing

- Add unit tests for any new behavior. Pure-Dart packages use `test`; the Flutter package uses `flutter_test`.
- The Flutter package has golden tests (`packages/sdk/test/golden/`). When the rendered output legitimately changes, regenerate the goldens with your change and include the updated fixtures:

```bash
flutter test --update-goldens test/golden/
```

- Golden pixel tolerances are intentionally strict; if your change alters rendering by more than a rounding error, confirm the diff images under `test/golden/failures/` before updating.

## Security

Report security issues privately — see [SECURITY.md](SECURITY.md). Do not open a public issue for vulnerabilities. The SVG sanitizer corpus (`packages/core/test/security/malicious_svgs/`) must never regress.

## PR Checklist

- [ ] `melos run analyze` passes with zero issues in every package
- [ ] `melos run test` passes (pure Dart and Flutter test suites)
- [ ] `melos run format` reports no changes
- [ ] Public API changes are reflected in `docs/`
- [ ] New/changed behavior covered by tests
- [ ] CHANGELOG entries updated if releasing

## Getting Help

Open an issue or discussion at <https://github.com/ampslabs/iconify>. The [ROADMAP](ROADMAP.md) describes the v2 phases; check it before starting work that may already be planned.