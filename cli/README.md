# Dataforge CLI

Standalone resolved code-generation adapter for Dataforge v1 value models.

> `1.0.0-dev.0` is a preview, not the 1.0 GA release. The CLI supports only the
> v1 `abstract final` factory declaration and never edits model source.

## Install

```bash
dart pub global activate dataforge_cli 1.0.0-dev.0
```

The consumer package needs the matching runtime annotation package:

```yaml
dependencies:
  dataforge_annotation: ^1.0.0-dev.0
```

Dart 3.9 or later is required. Run `dart pub get` in each package before
generation so the resolved frontend can read its package configuration.

## Commands

Generate a package or one Dart source file:

```bash
dataforge generate .
dataforge generate lib/models/user.dart
```

Check committed output without writing:

```bash
dataforge check .
```

`check` exits 4 when output is missing, stale, or an unfinished generation
journal requires recovery. In the journal case, run normal `generate` once and
then repeat `check`.

## Declaration

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

The declaration contract is the same as the build_runner adapter: exact part,
mixin, implementation and redirecting-factory shapes are required. Missing or
invalid source declarations produce diagnostics; the CLI does not insert or
rewrite them.

## Transaction model

A normal generation run:

1. resolves all candidate libraries and builds schemas in memory;
2. renders and formats all outputs in memory;
3. validates the complete generated library overlay;
4. groups outputs by their nearest Dart package root;
5. revalidates source, package configuration and pubspec snapshots under that
   package's process lock;
6. installs outputs through same-directory temporary files and that package's
   recovery journal.

The journal is written before target replacement. A later normal generation
rolls an interrupted transaction back before starting new work. Unknown target
content, links and malformed journals are preserved and reported rather than
overwritten.

Multiple generated files in one package are transactionally recoverable as a
group, but they are not guaranteed to become visible at the same instant at the
operating-system level. A monorepo invocation uses independent transactions for
different packages so outer and nested invocations coordinate on the same lock
and journal for every shared target.

## Exit status

| Code | Meaning |
| --- | --- |
| 0 | Generation or check succeeded |
| 2 | Invalid command arguments |
| 3 | Generation or declaration failure |
| 4 | Check drift or another safe precondition failure |
| 5 | File-system or transaction I/O failure |
| 70 | Unexpected internal failure |

## CI

Commit generated `.data.dart` files when that is your project policy, then add:

```bash
dataforge check .
```

The command is strictly read-only. It does not create a lock, recover a journal,
or modify source/generated files.

## Relationship to build_runner

The CLI and `dataforge` build_runner adapter use the same resolved generation
facade and renderer. Representative fixtures assert byte-for-byte parity. This
preview does not yet claim a complete GA parity matrix for every type and
platform.

## Troubleshooting

- **No package configuration:** run `dart pub get` in the nearest package root.
- **DF1001 declaration error:** verify `abstract final`, `_$Model`, `_Model`, the
  private base constructor, redirecting factory and `.data.dart` part URI.
- **Check exits 4:** run normal generation and inspect the resulting diff.
- **Recovery is refused:** preserve the reported files and journal; unknown
  content is never guessed or deleted automatically.

See the [generator documentation](https://github.com/lwj1994/dataforge/tree/main/generator)
for annotations, strict JSON and witness semantics.
