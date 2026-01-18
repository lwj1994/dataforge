# Dart Dataforge 数据锻造厂

[![Pub Version](https://img.shields.io/pub/v/dataforge)](https://pub.dev/packages/dataforge)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

强大的 Dart 代码生成器，用于创建不可变数据类，支持 `copyWith`、`==`、`hashCode`、`toJson`、`fromJson` 等功能。基于 `build_runner` 构建，与您的 Dart 工作流无缝集成。

## ✨ 功能特性

- 📦 **完整代码生成**：`copyWith`、`==`、`hashCode`、`toJson`、`fromJson`、`toString`
- 🔗 **嵌套 CopyWith**：使用 `$` 分隔符语法更新深层嵌套字段（如 `user$address$city`）
- 🔧 **灵活的 JSON 映射**：自定义字段名、备用名称、自定义转换器
- 🌟 **类型安全**：支持泛型的完整编译时类型检查
- 🎯 **Build Runner 集成**：与现有构建设置无缝配合
- 🚀 **易于使用**：简单注解，最少样板代码

## 📦 安装

在 `pubspec.yaml` 中添加以下依赖：

```yaml
dependencies:
  dataforge_annotation: ^0.3.0

dev_dependencies:
  build_runner: ^2.4.0
  dataforge: ^0.3.0
```

然后运行：

```bash
dart pub get
```

## 🚀 快速开始

### 1. 创建数据类

```dart
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'user.data.dart';

@Dataforge()
class User with _User {
  final String name;
  final int age;
  final List<String> hobbies;

  const User({
    required this.name,
    this.age = 0,
    this.hobbies = const [],
  });
}
```

### 2. 生成代码

运行代码生成器：

```bash
# 一次性生成
dart run build_runner build

# 监听模式（文件更改时自动重新生成）
dart run build_runner watch

# 先清理旧的生成文件
dart run build_runner build --delete-conflicting-outputs
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

**字段说明：**
- `includeFromJson`: 生成 `static MyClass fromJson(Map<String, dynamic> json)`
- `includeToJson`: 生成 `Map<String, dynamic> toJson()`
- `deepCopyWith`: 启用嵌套 Dataforge 类的 `user$name(...)` 语法

### @JsonKey

对字段序列化进行精细控制：

```dart
class Product with _Product {
  @JsonKey(name: 'product_id')        // 自定义 JSON 键名
  final String id;
  
  @JsonKey(alternateNames: ['qty', 'count'])  // fromJson 时尝试多个键名
  final int quantity;
  
  @JsonKey(ignore: true)               // 在 JSON 中忽略此字段
  final String? tempData;
  
  @JsonKey(includeIfNull: false)       // 如果为 null 则在 toJson 中省略
  final String? description;
  
  @JsonKey(readValue: _parseDate)      // fromJson 自定义预处理
  final DateTime createdAt;
  
  @JsonKey(converter: MyConverter())   // 自定义双向转换器
  final CustomType data;
  
  static Object? _parseDate(Map map, String key) {
    final value = map[key];
    return value is String ? DateTime.parse(value) : value;
  }
}
```

**处理优先级 (fromJson):**
1. `readValue` - 首先提取/转换原始 JSON 值
2. `converter.fromJson()` - 自定义类型转换
3. 自动检测 - 内置转换器 (`DateTime`, 枚举等)

**处理优先级 (toJson):**
1. `converter.toJson()` - 自定义序列化
2. `includeIfNull` - 如果为 `false` 且值为 `null` 则省略
3. 自动检测 - 内置转换器 (`DateTime`, 枚举等)
4. 直接值 (基本类型)

**内置转换器：**
- `DefaultDateTimeConverter` - 自动应用于 `DateTime` 字段 (ISO 8601 / 毫秒)
- `DefaultEnumConverter` - 自动应用于枚举字段 (基于名称)

#### 处理优先级

当有多个 JSON 处理选项时，遵循以下优先级顺序：

**序列化和反序列化：**
1. `readValue` - 首先执行以提取/预处理原始 JSON 值（仅用于 fromJson）
2. `converter` - 自定义类型转换器（转换的最高优先级）
3. 自动检测 - DateTime、Enum 和基础类型的默认转换

**重要说明：**
- ✅ `readValue` 仅适用于反序列化（fromJson）并独立工作
- ✅ 枚举类型无需任何配置即自动使用 `DefaultEnumConverter`
- ✅ DateTime 类型无需任何配置即自动使用 `DefaultDateTimeConverter`
- ✅ 使用 `converter` 处理任何自定义序列化/反序列化逻辑


## 🔗 链式 CopyWith (嵌套更新)

当 `deepCopyWith: true` (默认) 时，生成器会使用 `$` 分隔符为嵌套 Dataforge 类创建 **扁平化访问器**：

### 示例

```dart
@Dataforge(deepCopyWith: true)
class Address with _Address {
  final String city;
  final String country;
  
  const Address({required this.city, required this.country});
}

@Dataforge(deepCopyWith: true)
class Person with _Person {
  final String name;
  final Address address;
  
  const Person({required this.name, required this.address});
}
```

对于复杂的嵌套对象，dataforge 提供 **扁平访问器模式（Flat Accessor Pattern）**，使用 `$` 分隔符实现强大的链式更新：

```dart
@Dataforge(deepCopyWith: true)
class Address with _Address {
  final String street;
  final String city;
  final String country;

  const Address({required this.street, required this.city, required this.country});
}

@Dataforge(deepCopyWith: true)
class User with _User {
  final String name;
  final int age;
  final String? email;

  const User({required this.name, required this.age, this.email});
}

@Dataforge(deepCopyWith: true)
class ComplexUser with _ComplexUser {
  final User user;
  final Address address;
  final String nickname;

  const ComplexUser({required this.user, required this.address, required this.nickname});
}
```

### 使用示例

```dart
final complexUser = ComplexUser(
  user: User(name: '张三', age: 30, email: 'zhangsan@example.com'),
  address: Address(street: '中山路123号', city: '北京', country: '中国'),
  nickname: '小张',
);

// ✅ 使用 $ 分隔符直接访问嵌套字段
// 这种语法避免与现有属性名冲突
final updated1 = complexUser.copyWith.user$name('李四');
// 结果：user.name = '李四'，其他字段保持不变

// ✅ 更新深层嵌套字段
final updated2 = complexUser.copyWith.address$city('上海');
// 结果：address.city = '上海'，其他字段保持不变

// ✅ 链式更新多个嵌套字段
final updated3 = complexUser
    .copyWith.user$name('王五')
    .copyWith.user$age(25)
    .copyWith.address$city('广州')
    .copyWith.nickname('小王');
// 结果：一次性更新多个字段

// ✅ 传统 copyWith 仍然可用
final updated4 = complexUser.copyWith(nickname: '阿张');

// ✅ 更新整个嵌套对象
final updated5 = complexUser.copyWith(
  user: User(name: '赵六', age: 40, email: 'zhaoliu@example.com'),
);
```

### 为什么使用 `$` 分隔符？

`$` 分隔符（例如 `user$name`）提供以下优势：

1. **避免命名冲突**：不会与现有属性名（如 `userName`）产生冲突
2. **清晰的层级关系**：明确显示嵌套路径（`user` → `name`）
3. **自动生成**：为所有嵌套的 Dataforge 类自动生成访问器
4. **类型安全**：嵌套更新的完整编译时类型检查

### 🛡️ 空安全 (Null Safety)

如果链中的任何字段是可空的（例如 `Address? address`），生成的代码会优雅地处理它。如果父字段为 `null`，更新将被安全地忽略（保留原始对象不变），而不是抛出运行时错误。

```dart
// 如果 person.address 为 null，此调用将安全地返回原始 person 对象
// 正确处理 null 路径而不会崩溃
final updated = person.copyWith.address$city('New York');
```

## 🎯 设置 Null 值

**单字段访问器模式**的一个关键优势是能够显式地将可空字段设置为 `null`，这在传统的 `copyWith` 中是不可能实现的：

### 传统 CopyWith 的问题

```dart
class User {
  final String name;
  final String? email;  // 可空字段
  
  User copyWith({String? name, String? email}) {
    return User(
      name: name ?? this.name,
      email: email ?? this.email,  // ⚠️ 问题：无法区分"未提供"和"设为 null"
    );
  }
}

final user = User(name: '张三', email: 'zhangsan@example.com');

// 尝试清除 email
final updated = user.copyWith(email: null);
print(updated.email);  // ❌ 仍然是 'zhangsan@example.com'！null 被 ?? 忽略了
```

`??` 运算符无法区分：
- **未提供**（参数省略）→ 保持原值
- **显式为 null**（参数是 `null`）→ 应该设为 `null`

### 解决方案：单字段访问器

Dataforge 生成**单独的访问器方法**，接受确切的字段类型：

```dart
// 生成的代码
class _UserCopyWith<R> {
  R call({String? name, String? email}) {
    final res = User(
      name: name ?? _instance.name,
      email: email ?? _instance.email,  // 传统 copyWith 行为
    );
    return _then != null ? _then!(res) : res as R;
  }
  
  // 单字段访问器 - 接受确切类型并直接赋值
  R email(String? value) {
    final res = User(
      name: _instance.name,
      email: value,  // ✅ 直接赋值 - 可以是 null！
    );
    return _then != null ? _then!(res) : res as R;
  }
}
```

### 使用示例

```dart
@Dataforge()
class User with _User {
  final String name;
  final String? email;
  final int? age;
  
  const User({required this.name, this.email, this.age});
}

final user = User(name: '张三', email: 'zhangsan@example.com', age: 30);

// ✅ 使用单字段访问器清除 email
final noEmail = user.copyWith.email(null);
print(noEmail.email);  // null

// ✅ 清除 age
final noAge = user.copyWith.age(null);
print(noAge.age);  // null

// ✅ 链式更新多个字段，包括设置为 null
final updated = user
    .copyWith.name('李四')
    .copyWith.email(null)
    .copyWith.age(25);
// 结果：User(name: '李四', email: null, age: 25)
```

### 优势

✅ **显式 null 赋值**：使用 `.fieldName(null)` 清除可空字段  
✅ **向后兼容**：传统的 `copyWith(...)` 仍可用于非 null 更新  
✅ **类型安全**：编译器强制执行正确的类型  
✅ **可链式调用**：可以流畅地与其他更新组合  

这种设计优雅地解决了 Dart 长期存在的限制，而无需像 `Optional<T>` 这样的包装类型。

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