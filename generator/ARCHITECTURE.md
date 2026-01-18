# Dataforge Generator 模块

## 概述

该模块实现了基于 `build_runner` 的代码生成器,作为 CLI 工具的替代方案。它复用了 `lib/src` 中的核心逻辑,但适配了 `source_gen` 的 API。

## 目录结构

```
generator/
├── lib/
│   ├── builder.dart                      # Builder 入口点
│   └── src/
│       ├── dataforge.dart      # 主生成器类
│       ├── parser.dart                   # Element 解析器
│       ├── writer.dart                   # 代码生成器
│       └── model.dart                    # 数据模型(从主包复制)
├── test/
│   └── generator_test.dart               # 单元测试
├── build.yaml                            # build_runner 配置
├── pubspec.yaml                          # 包依赖
├── README.md                             # 使用文档
├── CHANGELOG.md                          # 变更日志
└── LICENSE                               # 许可证
```

## 与 CLI 版本的差异

### 相似点
1. 使用相同的数据模型 (`ClassInfo`, `FieldInfo`, etc.)
2. 生成相同的代码结构 (mixin, copyWith, toJson, fromJson, etc.)
3. 支持相同的注解选项 (`@Dataforge`, `@JsonKey`)

### 差异点

| 特性 | CLI 版本 (`lib/src`) | Generator 版本 (`generator/lib/src`) |
|------|---------------------|--------------------------------------|
| **输入源** | AST (analyzer 包的 parseFile) | Element (source_gen 的 ClassElement) |
| **Parser** | 解析文件 AST | 解析 ClassElement |
| **Writer** | 生成文件并写入磁盘,修改原文件 | 只生成代码字符串,由 build_runner 处理文件 |
| **文件操作** | 直接操作文件系统 | 通过 build_runner |
| **性能优化** | 并行处理,批量操作 | 依赖 build_runner 的优化 |
| **枚举检测** | 扫描项目文件 | 简化版本,未完全实现 |

## 核心组件

### 1. DataforgeGenerator (`dataforge.dart`)
- 继承自 `GeneratorForAnnotation<Dataforge>`
- 扫描所有带 `@Dataforge` 注解的类
- 协调 Parser 和 Writer

### 2. GeneratorParser (`parser.dart`)  
- 从 `ClassElement` 中提取类信息
- 解析注解参数 (`@Dataforge`, `@JsonKey`)
- 构建 `ParseResult` 和 `ClassInfo`

### 3. GeneratorWriter (`writer.dart`)
- 生成 mixin 代码
- 生成 copyWith (传统式或链式)
- 生成 toJson/fromJson
- 生成 ==, hashCode, toString

### 4. Model (`model.dart`)
- 从主包复制的数据结构
- `ClassInfo`, `FieldInfo`, `JsonKeyInfo`, etc.

## 使用方式

### 安装
```yaml
dependencies:
  dataforge_annotation: ^0.3.0

dev_dependencies:
  build_runner: ^2.4.0
  dataforge: ^0.3.0
```

### 代码示例
```dart
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'user.g.dart';

@Dataforge()
class User with _$User {
  final String name;
  final int age;

  User({required this.name, required this.age});

  factory User.fromJson(Map<String, dynamic> json) => _$User.fromJson(json);
}
```

### 运行生成
```bash
# 一次性生成
dart run build_runner build

# 持续监听
dart run build_runner watch

# 删除旧文件后生成
dart run build_runner build --delete-conflicting-outputs
```

## 当前限制

1. **枚举自动检测**: 简化实现,未完全实现枚举类型的自动检测
2. **自定义函数**: `@JsonKey` 的 `readValue`, `fromJson`, `toJson` 函数支持有限
3. **文件修改**: 不会自动添加 `with` 子句和 `fromJson` 工厂方法到原文件(需要手动添加)

## 未来改进

1. 完善枚举类型检测
2. 支持更多 `@JsonKey` 的自定义函数
3. 优化代码生成性能
4. 添加更多测试覆盖
5. 支持增量构建优化

## 测试

运行测试:
```bash
cd generator
dart test
```

## 与主项目的关系

- **annotation**: 提供注解定义 (`@Dataforge`, `@JsonKey`)
- **lib/src**: CLI 工具的实现,包含完整的文件处理逻辑
- **generator**: build_runner 版本,复用核心逻辑但简化文件操作

两种方式可以共存,用户可以根据项目需求选择:
- CLI: 更灵活,性能优化更好,适合大型项目
- build_runner: 更标准,与 Dart 生态集成更好,适合标准项目
