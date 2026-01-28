## 0.6.1-dev.1
### Changed
- Refined `copyWith` single-field update methods to use internal `call()` method, ensuring all fields are correctly preserved.

## 0.6.1-dev.0
- **copyWith Null Handling**: Improved null handling for non-nullable primitive types (String, int, double, bool)
  - Provides default values instead of throwing `TypeError` when null is passed
  - String: `''`, int: `0`, double: `0.0`, bool: `false`

## 0.6.0
- **Bug Fixes**:
  - Fixed DateTime converter padding logic that could produce incorrect dates
  - Now correctly handles 10-digit (seconds) and 13-digit (milliseconds) timestamps
  - Throws `FormatException` for ambiguous timestamp lengths
- **New Features**:
  - Added circular dependency detection
  - Added structured logging with `DataforgeLogger`
- **Performance**:
  - Code generation optimized with `@pragma('vm:prefer-inline')`
- Stable release

## 0.6.0-dev.4
- Optimize generated code performance by adding `@pragma('vm:prefer-inline')`.

## 0.6.0-dev.2
- Fix type casting mismatch for `double` fields in `copyWith` by enabling smart casting from `int` (via `num`).

## 0.6.0-dev.1
- Fix `readObject` call arguments to pass value directly instead of map and key.

## 0.6.0-dev.0
- Refine nested `copyWith` API: use chained getter syntax (e.g., `.$address.street`) and remove flat accessor syntax.

## 0.5.0

- Initial release.
- Extracted core logic (models, parser, writer) from `dataforge_generator`.
