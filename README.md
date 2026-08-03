# Dataforge

Dataforge 为 Dart 和 Flutter 生成深度不可变的 v1 值对象。

> **`1.0.0-dev.0` 仍是预览版本，不是 1.0 GA。** 当前 API、诊断与生成格式仍可能在
> 后续 dev/beta 版本中调整。1.0 只支持 `abstract final` factory 声明和生成的
> `final` 实现；这是当前唯一支持的模型声明形状。

[1.0 RFC](https://github.com/lwj1994/dataforge/blob/main/docs/1.0/RFC.md) ·
[支持矩阵](https://github.com/lwj1994/dataforge/blob/main/docs/1.0/SUPPORT_MATRIX.md)

## Quick start

```yaml
dependencies:
  dataforge_annotation: ^1.0.0-dev.0

dev_dependencies:
  build_runner: ^2.4.13
  dataforge: ^1.0.0-dev.0
```

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

使用 build_runner 生成：

```bash
dart run build_runner build
```

或使用独立 CLI 预览前端：

```bash
dart pub global activate dataforge_cli 1.0.0-dev.0
dataforge generate .
dataforge check .
```

`check` 只比较预期字节，不写文件；输出缺失或漂移时退出 4。普通
`generate` 会在内存中解析并格式化所有输出，再通过 journal、进程锁和逐文件原子
替换提交。CLI 不会修改模型源码。

## v1 value semantics

- 模型入口必须是 `abstract final class`；唯一具体实现由生成器创建并声明为 `final`。
- 值属性来自 redirecting factory 参数，不在抽象类中重复声明字段。
- `List`、`Set`、`Map`、Record 以及它们任意深度的组合都会沿完整类型树递归冻结。
- equality 与 hash 使用同一完整语义类型树；自定义叶节点由 `DataforgeType<T>`
  witness 定义 freeze、equality、hash 与 JSON codec。
- JSON 默认严格校验类型、required/null/default、未知 key 与 alternate-name 冲突，
  并通过稳定 `DFJ` code 和 JSONPath 报告错误。
- Record 支持非 JSON 值语义；参与 JSON 的 Record 子树需要 exact witness，否则在
  生成期产生 DF1006。

两个生成前端共享 resolved schema 和 renderer。当前已有代表性 fixture 的字节一致性
测试，但完整类型矩阵和 GA 级跨平台一致性门禁仍在建设中。

## Packages

| Package | Purpose |
| --- | --- |
| [dataforge_annotation](https://pub.dev/packages/dataforge_annotation) | v1 annotations, runtime witnesses and strict JSON errors |
| [dataforge_base](https://pub.dev/packages/dataforge_base) | resolved generation facade and diagnostics |
| [dataforge](https://pub.dev/packages/dataforge) | build_runner adapter |
| [dataforge_cli](https://pub.dev/packages/dataforge_cli) | standalone `generate` / `check` adapter |

## AI Skill

```bash
npx skills add https://github.com/lwj1994/dataforge --skill dataforge
```
