---
name: dataforge
description: 指导用户在 dataforge 项目中完成安装、模型声明、代码生成、调试与迁移。只要用户提到 Dataforge 用法、@Dataforge 注解、copyWith、fromJson/toJson、生成 .data.dart、CLI 与 build_runner 取舍、或报错排查，都应主动使用本技能。
---

# Dataforge Usage

用于回答和执行 dataforge 的日常使用问题，重点覆盖：
- 如何在业务项目接入 Dataforge
- 如何写 `@Dataforge()` 数据类
- 如何生成 `.data.dart`
- 如何排查常见错误
- 如何在 CLI 与 `build_runner` 两种模式之间选择

## 文档优先原则（关键）

Dataforge 不是广泛的通用知识。触发本技能后，不要只依赖记忆，必须优先读取 `references/` 下的完整 README，再输出答案或改动建议。

最少读取策略：
- 常规使用问题：先读 `references/root_README.md` 与相关子模块 README
- CLI 问题：读 `references/cli_README.md`（中文用户可优先 `references/cli_README_ZH.md`）
- 生成器/注解细节：读 `references/generator_README.md`（中文可读 `references/generator_README_ZH.md`）
- 基础包问题：读 `references/dataforge_base_README.md`

若用户问题跨模块或你不确定答案，直接读取全部 README，再给结论。

## 文档索引

先看 `references/README_INDEX.md` 再决定读取顺序。

## 适用范围

当用户提到以下任一内容时，优先使用本技能：
- "怎么用 dataforge"
- `@Dataforge`、`@JsonKey`
- `copyWith`、链式深拷贝
- `fromJson` / `toJson`
- `part 'xxx.data.dart'`
- `dataforge .` 或 `dart run build_runner build`
- 代码生成失败、找不到 mixin、`factory ... fromJson` 报错

## 回答流程

1. 先判断用户要用哪种生成模式。
- 若用户追求速度/一次性生成：优先 CLI。
- 若用户已在现有工程里用 `build_runner`：优先保留 `build_runner`。

2. 先从 `references/` 读取相关文档段落，再回答。

3. 给出最小可运行示例（不要只讲概念）。
- 包含 `pubspec.yaml` 依赖
- 包含模型声明
- 包含生成命令

4. 明确关键约束（最容易踩坑的地方）。
- 类必须 `with _ClassName`
- 字段需要 `@override`
- 文件顶部必须 `part 'xxx.data.dart'`
- 需要 `factory Class.fromJson(...) => _Class.fromJson(...)`（当用户需要 fromJson）

5. 给出可直接执行的命令，并按用户工作目录说明。

6. 如果用户遇到报错，先定位到下面“故障快速检查清单”，按顺序排查。

## 快速模板

### 1) 依赖配置

CLI 模式（推荐速度）：
```yaml
dependencies:
  dataforge_annotation: ^latest
```

并安装命令行工具：
```bash
dart pub global activate dataforge_cli
```

`build_runner` 模式：
```yaml
dependencies:
  dataforge_annotation: ^latest

dev_dependencies:
  build_runner: ^latest
  dataforge: ^latest
```

### 2) 数据类模板

```dart
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'user.data.dart';

@Dataforge(includeFromJson: true, includeToJson: true)
class User with _User {
  @override
  final String name;

  @override
  final int age;

  const User({required this.name, required this.age});

  factory User.fromJson(Map<String, dynamic> json) => _User.fromJson(json);
}
```

### 3) 生成命令

CLI：
```bash
dataforge .
# 或
dataforge lib/models/user.dart
```

`build_runner`：
```bash
dart run build_runner build
# 持续监听
dart run build_runner watch
```

## 故障快速检查清单

按这个顺序检查：
1. 是否写了 `part 'xxx.data.dart'`，且文件名匹配。
2. 类是否 `with _ClassName`（大小写必须一致）。
3. 字段是否加了 `@override`。
4. `factory ... fromJson` 是否指向 `_ClassName.fromJson(json)`。
5. 依赖是否装对：CLI 场景不需要强制引入 `build_runner`。
6. 命令是否在正确目录执行（业务项目根目录，而不是 dataforge 仓库内任意目录）。

## 输出约定

默认用这个结构回答用户：

```markdown
模式选择：CLI / build_runner（附一句原因）

步骤：
1. 修改依赖
2. 创建/修正模型
3. 运行生成命令

可直接复制的代码：
- pubspec 片段
- 模型代码
- 命令

排查建议（如有报错）：
- 给出 1~3 条最可能原因和修复方式
```

## 项目内工作提示（本仓库）

本仓库是 Dataforge monorepo，主要目录：
- `annotation/` 注解包
- `dataforge_base/` 基础能力
- `generator/` 生成器
- `cli/` 命令行工具

如果用户是在维护本仓库本身，不是在业务项目接入：
- 优先给出最小改动建议
- 尽量在对应包目录执行测试/命令
- 不要混淆“库开发”和“业务项目使用”两类场景
