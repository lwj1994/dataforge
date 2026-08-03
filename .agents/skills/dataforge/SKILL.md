---
name: dataforge
description: 指导用户在 Dataforge v1 项目中完成安装、abstract final 模型声明、build_runner 或 resolved CLI 代码生成、深度不可变值语义、strict JSON、泛型 witness 与故障排查。只要用户提到 Dataforge、@Dataforge、copyWith、fromJson/toJson、.data.dart、CLI、build_runner 或生成报错，都应主动使用本技能。
---

# Dataforge v1 Usage

用于回答和执行 Dataforge v1 的使用与仓库维护任务。

## 当前版本边界

- `1.0.0-dev.0` 是预览版本，不是 1.0 GA。
- 只支持 `abstract final` factory 声明和生成的 `final` implementation。
- build_runner 与实验性 resolved CLI 共享 generation facade 和 renderer。
- CLI 提供显式 `dataforge generate [path]` 与严格只读的
  `dataforge check [path]`。
- 已有代表性 fixture 的双前端字节一致性测试；完整类型/平台 GA 矩阵尚未完成。
- API、诊断和输出格式仍可能在后续 dev/beta 版本中改变。

若仓库实现或版本变化，先以 README、CHANGELOG、CLI help 和测试重新核实。

## 文档优先原则

Dataforge 不是广泛通用知识。触发本技能后，必须先读取
`references/README_INDEX.md`，再完整读取与问题直接相关的 README。

最少读取策略：

- 常规使用：`references/root_README.md`。
- CLI：`references/cli_README.md`；中文用户优先
  `references/cli_README_ZH.md`。
- build_runner、注解与生成格式：`references/generator_README.md`；中文用户优先
  `references/generator_README_ZH.md`。
- 基础包或架构：`references/dataforge_base_README.md`。
- 跨模块、版本或语义审计：读取全部 README，并读取 `docs/1.0/RFC.md` 与
  `docs/1.0/SUPPORT_MATRIX.md`。

## 前端选择

两种前端使用同一 v1 模型声明：

1. 项目已有 build_runner 工作流：使用 `dart run build_runner build/watch`。
2. 需要独立命令或 CI 漂移检查：使用 `dataforge generate` / `dataforge check`。

不能以“更快”为由推荐任一前端；当前没有公开的跨平台性能基准。说明选择依据时只谈
工作流、no-edit/check 和工具链集成。

## 最小模板

### 依赖

```yaml
dependencies:
  dataforge_annotation: ^1.0.0-dev.0

dev_dependencies:
  build_runner: ^2.4.13
  dataforge: ^1.0.0-dev.0
```

四个发布包统一要求 Dart 3.9 或更高版本。业务项目中的 Dataforge 包必须解析到同一
预览版本。

### 模型

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

关键约束：

- 公开类必须是 `abstract final`，生成实现必须是 `final`。
- 值属性来自 unnamed redirecting factory 参数，不重复声明实例字段。
- mixin 名为 `_$ClassName`，redirect target 为 `_ClassName`。
- 需要 `const ClassName._();` 供生成实现继承；公开 factory 默认不是 const。
- redirecting factory 默认值使用 `@DataforgeDefault(value)`。
- JSON 输入使用 `Map<String, Object?>`，默认 strict，不做字符串/数字隐式转换。
- 生成器不会插入 `part`、mixin、factory 或修改用户源码。

### 生成

```bash
dart run build_runner build
```

或：

```bash
dart pub global activate dataforge_cli 1.0.0-dev.0
dataforge generate .
dataforge check .
```

显式 CLI generate 在内存中 resolve、生成、格式化和 overlay 验证，再通过 lock、
journal 和逐文件原子替换提交。`check` 只比较字节，不创建 lock、恢复 journal 或写文件；
输出漂移或存在待恢复 journal 时退出 4。

## 深度不可变和值语义

- List/Set/Map 会在所有公开输入边界复制并递归冻结。
- 任意深度嵌套集合和 Record 都沿完整类型树处理。
- equality/hash 与 freeze 使用同一完整语义树和叶节点 witness。
- 已冻结且 witness-compatible 的内部子树可以共享；外部 replacement 必须先冻结。
- witness equality 下重复的 Set 元素或 Map key 会报错，不会静默丢失。
- Record 默认只有非 JSON 值语义；参与 JSON 的 Record 子树需要 exact witness，
  否则生成期返回 DF1006。

## 泛型与自定义类型

行为依赖 `T` 时必须提供 `DataforgeType<T>` witness：

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

自定义 witness 的实例行为、identity 与子 witness 树必须生命周期内语义不可变；
`freeze` 必须隔离可变输入，`equals`/`hash` 必须一致，codec 必须遵守 JSON domain。
内置和生成 witness 按完整 identity tree 兼容，自定义 witness 默认按对象 identity。
自定义 composite witness 若要让同一语义树跨不同协变 Dart 实例化兼容，还应实现
`DataforgeTypeErasedEquality` 并递归使用双方的子 witness。

## Strict JSON

排错时先按异常的稳定 `DFJ` code 与 JSONPath 检查：

- required/null/default；
- unknown key；
- 主 key 与 alternate name 冲突；
- Set 元素解码后在 witness equality 下重复；
- Map 原始或解码后重复 key；
- 非有限 double；
- 循环 List/Map 输入；
- 自定义 witness 返回契约外类型。

不要建议恢复全局宽松转换。自定义值应在进入模型前正规化，或通过 exact witness 明确
承担整棵语义子树。

## 故障快速检查

1. 是否在最近 package root 运行过 `dart pub get`。
2. `part 'xxx.data.dart'` 是否存在且与源文件匹配。
3. 类是否为 `abstract final class`，且 mixin/target 分别是 `_$Model`/`_Model`。
4. 是否有私有基类构造器和唯一 unnamed redirecting factory。
5. `fromJson` 是否使用 `Map<String, Object?>` 并重定向到 `_Model.fromJson`。
6. 默认值是否使用 `@DataforgeDefault`。
7. 每棵依赖类型参数或自定义值的子树是否有唯一兼容 witness。
8. annotation import 的 show/hide 是否隐藏了生成 part 需要的 runtime API。
9. 优先修复第一条带源码位置的 `DF` diagnostic。
10. `check` 退出 4 时先运行显式 generate，再审阅生成 diff。

## 仓库维护规则

本仓库目录：

- `annotation/`：v1 annotation、runtime witness 与 strict JSON error。
- `dataforge_base/`：resolved facade、diagnostic 与内部 renderer。
- `generator/`：build_runner adapter。
- `cli/`：独立 v1 generate/check adapter 与生成事务。

维护时：

- 在四个 package 内分别运行 pub get、format、analyze 和 test。
- 修改公开语义时同步 README、CHANGELOG、RFC、支持矩阵与 clean-consumer 测试。
- 版本按 annotation → dataforge_base → dataforge → dataforge_cli 顺序发布。
- dev 版本不得宣称未通过的 GA 门禁已经完成。
- `generate` 与 `check` 都不能修改模型源码。
- raw schema/renderer 不得公开；adapter 只能通过 resolved generation facade 进入。
- 所有 Dart 源码注释和 API doc comments 使用英文。

## 输出约定

回答时先说明版本和前端，例如：

```markdown
模式：1.0.0-dev.0 + build_runner（或 resolved CLI）预览

步骤：
1. 对齐依赖版本
2. 使用 abstract final factory 声明
3. 运行生成与验证

限制：
- 当前仍是 preview；完整 GA 类型/平台矩阵尚未完成
```

给出可复制的依赖、模型和命令。明确区分“当前已实现”与“1.0 GA 目标”。
