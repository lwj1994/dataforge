# Dataforge Generator

The build_runner adapter for Dataforge v1 deeply immutable value models.

> `1.0.0-dev.0` is a preview, not the 1.0 GA release. APIs, diagnostics and
> generated output may still change in later preview versions.

## Installation

```yaml
dependencies:
  dataforge_annotation: ^1.0.0-dev.0

dev_dependencies:
  build_runner: ^2.4.13
  dataforge: ^1.0.0-dev.0
```

All Dataforge packages in an application must resolve to the same preview
version. Dart 3.9 or later is required.

## Model declaration

```dart
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'user.data.dart';

@Dataforge()
abstract final class User with _$User {
  const User._();

  factory User({
    required String name,
    @DataforgeDefault(<String>[]) List<String> tags,
    @JsonKey(name: 'display_name') String? displayName,
  }) = _User;

  factory User.fromJson(Map<String, Object?> json) = _User.fromJson;
}
```

The declaration contract is strict:

- the public model is `abstract final`;
- value properties come from one unnamed redirecting factory;
- the generated target is `_User` and the generated mixin is `_$User`;
- `const User._();` provides the base constructor for the final implementation;
- the `part` URI must end in `.data.dart` and match the source file;
- JSON input is `Map<String, Object?>`;
- a `fromJson` factory, when enabled, redirects to `_User.fromJson`.

Invalid declarations fail generation with a source-located `DF` diagnostic.
The generator never rewrites the model source.

## Generate

```bash
dart run build_runner build
```

For continuous generation:

```bash
dart run build_runner watch
```

The published builder always emits `.data.dart` part files. The output suffix is
not configurable in this preview.

## Value semantics

Generated implementations are `final`. Constructor, `copyWith`, default and
decode boundaries recursively freeze the complete declared type tree:

- `List`, `Set` and `Map` inputs are copied and exposed through unmodifiable
  collections;
- nested collections and records are traversed recursively;
- equality and hash use the same leaf witnesses as freeze;
- `copyWith` may safely share values already frozen under compatible witness
  semantics.

Mutating caller-owned collections after construction cannot change a model.
Set elements and Map keys that collapse under witness equality are rejected
instead of being silently discarded.

## Annotations

### `@Dataforge`

```dart
@Dataforge(
  name: '',
  includeFromJson: true,
  includeToJson: true,
)
```

`name` changes the private implementation base name. JSON directions can be
disabled independently.

### `@DataforgeDefault`

Dart does not allow a default directly on a redirecting factory parameter. Use
compile-time metadata instead:

```dart
factory Page({
  @DataforgeDefault(1) int number,
  @DataforgeDefault(<String>[]) List<String> labels,
}) = _Page;
```

The resolved frontend validates that the constant is assignable and can be
rendered without losing meaning.

### `@JsonKey`

```dart
factory User({
  @JsonKey(
    name: 'user_name',
    alternateNames: ['username'],
    includeIfNull: false,
  )
  String? name,
}) = _User;
```

`ignore: true` excludes a field from both JSON directions. An ignored required
field must still have a construction default.

## Strict JSON

Generated codecs do not coerce unrelated runtime types. They validate required
fields, nullability, unknown keys, aliases, duplicate decoded keys and custom
witness output. Failures use `DataforgeDecodeException` or
`DataforgeEncodeException` with a stable `DFJ` code and JSONPath.

`DateTime` is encoded as normalized UTC ISO-8601 text. Record values have
recursive non-JSON value semantics, but a Record subtree used by JSON requires
an exact `DataforgeType<RecordShape>` witness; otherwise generation reports
DF1006.

## Generic and custom values

Any behavior that depends on a type parameter or unsupported custom leaf needs
an explicit `DataforgeType<T>` witness:

```dart
@Dataforge()
abstract final class Box<T> with _$Box<T> {
  const Box._();

  factory Box({
    required DataforgeType<T> type,
    required T value,
  }) = _Box<T>;

  factory Box.fromJson(
    Map<String, Object?> json, {
    required DataforgeType<T> type,
  }) = _Box<T>.fromJson;
}
```

A custom witness is part of the value contract. Its identity tree and its
freeze/equality/hash/codec behavior must remain immutable for its entire
lifetime. `freeze` must isolate mutable input; equality and hash must agree.

## Standalone CLI

The `dataforge_cli` package provides a standalone resolved adapter:

```bash
dataforge generate .
dataforge check .
```

Both adapters use the same resolved facade and renderer. Representative
fixtures assert byte parity, but the full GA type/platform parity matrix is not
complete yet.

## Troubleshooting

1. Run `dart pub get` in the nearest package root.
2. Check the exact `part`, `_$Model`, `_Model` and private base constructor names.
3. Use `@DataforgeDefault` rather than a redirecting-factory default.
4. Provide one compatible witness for every type-dependent semantic subtree.
5. Follow the first source-located `DF` diagnostic; later errors are often
   consequences of the same declaration mismatch.

See the [1.0 RFC](https://github.com/lwj1994/dataforge/blob/main/docs/1.0/RFC.md)
and [support matrix](https://github.com/lwj1994/dataforge/blob/main/docs/1.0/SUPPORT_MATRIX.md)
for the preview boundary.
