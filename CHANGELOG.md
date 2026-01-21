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
