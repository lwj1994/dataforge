# Dataforge Generator

强大的 Dart 代码生成器，用于创建不可变数据类、JSON 序列化逻辑和深度复制方法。与 `dataforge_annotation` 无缝协作。

## 目录

- [为什么选择 Dataforge？](#为什么选择-dataforge)
- [功能特性](#功能特性)
- [安装](#安装)
- [使用方法](#使用方法)
- [功能深度解析](#功能深度解析)
  - [不可变操作](#不可变操作)
  - [深度复制（链式 CopyWith）](#深度复制链式-copywith)
  - [JSON 序列化](#json-序列化)
  - [注解说明](#注解说明)
- [CLI 工具](#cli-工具更快的替代方案)
- [高级特性](#高级特性)
  - [自定义类型转换器](#自定义类型转换器)
  - [自定义 fromJson/toJson 函数](#自定义-fromjsontojson-函数)
  - [泛型类型](#泛型类型)
  - [空安全与默认值](#空安全与默认值)
  - [集合处理](#集合处理)
- [生成的代码](#生成的代码)
- [重要说明](#重要说明)
- [故障排除](#故障排除)
- [迁移指南](#迁移指南)

## 为什么选择 Dataforge？

- **双模式支持**：完美支持 **build_runner**（标准 Dart 工作流）和高性能 **CLI** 工具，通过并行处理实现即时代码生成。
- **类型安全的数据类**：自动生成 `copyWith`、`operator ==`、`hashCode` 和 `toString`，构建具有完整空安全支持的健壮不可变模型。
- **智能 JSON 转换**：
    - **安全类型转换**：优雅处理类型不匹配（例如：自动将字符串 `"123"` 转换为 `int`，或将 `int` 转换为 `String`），使用内置的 `SafeCasteUtil`。
    - **灵活的数据提取**：支持 `readValue` 自定义键提取逻辑、`alternateNames` 兼容旧版 API，以及针对复杂类型的自定义 `JsonConverter`。
    - **自动类型处理**：内置 `DateTime`（时间戳/ISO-8601）和 `Enum` 类型转换器，可配置行为。
- **深度不可变更新**：业界领先的链式 `copyWith` 语法（如 `user.copyWith.$address.city('NY')`），轻松实现嵌套状态管理，无需冗长的样板代码。
- **生产就绪**：轻松处理泛型、集合（List/Set/Map）、循环依赖检测和复杂嵌套结构。

| 包名 | Pub |
|---------|-----|
| [dataforge_annotation](https://pub.dev/packages/dataforge_annotation) | [![pub package](https://img.shields.io/pub/v/dataforge_annotation.svg)](https://pub.dev/packages/dataforge_annotation) |
| [dataforge_base](https://pub.dev/packages/dataforge_base) | [![pub package](https://img.shields.io/pub/v/dataforge_base.svg)](https://pub.dev/packages/dataforge_base) |
| [dataforge_cli](https://pub.dev/packages/dataforge_cli) | [![pub package](https://img.shields.io/pub/v/dataforge_cli.svg)](https://pub.dev/packages/dataforge_cli) |
| [dataforge](https://pub.dev/packages/dataforge) | [![pub package](https://img.shields.io/pub/v/dataforge.svg)](https://pub.dev/packages/dataforge) |

## 功能特性

- **不可变数据类**：生成包含 `copyWith`、`operator ==`（使用 `DeepCollectionEquality`）、`hashCode` 和 `toString` 的 `mixin`。
- **JSON 序列化**：全面的 `fromJson` 和 `toJson` 支持，具有自动类型转换和验证。
- **深度复制**：支持链式 `copyWith`（如 `user.copyWith.$address.street("New St")`）用于嵌套的 Dataforge 对象。
- **类型安全**：内置安全类型转换（`SafeCasteUtil`）优雅处理类型不匹配（如 String `"123"` → int `123`，int `42` → String `"42"`）。
- **智能转换器**：自动处理 `DateTime`（时间戳/ISO-8601 字符串）和 `Enum` 类型，内置转换器。
- **泛型支持**：完全支持带类型参数的泛型类型（如 `Result<T>`、`Response<List<User>>`）。
- **集合支持**：处理 `List<T>`、`Set<T>` 和 `Map<K, V>`，具有适当的类型转换和相等性检查。
- **空安全**：完整的空安全支持，包括可空字段和可选值。
- **自定义转换器**：实现 `JsonTypeConverter<T, S>` 或使用内联 `fromJson`/`toJson` 函数处理自定义类型。
- **旧版 API 支持**：使用 `alternateNames` 支持多个 JSON 键名以实现向后兼容。

## 安装

### 选项 1：build_runner（标准方式）

在 `pubspec.yaml` 中添加以下内容：

```yaml
dependencies:
  dataforge_annotation: ^latest_version

dev_dependencies:
  build_runner: ^latest_version
  dataforge: ^latest_version
```

### 选项 2：CLI 工具（推荐，更快的生成速度）

全局安装：

```bash
dart pub global activate dataforge_cli
```

然后仅在项目中添加注解包：

```yaml
dependencies:
  dataforge_annotation: ^latest_version
```

## 使用方法

### 1. 创建数据类

使用 `@Dataforge()` 注解定义类并混入生成的代码。
生成的 mixin 名称遵循 `_${ClassName}` 模式。

**重要**：所有字段必须有 `@override` 注解，mixin 模式才能正常工作。

```dart
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'user.data.dart'; // 1. 添加 part 指令

@Dataforge()
class User with _User { // 2. 添加 mixin
  @override  // 3. 为所有字段添加 @override
  final String name;

  @override
  final int age;

  // 可选：重命名 JSON 键
  @override
  @JsonKey(name: 'user_email')
  final String email;

  User({
    required this.name,
    required this.age,
    required this.email,
  });

  // 4. 添加 fromJson 工厂方法
  factory User.fromJson(Map<String, dynamic> json) => _User.fromJson(json);
}
```

### 2. 运行生成器

运行 `build_runner` 生成代码：

```bash
dart run build_runner build
```

或监听变化：

```bash
dart run build_runner watch
```

## 功能深度解析

### 不可变操作

生成器提供标准的 `copyWith` 方法和值相等性。

```dart
final user = User(name: 'Alice', age: 30, email: 'alice@example.com');
final updated = user.copyWith(age: 31);

print(user == updated); // false
print(user.name == updated.name); // true
```

### 深度复制（链式 CopyWith）

**什么是深度复制？**
深度复制（或"链式 CopyWith"）允许您更新嵌套的不可变结构，而无需冗长的"阶梯式"语法。

**对比：**

*传统方式：*
```dart
final newProfile = profile.copyWith(
  address: profile.address.copyWith(
    street: 'New St',
  ),
);
```

*Dataforge 方式：*
```dart
final newProfile = profile.copyWith.$address.street('New St');
```

此功能**默认启用**。要禁用它（例如，为简单类生成更少的代码），将 `deepCopyWith` 设置为 `false`：

```dart
@Dataforge(deepCopyWith: false)
class User with _User { ... }
```

如果您有嵌套的 Dataforge 对象，可以轻松更新深层嵌套字段，无需手动重建整个树。

```dart
@Dataforge()
class Address with _Address {
  @override
  final String city;

  @override
  final String street;

  Address({required this.city, required this.street});
  factory Address.fromJson(Map<String, dynamic> json) => _Address.fromJson(json);
}

@Dataforge()
class Profile with _Profile {
  @override
  final Address address;

  Profile({required this.address});
  factory Profile.fromJson(Map<String, dynamic> json) => _Profile.fromJson(json);
}

void main() {
  final profile = Profile(address: Address(city: 'NY', street: '5th Ave'));

  // 直接更新嵌套字段！
  final newProfile = profile.copyWith.$address.street('4th Ave');
  print(newProfile.address.street);  // 4th Ave
  print(newProfile.address.city);    // NY（未更改）
}
```

### JSON 序列化

`fromJson` 和 `toJson` 通过智能类型转换自动处理复杂场景。

#### 内置类型处理

- **安全类型转换**：自动尝试解析和转换不匹配的类型：
  - String `"123"` → int `123`
  - int `42` → String `"42"`
  - String `"true"` → bool `true`
  - 对于非空类型，优雅地回退到默认值

- **空安全**：尊重可空（`T?`）和非空（`T`）字段定义，具有适当的验证

- **集合**：处理 `List<T>`、`Set<T>` 和 `Map<K, V>`，具有内部类型转换：
  ```dart
  // JSON: { "scores": ["1", "2", "3"] }
  // Dart: List<int> scores = [1, 2, 3]  // 自动转换
  ```

- **嵌套对象**：自动反序列化 Dataforge 注解的类：
  ```dart
  @Dataforge()
  class Profile with _Profile {
    @override
    final User user;  // 自动调用 User.fromJson()

    @override
    final List<Address> addresses;  // 为每个项调用 Address.fromJson()

    // 构造函数和工厂方法...
  }
  ```

#### DateTime 转换（DefaultDateTimeConverter）

自动处理多种 DateTime 格式：

```dart
// 数字时间戳
fromJson(1737619200000)  // 13 位毫秒 → DateTime
fromJson(1737619200)     // 10 位秒 → DateTime（转换为毫秒）

// ISO-8601 字符串
fromJson("2026-01-23T08:00:00.000Z")  // 标准格式 → DateTime

// 序列化（始终一致）
toJson(dateTime)  // DateTime → 毫秒时间戳字符串
```

**重要**：长度不明确的时间戳（不是 10 或 13 位）将抛出 `FormatException` 以防止错误转换。

#### 枚举转换（DefaultEnumConverter）

枚举自动转换为/从其字符串名称：

```dart
enum Status { pending, active, completed }

@Dataforge()
class Task with _Task {
  @override
  final Status status;  // 自动转换

  // 构造函数和工厂方法...
}

// JSON: { "status": "active" }
// Dart: Task(status: Status.active)
```

#### JSON 键特性

**重命名键：**
```dart
@JsonKey(name: 'user_email')
final String email;  // 映射到 JSON 中的 "user_email"
```

**备用名称（旧版 API 支持）：**
```dart
@JsonKey(name: 'product_id', alternateNames: ['id', 'uuid', 'productId'])
final String id;  // 按顺序检查所有键：product_id → id → uuid → productId
```

**忽略字段：**
```dart
@JsonKey(ignore: true)
final String secretCode;  // 从 fromJson 和 toJson 中排除
```

**条件序列化：**
```dart
@JsonKey(includeIfNull: false)
final String? bio;  // 仅在非空时包含在 JSON 中
```

**自定义值提取：**
```dart
Object? customReadValue(Map map, String key) {
  // 从 map 中提取值的自定义逻辑
  return map['nested']?['deep']?[key];
}

@JsonKey(readValue: customReadValue)
final String value;
```

**优先级顺序** 用于字段反序列化：
1. `fromJson` 函数（最高优先级）
2. `converter`（JsonTypeConverter）
3. 自动匹配的转换器（DateTime、Enum）
4. 安全类型转换（SafeCasteUtil）
5. 直接赋值（最低优先级）

### 注解说明

#### @Dataforge

整个类的配置。

| 属性 | 类型 | 默认值 | 说明 |
|----------|------|---------|-------------|
| `name` | String | `""` | 自定义 mixin 名称覆盖（很少需要） |
| `includeFromJson` | bool? | `true` | 生成用于反序列化的 `fromJson` 方法 |
| `includeToJson` | bool? | `true` | 生成用于序列化的 `toJson` 方法 |
| `deepCopyWith` | bool | `true` | 启用链式 copyWith 语法（如 `obj.copyWith.$field.value()`） |

**示例：**
```dart
@Dataforge()  // 所有默认值：fromJson ✓、toJson ✓、deepCopyWith ✓
class User with _User { ... }

@Dataforge(deepCopyWith: false)  // 禁用链式 copyWith
class SimpleModel with _SimpleModel { ... }

@Dataforge(includeFromJson: false, includeToJson: false)  // 无 JSON 方法
class InternalModel with _InternalModel { ... }
```

#### @JsonKey

单个字段的配置。

| 属性 | 类型 | 默认值 | 说明 |
|----------|------|---------|-------------|
| `name` | String | `""` | 自定义 JSON 键名（覆盖字段名） |
| `alternateNames` | List\<String\> | `[]` | 如果主键缺失，检查的备用键 |
| `ignore` | bool | `false` | 完全从 JSON 序列化中排除字段 |
| `includeIfNull` | bool? | `null` | 控制是否在 toJson 中包含 null 值 |
| `readValue` | Function? | `null` | 从 Map 中提取值的自定义函数 |
| `converter` | JsonTypeConverter? | `null` | 自定义类型转换器类实例 |
| `fromJson` | Function? | `null` | 自定义反序列化函数（最高优先级） |
| `toJson` | Function? | `null` | 自定义序列化函数（最高优先级） |

**示例：**
```dart
// 重命名键
@JsonKey(name: 'user_name')
final String name;

// 多个备用名称
@JsonKey(name: 'product_id', alternateNames: ['id', 'uuid'])
final String productId;

// 从 JSON 中排除
@JsonKey(ignore: true)
final String internalField;

// 条件序列化
@JsonKey(includeIfNull: false)
final String? bio;

// 自定义转换器
@JsonKey(converter: PhoneNumberConverter())
final PhoneNumber phone;

// 内联函数（最高优先级）
@JsonKey(fromJson: _parseDate, toJson: _formatDate)
final DateTime createdAt;

// 自定义提取逻辑
@JsonKey(readValue: _extractNestedValue)
final String deepValue;
```

## 默认行为

- **构造函数**：您的类必须实现一个初始化所有 final 字段的构造函数。
- **Part 文件**：生成器在 `.data.dart` 文件中生成属性（可通过 build.yaml 配置，但默认基于构建器为 `.data.dart`）。

## 注解示例

```dart
@Dataforge(deepCopyWith: false)
class Product with _Product {
  @override
  @JsonKey(name: 'product_id', alternateNames: ['id', 'uuid'])
  final String id;

  @override
  @JsonKey(ignore: true)
  final String secretCode;

  @override
  final DateTime createdAt; // 自动处理

  Product({
    required this.id,
    this.secretCode = '',
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) => _Product.fromJson(json);
}
```

## CLI 工具（更快的替代方案）

要获得更快的代码生成速度，使用 **dataforge CLI** 代替 build_runner：

### 安装

```bash
dart pub global activate dataforge_cli
```

### 使用

```bash
# 为当前目录生成（递归）
dataforge .

# 为特定文件生成
dataforge lib/models/user.dart

# 为特定目录生成
dataforge lib/models

# 调试模式（详细输出和计时指标）
dataforge . --debug
```

### 性能

CLI 工具明显快于 build_runner：
- **并行处理**：具有 CPU 感知并发的多线程文件处理
- **智能过滤**：仅处理带有 `@Dataforge` 注解的文件
- **即时输出**：立即在源文件旁边生成 `.data.dart` 文件

## 高级特性

### 自定义类型转换器

实现 `JsonTypeConverter<T, S>` 以实现自定义序列化逻辑：

```dart
class PhoneNumberConverter extends JsonTypeConverter<PhoneNumber, String> {
  const PhoneNumberConverter();

  @override
  PhoneNumber? fromJson(String? json) {
    if (json == null) return null;
    return PhoneNumber.parse(json);
  }

  @override
  String? toJson(PhoneNumber? object) {
    return object?.toString();
  }
}

@Dataforge()
class Contact with _Contact {
  @override
  final String name;

  @override
  @JsonKey(converter: PhoneNumberConverter())
  final PhoneNumber phone;

  Contact({required this.name, required this.phone});
  factory Contact.fromJson(Map<String, dynamic> json) => _Contact.fromJson(json);
}
```

### 自定义 fromJson/toJson 函数

要实现细粒度控制，使用 `@JsonKey` 的内联函数：

```dart
String customStringFromJson(dynamic value) => 'custom_$value';
String customStringToJson(String value) => value.toUpperCase();

@Dataforge()
class CustomExample with _CustomExample {
  @override
  @JsonKey(fromJson: customStringFromJson, toJson: customStringToJson)
  final String name;

  CustomExample({required this.name});
  factory CustomExample.fromJson(Map<String, dynamic> json) => _CustomExample.fromJson(json);
}
```

### 泛型类型

Dataforge 完全支持泛型类型参数：

```dart
@Dataforge()
class Result<T> with _Result<T> {
  @override
  final T? data;
  @override
  final String? error;
  @override
  final bool success;

  Result({this.data, this.error, required this.success});
  factory Result.fromJson(Map<String, dynamic> json) => _Result.fromJson(json);
}

// 使用：
final userResult = Result<User>.fromJson(json);
final listResult = Result<List<User>>.fromJson(json);
```

### 空安全与默认值

```dart
@Dataforge()
class Config with _Config {
  @override
  final String name;           // 必填字段

  @override
  final String? nickname;      // 可选字段（可以为 null）

  @override
  @JsonKey(includeIfNull: false)
  final String? bio;           // null 时从 JSON 中排除

  @override
  final int count;             // 带默认值的必填字段

  Config({
    required this.name,
    this.nickname,
    this.bio,
    this.count = 0,
  });

  factory Config.fromJson(Map<String, dynamic> json) => _Config.fromJson(json);
}
```

### 集合处理

Dataforge 自动处理 `List<T>`、`Set<T>` 和 `Map<K, V>`，具有适当的类型转换：

```dart
@Dataforge()
class Team with _Team {
  @override
  final List<User> members;           // Dataforge 对象列表

  @override
  final List<String> tags;            // 基本类型列表

  @override
  final Map<String, int> scores;      // 具有基本类型值的映射

  @override
  final Set<String> uniqueIds;        // 基本类型集合

  @override
  final List<int>? optionalScores;    // 可空列表

  Team({
    required this.members,
    required this.tags,
    required this.scores,
    required this.uniqueIds,
    this.optionalScores,
  });

  factory Team.fromJson(Map<String, dynamic> json) => _Team.fromJson(json);
}

// 使用类型转换：
final json = {
  'members': [{'name': 'Alice', 'age': 30}],  // 每个项 → User.fromJson()
  'tags': ['dev', 'frontend'],                 // 直接赋值
  'scores': {'alice': '100', 'bob': 95},       // "100" → 100（类型转换）
  'uniqueIds': ['id1', 'id2', 'id1'],          // 转换为 Set（删除重复项）
};

final team = Team.fromJson(json);
```

**集合特性：**
- 自动类型转换元素（如 `["1", "2"]` → `[1, 2]`）
- 嵌套 Dataforge 对象自动反序列化
- 使用 `DeepCollectionEquality` 的值相等性
- 可选集合的空安全处理
- 从 JSON 数组转换为 Dart `Set<T>`

## 生成的代码

对于每个 `@Dataforge()` 类，生成器创建：

- **Mixin**：包含所有生成方法的 `_ClassName`
- **copyWith()**：带命名参数的传统复制方法
- **copyWith（链式）**：高级嵌套更新语法（当 `deepCopyWith: true` 时）
- **operator ==**：使用 `DeepCollectionEquality` 的集合值相等性
- **hashCode**：使用 `Object.hashAll` 的高效哈希
- **toString()**：可读的字符串表示
- **fromJson()**：具有类型安全的反序列化
- **toJson()**：处理枚举、DateTime 和嵌套对象的序列化

## 重要说明

### 必需模式

1. **@override 注解**：所有字段必须有 `@override` 以适应 mixin 模式：
   ```dart
   @override
   final String name;  // ✓ 正确
   final String name;  // ✗ 缺少 @override
   ```

2. **工厂方法**：必须手动添加 `fromJson` 工厂：
   ```dart
   factory User.fromJson(Map<String, dynamic> json) => _User.fromJson(json);
   ```

3. **Part 指令**：使用 `part` 语句包含生成的文件：
   ```dart
   part 'user.data.dart';
   ```

### 最佳实践

- 使用 `@JsonKey(ignore: true)` 从 JSON 序列化中排除字段
- 使用 `alternateNames` 实现与旧版 API 的向后兼容
- 对简单类使用 `deepCopyWith: false` 以减少生成的代码大小
- 对复杂类型使用自定义转换器（如颜色、自定义对象）
- 避免类之间的循环引用（改用 ID 引用）
- 对于没有嵌套的简单数据类，考虑 `deepCopyWith: false` 以减少代码大小
- 始终为字段添加 `@override` - 这是 mixin 模式所必需的

### 性能提示

- **CLI vs build_runner**：使用 CLI 工具（`dataforge .`）以获得更快的开发周期
- **并行生成**：CLI 自动并行处理文件
- **选择性生成**：仅对需要代码生成的类进行注解
- **调试模式**：使用 `dataforge . --debug` 在大型项目中识别瓶颈

### 与其他包的对比

| 特性 | Dataforge | json_serializable | freezed |
|---------|-----------|-------------------|---------|
| JSON 序列化 | ✅ | ✅ | ✅ |
| 不可变 copyWith | ✅ | ❌ | ✅ |
| 深度/链式 copyWith | ✅ | ❌ | ❌ |
| 安全类型转换 | ✅ | ❌ | ❌ |
| CLI 工具 | ✅ | ❌ | ❌ |
| 联合类型 | ❌ | ❌ | ✅ |
| 模式匹配 | ❌ | ❌ | ✅ |
| Mixin 模式 | ✅ | ❌ | ❌ |
| 代码大小 | 中等 | 小 | 大 |

**何时选择 Dataforge：**
- 需要通过链式 copyWith 进行嵌套不可变更新
- 使用返回不一致类型的不可靠 API
- 希望使用 CLI 工具获得更快的代码生成
- 更喜欢 mixin 模式而不是生成到同一文件

**何时选择替代方案：**
- 需要联合类型 → 使用 `freezed`
- 需要模式匹配 → 使用 `freezed`
- 想要最小的生成代码 → 使用 `json_serializable`
- 已经深度投资于另一个生态系统

## 故障排除

### 常见错误

**错误："Missing @override"**
- 解决方案：为类中的所有字段添加 `@override` 注解

**错误："Ambiguous timestamp length"**
- 解决方案：DateTime 时间戳必须是 10 位（秒）或 13 位（毫秒）

**错误："Circular dependency detected"**
- 解决方案：在一侧使用 `@JsonKey(ignore: true)` 或通过 ID 引用

### 构建配置

在 `build.yaml` 中自定义输出文件扩展名：

```yaml
targets:
  $default:
    builders:
      dataforge:dataforge:
        enabled: true
        options:
          # 此处自定义选项

builders:
  dataforge:
    import: "package:dataforge/builder.dart"
    builder_factories: ["dataforgeBuilder"]
    build_extensions: {".dart": [".data.dart"]}
    auto_apply: dependents
    build_to: source
```

## 迁移指南

### 从 json_serializable 迁移

如果您正在从 `json_serializable` 迁移：

1. 将 `@JsonSerializable()` 替换为 `@Dataforge()`
2. 将 `part 'user.g.dart'` 更改为 `part 'user.data.dart'`
3. 为所有字段添加 `@override`
4. 混入生成的代码：`class User with _User`
5. 更新工厂：`_$UserFromJson(json)` → `_User.fromJson(json)`

### 从 freezed 迁移

如果您正在从 `freezed` 迁移：

1. 将 `@freezed` 替换为 `@Dataforge()`
2. 从抽象类更改为带 mixin 的具体类
3. 使用 `@override` 添加显式字段声明
4. 保持相同的 `copyWith` 和 `fromJson` 模式

## 支持与社区

- **问题**：[GitHub Issues](https://github.com/luwenjie/dataforge/issues)
- **文档**：[pub.dev](https://pub.dev/packages/dataforge)
- **示例**：查看仓库中的 `example/` 目录

## 许可证

本包在 MIT 许可证下发布。详见 LICENSE 文件。
