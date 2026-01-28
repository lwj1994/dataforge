## 0.6.1-dev.3
### Changed
- Compatibility update for `DataforgeInit.init`.

## 0.6.1-dev.2
### Changed
- Refinement for `DataforgeInit` compatibility.

## 0.6.1-dev.1
### Changed
- Refined `copyWith` single-field update methods to use internal `call()` method, ensuring all fields are correctly preserved.

## 0.6.1-dev.0
- **copyWith Null Handling**: Improved null handling for non-nullable primitive types
  - Provides default values instead of throwing `TypeError` when null is passed

## 0.6.0
- **Documentation**: Comprehensive README updates with complete feature documentation
  - Added detailed table of contents and navigation
  - Expanded JSON serialization documentation (DateTime, Enum, type casting)
  - Added complete `@JsonKey` annotation reference (8 parameters)
  - Added CLI tool documentation and performance tips
  - Added advanced features (custom converters, generics, collection handling)
  - Added comparison table with json_serializable and freezed
  - Added troubleshooting and migration guides
  - Updated all code examples with `@override` annotations (required for mixin pattern)
- Chinese README (README_ZH.md) fully synchronized with English version

## 0.6.0-dev.6
- Previous development version

## 0.6.0-dev.4
- Optimize generated code performance by adding `@pragma('vm:prefer-inline')`.

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
