# CLAUDE.md

This file provides repository guidance for Claude Code.

## Project Overview

Dataforge generates deeply immutable Dart value models with strict JSON,
`copyWith`, equality, hash and `toString` support.

The current shared version is `1.0.0-dev.0`. It is a preview, not the 1.0 GA
release. The repository is v1-only: supported models use an `abstract final`
public class with a redirecting factory and a generated `final` implementation.
APIs, diagnostics and generated output may still change during preview releases.

## Monorepo Structure

- **annotation/** — `dataforge_annotation`: v1 metadata, runtime witnesses and
  strict JSON errors.
- **dataforge_base/** — `dataforge_base`: the resolved generation facade,
  diagnostics and internal schema/renderer implementation. It has no
  build_runner dependency.
- **generator/** — `dataforge`: the build_runner adapter.
- **cli/** — `dataforge_cli`: the standalone resolved `generate` / `check`
  adapter and recoverable generated-file transaction.

`generator` and `cli` depend on `annotation` and `dataforge_base`. Local path
references belong in `pubspec_overrides.yaml`; published pubspecs retain hosted
constraints and all four packages use the same version.

## Common Commands

Each package is independent. Run package commands from its directory:

```bash
# Install dependencies.
cd <package> && dart pub get

# Run all tests or one test file.
cd <package> && dart test
cd <package> && dart test test/specific_test.dart

# Run static analysis with the CI severity.
cd <package> && dart analyze --fatal-infos

# Check formatting without rewriting files.
cd <package> && dart format --output=none --set-exit-if-changed .

# Generate through build_runner in a consumer or generator/example.
dart run build_runner build

# Generate or perform a read-only drift check through the CLI.
dataforge generate .
dataforge check .
```

## Model Contract

```dart
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'user.data.dart';

@Dataforge()
abstract final class User with _$User {
  const User._();

  factory User({
    required String name,
    @DataforgeDefault(<String>[]) List<String> tags,
  }) = _User;

  factory User.fromJson(Map<String, Object?> json) = _User.fromJson;
}
```

- Generated files use `.data.dart`.
- Values come from one unnamed redirecting factory.
- `_$Model` is the generated mixin and `_Model` is the generated final target.
- Redirecting-factory defaults use compile-time `@DataforgeDefault` metadata.
- `@JsonKey` currently supports `name`, `alternateNames`, `ignore` and
  `includeIfNull`.
- The generators never insert declarations or rewrite model source.

## Architecture and Invariants

- Both adapters use the same resolved generation facade and renderer. Raw
  schemas and the renderer are internal and must not be exported or called by
  adapters directly.
- Freeze, equality and hash traverse the same complete semantic type tree.
- List, Set, Map and Record inputs are copied and recursively frozen at every
  public boundary.
- Generic or custom semantic subtrees require an explicit `DataforgeType<T>`
  witness. Custom witness behavior and identity trees must remain immutable.
- Strict JSON does not coerce unrelated runtime types. Failures include stable
  `DFJ` codes and JSONPath.
- Record has recursive non-JSON value semantics; a Record subtree used by JSON
  requires an exact witness.
- Representative fixtures assert build_runner/CLI byte parity. The complete
  GA type/platform matrix is not finished yet.

## CLI Transaction Rules

Explicit `generate` resolves, renders, formats and validates every output in
memory before entering a locked, journaled multi-file commit. Input snapshots
are revalidated under the lock. Each target uses same-directory atomic rename;
multiple files are recoverable as a group but are not guaranteed to become
visible simultaneously at the operating-system level.

`check` is strictly read-only. It does not create a lock, recover a
journal or modify files. Drift or an unfinished generation journal exits 4;
run explicit `generate` to recover, then repeat `check`.

Unknown target content, malformed journals, symlinks and hash mismatches are
preserved and reported rather than guessed or overwritten.

## Code Style

- The toolchain requires Dart SDK 3.9 or later and Analyzer 8.x.
- All source comments and public API doc comments must be English.
- Respect package implementation-import boundaries.
- Generated `*.data.dart` files are not authored source and should only be
  regenerated through a supported adapter.

## Publishing

Publish in dependency order: `annotation` → `dataforge_base` → `generator` →
`cli`. Wait for each upstream hosted version to become resolvable instead of
using a fixed sleep. Follow `.claude/skills/release.md` for the complete strict
dry-run and clean-consumer workflow.
