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
