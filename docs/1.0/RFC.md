# Dataforge 1.0 值对象语义 RFC

状态：`1.0.0-dev.0` 实现预览

本 RFC 定义 Dataforge 1.0 的唯一模型语义。当前 dev 版本不是 GA；未完成的验证门禁
见[支持矩阵](SUPPORT_MATRIX.md)。

## 1. 目标

Dataforge 1.0 生成可长期作为 Map key、缓存值和状态快照使用的 Dart 值对象：

1. 公开模型不能被继承出新的可变实现。
2. 构造完成后，调用方持有的任何可变集合都不能反向改变模型。
3. freeze、equality 与 hash 必须沿同一完整类型树执行。
4. 泛型和自定义值不能依赖 `dynamic` 猜测，必须携带明确语义证据。
5. JSON 解码默认严格，失败信息必须稳定且可定位。
6. build_runner 与 CLI 必须共享同一 resolved frontend 和 renderer。
7. CLI 生成不能改写用户源码，写生成物时必须可回滚、可恢复。

以下能力不属于 1.0 目标：union/sealed-union API、Dart macro adapter、运行时
reflection、任意循环对象图以及对未知可变类型的自动信任。

## 2. 标准声明

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

声明包含以下不可分割的约束：

- 模型是 `abstract final class`。
- 值属性仅来自一个 unnamed redirecting factory 的参数。
- 生成 mixin 名为 `_$User`，生成实现基名为 `_User`。
- 私有 `const User._();` 只用于生成实现调用，不代表公开 factory 可以 const。
- 生成实现是 `final`，用户不能提供额外 subtype、实现、生成 mixin 或私有 target。
- 启用 JSON decode 时，公开 factory 接受 `Map<String, Object?>` 并重定向到生成目标。
- `part` URI 与输出 `.data.dart` 文件严格匹配。

resolved frontend 会拒绝额外 named constructor、非 `Object` 继承、`implements`、
额外生成目标/mixin/helper 以及对生成私有成员的直接引用。这不是风格限制，而是保证
唯一具体值实现的必要边界。

## 3. 语义流水线

两个适配器只负责取得 resolved Analyzer library 和交付输出：

```text
resolved ClassElement
        │
        ▼
declaration and namespace validation
        │
        ▼
complete semantic type tree + model schema
        │
        ▼
cross-model and witness validation
        │
        ▼
shared renderer
        │
        ▼
formatted .data.dart part
```

raw schema、schema builder 和 renderer 都不是 public API。公开入口必须接收 resolved
element，并返回不可伪造的 generation result。这样调用方不能手工拼装缺少跨模型
arity、namespace、witness 签名或类型树信息的 schema。

## 4. 完整语义类型树

字段的 Dart 顶层类型不足以定义值语义。例如：

```text
Map<String, List<Set<T?>>>
```

必须被解析为包含每一层 Map/List/Set/nullable/T witness 的完整树。每个节点统一提供：

- `freeze(value)`：隔离可变输入；
- `equals(left, right)`：定义值相等；
- `hash(value)`：与 equals 一致；
- `fromJson(json, context)`：严格解码；
- `toJson(value, context)`：严格编码。

生成代码不能只因为顶层是集合就调用通用 deep-equality。容器顺序规则、Map key
语义、模型 companion 以及自定义叶节点都必须来自同一棵树，否则 equality/hash 与
freeze 会产生不同的“值”定义。

## 5. 深度不可变边界

### 5.1 外部输入

所有公开输入边界都必须冻结：

- factory 构造；
- `copyWith` replacement；
- `@DataforgeDefault` 值；
- JSON decode 结果；
- 自定义 witness 返回值。

List、Set 和 Map 会递归复制并通过不可修改集合公开。Record 的 positional/named
子节点同样递归冻结。构造后修改原始集合，模型及其 hash 不得变化。

### 5.2 内部结构共享

已经由兼容语义树冻结的值可以在模型内部共享：

- 无变化的 `copyWith()` 返回原实例；
- 未变化的子树保持 identity；
- replacement 仍必须先冻结，不能直接信任调用方对象；
- 不兼容 witness 冻结出的相同 Dart 实例不能走 identity 快路。

### 5.3 重复值

若 Set 元素或 Map key 在 witness equality 下冻结为重复值，构造必须报错，不得静默
丢失。Map JSON decode 还要分别检查原始 String key 和解码后的语义 key，防止自定义
key witness 掩盖输入歧义。

## 6. Equality 与 hash

必须满足：

- equality 对称、传递；
- 相等值具有相同 hash；
- List 按顺序比较；
- Set 与 Map 不受插入顺序影响；
- nested model 沿生成 companion 递归；
- NaN 在模型值语义中相等并得到稳定 hash，但 JSON 仍拒绝非有限数；
- 泛型实参必须先证明 witness compatibility，再比较字段。

自定义 `DataforgeType<T>` 默认按对象 identity 兼容。实现
`DataforgeTypeIdentity` 后，可用稳定 node id 和有序子 witness 列表描述完整语义树；
该 identity 图必须生命周期内不可变、有限且无环。若自定义 composite witness 需要在
不同协变 Dart 实例化之间比较，还应实现 `DataforgeTypeErasedEquality`，在已证明语义树
兼容后沿自己的完整子 witness 树执行无类型桥接的对称比较。内建 witness 和生成的
model/Record witness 已实现该协议。

## 7. 泛型与 exact witness

依赖类型参数的模型必须显式接收 witness：

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

一个 exact witness 是完整 TypeShape 子树的显式语义边界。它可以覆盖自定义值、
`Object?`/`dynamic` 叶节点、实例化后的泛型模型或包含 Record 的 composite。renderer
不会越过 exact 边界重新猜测其内部 JSON 能力。

自定义 witness 必须保证：

1. 实例行为和 identity 子树生命周期内不变。
2. `freeze` 返回已经隔离可变输入的值。
3. `equals` 与 `hash` 一致。
4. codec 不返回契约外的 null 或非 JSON-domain 值。

## 8. 默认值与 metadata

Dart 不允许 redirecting factory 参数直接写默认值，因此使用编译期常量：

```dart
factory Page({
  @DataforgeDefault(1) int number,
  @DataforgeDefault(<String>[]) List<String> labels,
}) = _Page;
```

前端按 resolved 常量类型检查可赋值性，并只接受能无损输出的值。允许精确的
`int` → `double` 和 enum prefix/alias；拒绝有损数值转换、非有限默认值以及无法证明
冻结语义的对象图。

`JsonKey` 提供 const metadata 配置：`name`、`alternateNames`、`ignore`、
`includeIfNull`。自定义值应在完整 `DataforgeType<T>` 边界处理，或在进入模型前正规化。

## 9. Strict JSON

默认 JSON 契约：

- 不做 String/number/bool 间隐式转换；
- required key 缺失是错误，即使字段 nullable；
- 默认值只在 key 缺失时使用，非法显式值不会回退默认；
- unknown key 默认拒绝；
- 主 key 与 alternate name 同时出现是歧义错误；
- DateTime 输入必须携带 `Z` 或显式 offset，输出统一为 UTC `Z`；
- 非有限 double、循环 List/Map 输入、重复 Set 元素和重复语义 key 被拒绝；
- encode 输出必须属于 JSON domain。

失败通过 `DataforgeDecodeException` / `DataforgeEncodeException` 报告：

- 稳定 `DFJ` code；
- 完整 JSONPath；
- expected/actual type；
- canonical model id 与 schema field。

Record 默认没有统一 wire representation。Record 字段参与任一 JSON 方向时产生
DF1006，除非关闭该方向、ignore 字段或为整棵子树提供 exact witness。

## 10. 生成 API

生成 mixin/实现提供：

- factory 参数对应的只读 getter；
- `copyWith`；
- `operator ==` 与 `hashCode`；
- `toString`；
- 启用方向时的 `fromJson` / `toJson`；
- 泛型模型的 companion witness。

生成的 private helper、实现、frozen constructor、sentinel 与 witness 类都不属于
public API。用户代码只应依赖公开模型、annotation runtime 和生成 mixin 暴露的成员。

## 11. CLI 生成事务

显式 `dataforge generate`：

1. resolve、构建 schema、渲染和格式化全部输出；
2. 用 Analyzer overlay 验证完整 library；
3. 在锁内复验输入快照；
4. journal 先落盘，再逐文件同目录原子替换；
5. 删除 journal 作为提交点，随后清理 backup。

崩溃恢复默认回滚到事务前状态。任何未知用户改写、非法 journal、symlink 或不匹配
hash 都会保留现场并失败，不猜测覆盖。多文件可作为一组恢复，但不承诺在 OS 层同一
时刻可见。

`dataforge check` 严格只读，不创建 lock、不恢复 journal、不改写任何文件；
漂移或待恢复 journal 退出 4。

## 12. 诊断与确定性

semantic core 产生稳定 code、severity、target 和 source location；适配器只负责映射到
build_runner 或 CLI 表现。输入、模型与字段按 canonical identity 排序，确保相同 SDK、
配置和输入得到相同 bytes 与 diagnostic 顺序。

当前 preview 已对代表性 fixture 校验 CLI/build_runner 字节一致性。正式 GA 前仍需
完成支持矩阵中的完整类型、属性、平台和故障注入门禁。
