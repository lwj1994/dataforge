# Dart 数据类生成器

[![Pub Version](https://img.shields.io/pub/v/data_class_gen)](https://pub.dev/packages/data_class_gen)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

一个高性能的 Dart 数据类代码生成器，专为替代缓慢的 `build_runner` 而设计。`dart_build_runner` 的速度极其缓慢，特别是在大型项目中。因此，开发了这个脚本来实现快速生成。

## ✨ 功能特性

- 🚀 **闪电般快速**：比 `build_runner` 快数倍
- 🎯 **零配置**：开箱即用，最少设置
- 🔧 **高度可定制**：支持自定义方法名、字段映射等
- 📦 **功能完整**：自动生成 `copyWith`、`==`、`hashCode`、`toJson`、`fromJson`
- 🌟 **智能类型处理**：支持嵌套对象、集合、可选类型等
- 🔄 **JSON 序列化**：完整的 JSON 序列化/反序列化支持，与 `dart:convert` 完美兼容
- 🎨 **注解驱动**：简单注解控制代码生成
- 🌐 **标准兼容**：生成的 `fromJson`/`toJson` 方法与 `jsonEncode`/`jsonDecode` 无缝配合

## 📦 安装

### 1. 添加依赖

首先，在你的 `pubspec.yaml` 中添加 `dataclass_annotation`：

```yaml
dependencies:
  dataclass_annotation:
    git:
      url: https://github.com/lwj1994/dart_data_class_gen
      ref: main
      path: annotation
```

### 2. 安装 CLI 工具

然后，安装 CLI 工具：

```bash
dart pub global activate --source git https://github.com/lwj1994/dart_data_class_gen
```

## 🚀 快速开始

### 1. 创建数据类

```dart
import 'package:data_class_annotation/data_class_annotation.dart';

part 'user.data.dart';

@DataClass(includeFromJson: true, includeToJson: true)
class User with _User {
  @override
  final String name;
  
  @override
  @JsonKey(name: "user_age", alternateNames: ["age"])
  final int age;
  
  @override
  final List<String> hobbies;
  
  @override
  @JsonKey(ignore: true)
  final String? password;

  const User({
    required this.name,
    this.age = 0,
    this.hobbies = const [],
    this.password,
  });
}
```

### 2. 运行代码生成

```bash
# 为当前目录生成
data_class_gen

# 为指定目录生成
data_class_gen --path ./lib/models
```

### 3. 使用生成的代码

```dart
void main() {
  // 创建对象
  final user = User(name: "John", age: 25, hobbies: ["coding", "reading"]);
  
  // 使用 copyWith 创建副本
  final updatedUser = user.copyWith(age: 26);
  
  // JSON 序列化
  final json = user.toJson();
  print(json); // {name: John, user_age: 25, hobbies: [coding, reading]}
  
  // JSON 反序列化
  final userFromJson = User.fromJson(json);
  
  // 对象比较
  print(user == updatedUser); // false
  print(user.hashCode != updatedUser.hashCode); // true
  
  // 与 dart:convert 无缝配合
  final jsonString = jsonEncode(user); // 自动调用 user.toJson()
  final decodedUser = User.fromJson(jsonDecode(jsonString));
}
```

## 📚 详细使用

### DataClass 注解

```dart
@DataClass(
  name: "CustomMixin",        // 自定义 mixin 名称，默认为 _ClassName
  includeFromJson: true,      // 是否生成 fromJson 方法
  includeToJson: true,        // 是否生成 toJson 方法
)
class MyClass with _MyClass {
  // ...
}
```

### JsonKey 注解

```dart
class User with _User {
  // 字段重命名
  @JsonKey(name: "user_name")
  final String name;
  
  // 多个备用字段名
  @JsonKey(alternateNames: ["user_age", "age"])
  final int age;
  
  // 忽略字段（不包含在 JSON 序列化中）
  @JsonKey(ignore: true)
  final String? password;
  
  // 控制null值是否包含在JSON中
  @JsonKey(includeIfNull: false)
  final String? optionalField;
  
  // 自定义读取逻辑（readValue 是函数名字符串）
  @JsonKey(readValue: "parseDate")
  final DateTime createdAt;
  
  static Object? parseDate(Map map, String key) {
    final value = map[key];
    return value is String ? DateTime.parse(value) : value;
  }
}
```

### 全局配置

你可以通过调用 `initialize` 函数来设置全局配置，这会影响所有使用 `@DataClass` 注解但未指定特定参数的类：

```dart
import 'package:data_class_annotation/data_class_annotation.dart';

void main() {
  // 初始化全局配置
  initialize(
    globalConfig: GlobalConfig(
      includeFromJson: true,    // 默认生成 fromJson 方法
      includeToJson: true,      // 默认生成 toJson 方法
    ),
  );
  
  // 注意：代码生成需要使用 CLI 工具，不是通过代码调用
}
```

## 🔧 支持的类型

### 基本类型
- `String`、`int`、`double`、`num`、`bool`
- `DateTime`、`Uri`、`Duration`
- 可选类型：`String?`、`int?` 等
- 带默认值的类型

### 集合类型
- `List<T>`
- `Map<String, dynamic>`、`Map<K, V>`
- 嵌套集合：`List<Map<String, dynamic>>`

### 复杂类型
- 嵌套对象：`User`、`List<User>`
- 自定义类（需要有对应的 fromJson 方法）

### 示例

```dart
@DataClass(includeFromJson: true, includeToJson: true)
class ComplexModel with _ComplexModel {
  @override
  final String name;
  
  @override
  final List<User> users;
  
  @override
  final Map<String, dynamic> metadata;
  
  @override
  final List<Map<String, dynamic>> configs;
  
  @override
  final DateTime createdAt;
  
  @override
  final Uri? website;
  
  const ComplexModel({
    required this.name,
    this.users = const [],
    this.metadata = const {},
    this.configs = const [],
    required this.createdAt,
    this.website,
  });
}
```

## 🎯 生成的代码

对于上面的 `User` 类，将生成以下代码：

```dart
// user.data.dart
// 由数据类生成器生成
// 请勿手动修改

part of 'user.dart';

mixin _User {
  abstract final String name;
  abstract final int age;
  abstract final List<String> hobbies;

  User copyWith({
    String? name,
    int? age,
    List<String>? hobbies,
  }) {
    return User(
      name: name ?? this.name,
      age: age ?? this.age,
      hobbies: hobbies ?? this.hobbies,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! User) return false;
    return name == other.name &&
           age == other.age &&
           hobbies == other.hobbies;
  }

  @override
  int get hashCode => Object.hashAll([name, age, hobbies]);

  Map<String, dynamic> toJson() => {
        'name': name,
        'user_age': age,
        'hobbies': hobbies,
      };

  static User fromJson(Map<String, dynamic> map) {
    return User(
      name: map['name']?.toString() ?? '',
      age: (map['user_age'] ?? map['age']) != null 
          ? int.tryParse((map['user_age'] ?? map['age'])?.toString() ?? '') 
          : null ?? 0,
      hobbies: (map['hobbies'] != null 
          ? (map['hobbies'] as List<dynamic>?)?.map((e) => e.toString()).toList() 
          : null) ?? const [],
    );
  }
}
```

## 🔄 与 build_runner 的对比

| 功能 | dart_data_class_gen | build_runner |
|------|---------------------|---------------|
| 生成速度 | ⚡ 极快 | 🐌 缓慢 |
| 配置复杂度 | ✅ 零配置 | ❌ 复杂 |
| 依赖大小 | ✅ 轻量级 | ❌ 重量级 |
| 增量构建 | ✅ 支持 | ✅ 支持 |
| 自定义能力 | ✅ 高 | ✅ 高 |
| 学习曲线 | ✅ 低 | ❌ 高 |

## 🛠️ 开发

### 本地开发

```bash
# 克隆项目
git clone https://github.com/lwj1994/dart_data_class_gen.git
cd dart_data_class_gen

# 安装依赖
dart pub get

# 运行测试
dart test

# 本地运行
dart run bin/data_class_gen.dart --path ./test
```

### 项目结构

```
dart_data_class_gen/
├── annotation/           # 注解包
│   ├── lib/
│   │   ├── dataclass_annotation.dart
│   │   └── src/
│   └── pubspec.yaml
├── bin/                  # CLI 入口
│   └── data_class_gen.dart
├── lib/                  # 核心库
│   ├── data_class_gen.dart
│   └── src/
│       ├── config_loader.dart
│       ├── model.dart
│       ├── parser.dart
│       ├── type_handlers.dart
│       ├── util.dart
│       └── writer.dart
├── test/                 # 测试文件
│   ├── edge_cases_test.dart
│   ├── error_handling_test.dart
│   ├── integration_test.dart
│   ├── model_test.dart
│   ├── parser_test.dart
│   └── writer_test.dart
└── pubspec.yaml
```

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🤝 贡献

欢迎贡献！请随时提交 Pull Request。

## 📞 支持

如果您遇到任何问题或有功能请求，请在 [GitHub Issues](https://github.com/lwj1994/dart_data_class_gen/issues) 中创建一个 issue。

## 🙏 致谢

感谢所有为这个项目做出贡献的开发者！