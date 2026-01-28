## 0.6.1-dev.3
### Changed
- Renamed parameter `onError` to `onCopyWithError` in `DataforgeInit.init` for better clarity.

## 0.6.1-dev.2
### Changed
- Changed `DataforgeInit` from an `extension` to a `class` to avoid potential compatibility issues and improve discoverability.

## 0.6.1-dev.1
### Changed
- Refined `copyWith` single-field update methods to use internal `call()` method, ensuring all fields are correctly preserved.

## 0.6.1-dev.0
### Added
- **Error Callback API**: New `DataforgeConfig` and `DataforgeInit.init()` for registering error callbacks
  - Allows developers to capture and handle type conversion errors in `copyWith`
  - `SafeCasteUtil.copyWithCast` and `SafeCasteUtil.copyWithCastNullable` for safe type conversion with error reporting

### Fixed
- **copyWith Null Handling**: Improved null handling for non-nullable primitive types
  - `String`: uses `''` as default when null is passed
  - `int`: uses `0` as default when null is passed
  - `double`: uses `0.0` as default when null is passed
  - `bool`: uses `false` as default when null is passed
  - Prevents runtime `TypeError` when null is incorrectly passed to non-nullable fields

## 0.6.0
### Added
- **Comprehensive Documentation**: Complete README overhaul for all packages
  - Detailed feature documentation with examples
  - CLI tool usage and performance tips
  - Advanced features guide (custom converters, generics, collections)
  - Comparison table with json_serializable and freezed
  - Migration guides and troubleshooting
  - Chinese README fully synchronized
- **Circular Dependency Detection**: Automatic detection with clear warnings
- **Structured Logging**: `DataforgeLogger` with debug/info/warning/error levels

### Fixed
- **DateTime Converter**: Fixed dangerous padding logic
  - Correctly handles 10-digit seconds timestamps (Unix standard)
  - Correctly handles 13-digit milliseconds timestamps
  - Throws `FormatException` for ambiguous lengths
  - Supports ISO 8601 date string parsing
- Type casting for `double` fields in `copyWith` (smart casting from `int` via `num`)

### Changed
- Updated all code examples with `@override` annotations (required for mixin pattern)
- Unified `analyzer` dependency to ^8.1.1 across all packages
- Performance optimizations with `@pragma('vm:prefer-inline')`

### Documentation
- 25 new tests added (6 for circular dependencies, 19 for DateTime converter)
- README expanded from ~200 lines to 760+ lines with comprehensive guides
- All documentation properly synchronized between English and Chinese versions

## 0.6.0-dev.6
### Added
- **Circular Dependency Detection**: Automatic detection of circular references between Dataforge classes with clear warnings
- **Structured Logging**: New `DataforgeLogger` utility with debug/info/warning/error levels
- Comprehensive test coverage: 25 new tests (6 for circular dependencies, 19 for DateTime converter)

### Fixed
- **DateTime Converter**: Fixed dangerous padding logic that produced incorrect dates
  - Now correctly handles 10-digit seconds timestamps (Unix standard)
  - Now correctly handles 13-digit milliseconds timestamps
  - Throws `FormatException` for ambiguous timestamp lengths
  - Supports ISO 8601 date string parsing

### Changed
- Unified `analyzer` dependency to ^8.1.1 across all packages
- Improved error handling with structured logging in dataforge_base

### Documentation
- Added CIRCULAR_DEPENDENCY_ISSUE.md with detailed problem explanation
- Added IMPROVEMENTS_REPORT.md with complete change summary
- Enhanced DateTime converter documentation with examples

## 0.6.0-dev.4
- Optimize generated code performance by adding `@pragma('vm:prefer-inline')`.

## 0.6.0-dev.2
- Bump version.

## 0.6.0-dev.1
- Fix `readObject` call arguments to pass value directly instead of map and key.

## 0.6.0-dev.0
- Refine nested `copyWith` API: use chained getter syntax (e.g., `.$address.street`) and remove flat accessor syntax.

## 0.5.0-dev.5
- Add `readObject` and `readRequiredObject` methods to `SafeCasteUtil` for parsing nested objects with factory functions.
- Add `parseObject` method for internal object parsing.
- Rename `objectFromJson` to use new API pattern.

## 0.5.0-dev.3
- Initial development release.
