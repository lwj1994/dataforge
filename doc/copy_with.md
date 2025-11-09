# DataForge 中的 `copyWith` 功能

DataForge 强化了 Dart 的 `copyWith` 模式，提供了一种更强大、更易读的方式来更新对象，特别是针对深度嵌套的复杂对象。

### 1. 传统 `copyWith`

DataForge 会为每个数据类生成一个标准的 `copyWith` 方法，用于创建对象的浅拷贝并修改指定字段。

**示例:**
```dart
final updatedUser = user.copyWith(age: 31);
```

### 2. 链式 `copyWith` (Fluent API)

为了提供更流畅的 API，DataForge 额外生成了一个 `copyWith` getter。它返回一个辅助类，允许你用链式调用的方式单独更新字段， 并且会强制覆盖, 即使值是 null。

**示例:**
```dart
// 传统方式
// final updatedUser = user.copyWith(name: 'Bob', age: 32);

// DataForge 链式调用
final updatedUser = user.copyWith.name('Bob').copyWith.age(32);
```

### 3. 嵌套对象的 `copyWith` (核心优势)

这是 DataForge `copyWith` 最强大的功能。对于嵌套对象，无需编写冗长的代码来手动更新，DataForge 会自动处理。

**传统方式的痛点:**
```dart
final updatedCompany = company.copyWith(
  address: company.address.copyWith(
    city: 'New City',
  ),
);
```

**DataForge 的解决方案:**

DataForge 会为嵌套字段生成 特殊 getter，让你可以用一行代码完成深层更新。

**示例:**
```dart
// 一行代码更新嵌套对象的 city 字段
final updatedCompany = company.copyWith.headquarters$zipCode('90210');
```

**工作原理:** `address_city` getter 返回一个函数，该函数接收新值，内部调用 `address.copyWith(city: x)` 创建新的 `Address` 实例，最后再调用 `company.copyWith(company: x)` 完成整个对象的更新。这种机制保证了类型安全和代码的高度可读性。