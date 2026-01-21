## 0.6.0-dev.2
- Bump version.

## 0.6.0-dev.1
- Fix `readObject` call arguments to pass value directly instead of map and key.

## 0.6.0-dev.0
- Refine nested `copyWith` API: use chained getter syntax (e.g., `.$address.street`) and remove flat accessor syntax.

## 0.5.0-dev.5
- Add `isRequired` field parsing for constructor parameters.
- Use `readRequiredValue` for required non-nullable basic types in `fromJson`.
- Use `readRequiredObject` for required non-nullable Dataforge objects in `fromJson`.
- Use `readObject` for optional Dataforge objects with default values.
- Improve code generation for cleaner output.

## 0.5.0-dev.3
- Remove `required_inputs` from `build.yaml`.

## 0.5.0-dev.2
- Support detecting Dataforge prefix alias.
- Support List<Object> nested fromJson.
- Fix dataforgeUndefined prefix.

## 0.5.0-dev.1
- Development release.

## 0.5.0-dev.0
- Development release.
