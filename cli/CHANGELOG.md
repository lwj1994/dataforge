## 0.6.0
- **Documentation**: Complete CLI documentation in README
  - Added installation and usage instructions
  - Performance comparison with build_runner
  - Debug mode documentation
- Stable release with all features from 0.6.0-dev.x

## 0.6.0-dev.4
- Optimize generated code performance by adding `@pragma('vm:prefer-inline')`.

## 0.6.0-dev.2
- Bump version.

## 0.6.0-dev.1
- Fix `readObject` call arguments to pass value directly instead of map and key.

## 0.6.0-dev.0
- Refine nested `copyWith` API: use chained getter syntax (e.g., `.$address.street`) and remove flat accessor syntax.

## 0.2.0
- Chained copyWith support
- Support for fromJson and toJson hooks

## 0.1.0

- Initial release of data_class_gen
