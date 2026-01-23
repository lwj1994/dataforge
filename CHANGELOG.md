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
