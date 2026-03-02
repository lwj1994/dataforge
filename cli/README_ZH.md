# Dart Dataforge 数据锻造厂

[![Pub Version](https://img.shields.io/pub/v/dataforge_cli)](https://pub.dev/packages/dataforge_cli)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

高性能的 Dart 数据类生成器，比 `build_runner` **快数倍**。自动生成完美的数据类，包含 `copyWith`、`==`、`hashCode`、`toJson`、`fromJson` 等方法。

## ✨ 功能特性

- ⚡ **闪电般快速**：比 `build_runner` 快数倍
- 🎯 **零配置**：开箱即用
- 📦 **完整生成**：`copyWith`、`==`、`hashCode`、`toJson`、`fromJson`、`toString`
- 🔗 **链式 CopyWith**：高级嵌套对象更新
- 🔧 **灵活配置**：自定义字段映射、忽略字段、备用名称
- 🌟 **类型安全**：完整的编译时类型检查
- 🚀 **易于使用**：简单注解，最少设置

## 📦 安装

### 1. 添加依赖

```yaml
dependencies:
  dataforge_annotation:
    git:
      url: https://github.com/lwj1994/dataforge
      ref: main
      path: annotation
```

### 2. 安装 CLI 工具

```bash
dart pub global activate dataforge_cli
```

## 🚀 快速开始

### 1. 创建数据类

```dart
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'user.data.dart';

@Dataforge()
class User with _User {
  @override
  final String name;
  
  @override
  final int age;
  
  @override
  final List<String> hobbies;

  const User({
    required this.name,
    this.age = 0,
    this.hobbies = const [],
  });
}
```

### 2. 生成代码

```bash
# 为当前目录生成
dataforge .

# 为指定文件生成
dataforge lib/models/user.dart
```

### 3. 使用生成的方法

```dart
void main() {
  // 创建实例
  final user = User(name: "张三", age: 25, hobbies: ["编程"]);
  
  // 复制并修改
  final updated = user.copyWith(age: 26);
  
  // JSON 序列化
  final json = user.toJson();
  final fromJson = User.fromJson(json);
  
  // 对象比较
  print(user == updated); // false
  print(user.toString()); // User(name: 张三, age: 25, hobbies: [编程])
}
```

## 🔧 配置选项

### @Dataforge 注解

```dart
@Dataforge(
  includeFromJson: true,    // 生成 fromJson 方法（默认：false）
  includeToJson: true,      // 生成 toJson 方法（默认：false）
  deepCopyWith: false,   // 禁用链式 copyWith（默认：true）
)
class MyClass with _MyClass {
  // ...
}
```

### @JsonKey 注解

```dart
class User with _User {
  // 自定义 JSON 字段名
  @JsonKey(name: "user_name")
  final String name;
  
  // 多个可能的字段名
  @JsonKey(alternateNames: ["user_age", "age"])
  final int age;
  
  // 在 JSON 中忽略字段
  @JsonKey(ignore: true)
  final String? password;
  
  // 从 JSON 中排除 null 值
  @JsonKey(includeIfNull: false)
  final String? nickname;
  
  // 自定义值读取
  @JsonKey(readValue: parseDate)
  final DateTime createdAt;
  
  static Object? parseDate(Map map, String key) {
    final value = map[key];
    return value is String ? DateTime.parse(value) : value;
  }
}
```

## 🔗 链式 CopyWith

对于复杂的嵌套对象，启用强大的链式更新：

```dart
@Dataforge(deepCopyWith: true)
class Address with _Address {
  @override
  final String street;
  @override
  final String city;
  @override
  final String zipCode;

  const Address({required this.street, required this.city, required this.zipCode});
}

@Dataforge(deepCopyWith: true)
class Person with _Person {
  @override
  final String name;
  @override
  final int age;
  @override
  final Address address;
  @override
  final Address? workAddress;

  const Person({required this.name, required this.age, required this.address, this.workAddress});
}

@Dataforge(deepCopyWith: true)
class Company with _Company {
  @override
  final String name;
  @override
  final Person ceo;
  @override
  final List<Person> employees;

  const Company({required this.name, required this.ceo, required this.employees});
}
```

### 使用示例

```dart
final company = Company(
  name: '科技公司',
  ceo: Person(
    name: '张三',
    age: 30,
    address: Address(street: '中山路123号', city: '北京', zipCode: '100001'),
  ),
  employees: [],
);

// 简单链式 copyWith
final newCompany1 = company.copyWith.name('新科技公司');

// 嵌套更新
final newCompany2 = company.copyWith.ceoBuilder((ceo) => 
  ceo.copyWith.name('李四')
);

// 多层嵌套更新
final newCompany3 = company.copyWith.ceoBuilder((ceo) => 
  ceo.copyWith.addressBuilder((addr) => 
    addr.copyWith.street('长安街999号')
  )
);

// 复杂多字段更新
final newCompany4 = company.copyWith.ceoBuilder((ceo) => 
  ceo.copyWith
    .name('王五')
    .copyWith.age(35)
    .copyWith.addressBuilder((addr) => 
      addr.copyWith
        .street('天安门大街777号')
        .copyWith.city('上海')
        .copyWith.zipCode('200001')
    )
);
```

## 📋 支持的类型

- **基础类型**：`String`、`int`、`double`、`bool`、`num`
- **日期时间**：`DateTime`、`Duration`
- **集合类型**：`List<T>`、`Set<T>`、`Map<K, V>`
- **可选类型**：`String?`、`int?` 等
- **嵌套对象**：带有 `fromJson` 的自定义类
- **复杂集合**：`List<User>`、`Map<String, User>` 等

## 🔄 从 build_runner 迁移

从 `json_annotation` + `build_runner` 迁移？很简单：

**之前（build_runner）：**
```dart
@JsonSerializable()
class User {
  final String name;
  final int age;
  
  User({required this.name, required this.age});
  
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
```

**现在（Dataforge）：**
```dart
@Dataforge(includeFromJson: true, includeToJson: true)
class User with _User {
  @override
  final String name;
  @override
  final int age;
  
  const User({required this.name, required this.age});
}
```

## 🎯 为什么选择 Dataforge？

| 功能 | Dataforge | build_runner |
|------|-----------|-------------|
| **速度** | ⚡ 快数倍 | 🐌 缓慢 |
| **设置** | ✅ 零配置 | ❌ 复杂设置 |
| **依赖** | ✅ 轻量级 | ❌ 重量级 |
| **生成代码** | ✅ 清晰易读 | ❌ 复杂 |
| **链式 CopyWith** | ✅ 内置支持 | ❌ 不可用 |
| **学习曲线** | ✅ 最小 | ❌ 陡峭 |

## 🛠️ 开发

```bash
# 克隆仓库
git clone https://github.com/lwj1994/dataforge.git
cd dataforge

# 安装依赖
dart pub get

# 运行测试
dart test

# 格式化代码
dart tools/format_project.dart
```

## 📄 许可证

MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🤝 贡献

欢迎贡献！请随时提交 Pull Request。

## 📞 支持

如果您遇到任何问题或有功能请求，请在 [GitHub](https://github.com/lwj1994/dataforge/issues) 上创建 issue。
