# Dataforge CLI

Dataforge v1 值对象的独立 resolved 代码生成适配器。

> `1.0.0-dev.0` 是预览版本，不是 1.0 GA。CLI 只支持 v1 `abstract final`
> factory 声明，并且不会编辑模型源码。

## 安装

```bash
dart pub global activate dataforge_cli 1.0.0-dev.0
```

业务 package 需要同版本运行时注解包：

```yaml
dependencies:
  dataforge_annotation: ^1.0.0-dev.0
```

最低要求 Dart 3.9。生成前先在每个 package 运行 `dart pub get`，让 resolved frontend
能够读取 package configuration。

## 命令

生成一个 package 或单个 Dart 源文件：

```bash
dataforge generate .
dataforge generate lib/models/user.dart
```

只检查已提交输出，不写文件：

```bash
dataforge check .
```

输出缺失、漂移或存在需要恢复的未完成 generation journal 时，`check` 退出 4。
遇到 journal 时先运行一次显式 `generate`，再重新执行 `check`。

## 声明

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

CLI 与 build_runner 使用同一声明契约：`part`、mixin、实现名和 redirecting factory
形状必须准确。源码缺失或非法时返回诊断；CLI 不会代替用户插入或改写声明。

## 事务模型

普通生成会：

1. 在内存中 resolve 全部候选 library 并构建 schema；
2. 在内存中渲染并格式化全部输出；
3. 通过 Analyzer overlay 验证完整生成 library；
4. 按最近的 Dart package root 对输出分组；
5. 在对应 package 的进程锁内复验源码、package configuration 与 pubspec 快照；
6. 通过同目录临时文件和该 package 的 recovery journal 安装输出。

journal 会在替换目标前落盘。进程中断后，下一次普通 generate 会先回滚未完成事务。
若目标含未知内容、路径变成链接或 journal 非法，CLI 会保留现场并报错，不会猜测覆盖。

同一个 package 内的多文件事务可以按组恢复，但不承诺所有文件在操作系统层同一时刻
可见。monorepo 的不同 package 使用独立事务，因此从外层或嵌套 package 启动时，凡是
可能修改同一目标，都一定使用同一份 lock 与 journal。

## 退出状态

| Code | 含义 |
| --- | --- |
| 0 | 生成或检查成功 |
| 2 | 命令参数非法 |
| 3 | 生成或声明失败 |
| 4 | 输出漂移或其他安全前置条件失败 |
| 5 | 文件系统或事务 I/O 失败 |
| 70 | 未预期内部失败 |

## CI

如果项目选择提交 `.data.dart`，可加入：

```bash
dataforge check .
```

该命令严格只读：不会创建 lock、恢复 journal，也不会修改源码或生成文件。

## 与 build_runner 的关系

CLI 与 `dataforge` build_runner 适配器使用同一 resolved generation facade 和
renderer。代表性 fixture 已校验逐字节一致性，但当前预览尚未宣称覆盖所有类型和平台的
完整 GA 一致性矩阵。

## 排错

- **找不到 package configuration：** 在最近的 package root 运行 `dart pub get`。
- **DF1001 声明错误：** 检查 `abstract final`、`_$Model`、`_Model`、私有基类
  构造器、redirecting factory 与 `.data.dart` part URI。
- **check 退出 4：** 运行普通生成并审阅 diff。
- **拒绝恢复：** 保留错误中列出的文件和 journal；CLI 不会自动猜测或删除未知内容。

注解、strict JSON 与 witness 语义见
[generator 文档](https://github.com/lwj1994/dataforge/tree/main/generator)。
