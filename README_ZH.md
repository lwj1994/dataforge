# Dart Dataforge 数据锻造厂

[![Pub Version](https://img.shields.io/pub/v/dataforge)](https://pub.dev/packages/dataforge)
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
dart pub global activate --source git https://github.com/lwj1994/dataforge
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
  chainedCopyWith: false,   // 禁用链式 copyWith（默认：true）
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

## 🔗 高级 CopyWith 功能

Dataforge 提供多种 copyWith 模式，适应不同的编码风格和使用场景：

### 1. 传统 CopyWith（默认）

```dart
@Dataforge()
class User with _User {
  @override
  final String name;
  @override
  final int age;
  @override
  final String? email;

  const User({required this.name, required this.age, this.email});
}

// 使用方式
final user = User(name: '张三', age: 25, email: 'zhangsan@example.com');
final updated = user.copyWith(name: '李四', age: 30);
```

### 2. 链式 CopyWith（流畅 API）

启用链式 copyWith 获得更流畅的 API 体验：

```dart
@Dataforge(chainedCopyWith: true)
class User with _User {
  @override
  final String name;
  @override
  final int age;
  @override
  final String? email;

  const User({required this.name, required this.age, this.email});
}

// 链式更新
final updated1 = user.copyWith.name('李四').build();
final updated2 = user.copyWith.name('李四').age(30).build();
final updated3 = user.copyWith.email(null).build();

// 传统 copyWith 仍然可用
final updated4 = user.copyWith(name: '李四', age: 30);
```

### 3. 嵌套对象更新

对于复杂的嵌套对象，使用传统的 copyWith 方法进行更新：

```dart
@Dataforge()
class Address with _Address {
  @override
  final String street;
  @override
  final String city;
  @override
  final String zipCode;

  const Address({required this.street, required this.city, required this.zipCode});
}

@Dataforge()
class Profile with _Profile {
  @override
  final User user;
  @override
  final Address address;
  @override
  final List<String> tags;

  const Profile({required this.user, required this.address, required this.tags});
}

// 使用传统 copyWith 方法进行嵌套更新
final profile = Profile(
  user: User(name: '张三', age: 25),
  address: Address(street: '中山路123号', city: '北京', zipCode: '100001'),
  tags: ['开发者'],
);

// 更新嵌套的用户
final updated1 = profile.copyWith(
  user: profile.user.copyWith(name: '李四'),
);

// 更新嵌套的地址
final updated2 = profile.copyWith(
  address: profile.address.copyWith(street: '长安街999号', city: '上海'),
);

// 多重嵌套更新
final updated3 = profile.copyWith(
  user: profile.user.copyWith(name: '王五', age: 35),
  address: profile.address.copyWith(city: '深圳'),
  tags: ['高级开发者', '团队负责人'],
);
```

### 4. 链式 CopyWith 与嵌套对象

当使用链式 copyWith 时，仍然可以更新嵌套对象：

```dart
@Dataforge(chainedCopyWith: true)
class Profile with _Profile {
  // ... 与上面相同
}

// 链式更新嵌套对象
final updated1 = profile.copyWith
  .user(profile.user.copyWith(name: '李四'))
  .build();
  
final updated2 = profile.copyWith
  .address(profile.address.copyWith(city: '上海'))
  .build();
```

### 5. 混合使用模式

```dart
// 简单情况使用传统 copyWith
final simple = user.copyWith(name: '简单更新');

// 流畅 API 使用链式
final fluent = user.copyWith.name('流畅').age(25).build();

// 嵌套对象更新
final nested = profile.copyWith(
  user: User(name: '新用户', age: 40),  // 替换整个对象
  tags: ['新标签']                     // 更新列表
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