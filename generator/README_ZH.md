# Dataforge Generator

Dataforge v1 深度不可变值对象的 build_runner 适配器。

> `1.0.0-dev.0` 是预览版本，不是 1.0 GA。API、诊断与生成格式仍可能在后续
> dev/beta 版本中调整。

## 安装

```yaml
dependencies:
  dataforge_annotation: ^1.0.0-dev.0

dev_dependencies:
  build_runner: ^2.4.13
  dataforge: ^1.0.0-dev.0
```

业务项目中的所有 Dataforge 包必须解析到同一预览版本，并使用 Dart 3.9 或更高版本。

## 模型声明

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

声明契约是严格的：

- 公开模型必须是 `abstract final`；
- 值属性来自唯一的 unnamed redirecting factory；
- 生成目标是 `_User`，生成 mixin 是 `_$User`；
- `const User._();` 为 final 实现提供基类构造器；
- `part` URI 必须以 `.data.dart` 结尾并与源文件匹配；
- JSON 输入类型是 `Map<String, Object?>`；
- 启用 `fromJson` 时，factory 重定向到 `_User.fromJson`。

非法声明会产生带源码位置的 `DF` 诊断。生成器不会改写模型源码。

## 生成

```bash
dart run build_runner build
```

持续生成：

```bash
dart run build_runner watch
```

已发布 builder 固定生成 `.data.dart` part；当前预览不支持自定义输出后缀。

## 值语义

生成实现为 `final`。构造、`copyWith`、默认值与 decode 边界都会递归冻结完整声明类型树：

- `List`、`Set`、`Map` 输入会先复制，再通过不可修改集合公开；
- 任意深度的嵌套集合和 Record 都会递归遍历；
- freeze、equality 与 hash 使用同一组叶节点 witness；
- `copyWith` 可以安全共享已经由兼容 witness 语义冻结的值。

模型构造后再修改调用方持有的集合，不会改变模型。若 Set 元素或 Map key 在 witness
equality 下发生折叠，构造会拒绝输入，不会静默丢值。

## 注解

### `@Dataforge`

```dart
@Dataforge(
  name: '',
  includeFromJson: true,
  includeToJson: true,
)
```

`name` 修改私有实现基名；两个 JSON 方向可以分别关闭。

### `@DataforgeDefault`

redirecting factory 参数不能直接声明默认值，应使用编译期 metadata：

```dart
factory Page({
  @DataforgeDefault(1) int number,
  @DataforgeDefault(<String>[]) List<String> labels,
}) = _Page;
```

resolved frontend 会验证常量可赋值，并能在不丢失语义的情况下重新输出。

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

`ignore: true` 会同时排除两个 JSON 方向。被忽略的 required 字段仍必须有构造默认值。

## Strict JSON

生成 codec 不会在无关运行时类型间做宽松转换。它会验证 required、nullability、
unknown key、alias 冲突、解码后重复 key 与自定义 witness 输出。失败通过
`DataforgeDecodeException` 或 `DataforgeEncodeException` 报告稳定 `DFJ` code 和
JSONPath。

`DateTime` 统一编码为 UTC ISO-8601 文本。Record 支持递归非 JSON 值语义；Record
子树参与 JSON 时必须提供 exact `DataforgeType<RecordShape>` witness，否则生成期返回
DF1006。

## 泛型与自定义值

依赖类型参数的行为或不受支持的自定义叶节点必须提供显式 `DataforgeType<T>` witness：

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

自定义 witness 是值契约的一部分。它的 identity 树以及
freeze/equality/hash/codec 行为必须在整个生命周期内保持不可变；`freeze` 必须隔离
可变输入，equality 与 hash 必须一致。

## 独立 CLI

`dataforge_cli` 提供独立的 resolved 适配器：

```bash
dataforge generate .
dataforge check .
```

两个适配器使用同一 resolved facade 与 renderer。代表性 fixture 已校验字节一致性，
但完整的 GA 类型/平台一致性矩阵尚未完成。

## 排错

1. 在最近的 package root 运行 `dart pub get`。
2. 检查 `part`、`_$Model`、`_Model` 与私有基类构造器名称是否完全匹配。
3. 使用 `@DataforgeDefault`，不要给 redirecting factory 参数直接写默认值。
4. 为每棵依赖类型参数的语义子树提供唯一兼容 witness。
5. 优先修复第一条带源码位置的 `DF` 诊断；后续错误通常是同一声明问题的结果。

预览边界见 [1.0 RFC](https://github.com/lwj1994/dataforge/blob/main/docs/1.0/RFC.md)
与[支持矩阵](https://github.com/lwj1994/dataforge/blob/main/docs/1.0/SUPPORT_MATRIX.md)。
