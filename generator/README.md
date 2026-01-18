# Dataforge Generator

[![Pub Version](https://img.shields.io/pub/v/dataforge)](https://pub.dev/packages/dataforge)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Pure `build_runner` based code generator** for creating immutable data classes in Dart with `copyWith`, `==`, `hashCode`, `toJson`, `fromJson`, and more.

## 📦 Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  dataforge_annotation: ^0.5.0-dev.0

dev_dependencies:
  build_runner: ^2.4.0
  dataforge: ^0.5.0-dev.0
```

Then run:

```bash
dart pub get
```

## 🚀 Quick Start

### 1. Annotate Your Class

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
  final String? email;

  const User({
    required this.name,
    required this.age,
    this.email,
  });
}
```

### 2. Run Code Generator

```bash
# One-time build
dart run build_runner build

# Watch mode
dart run build_runner watch
```

### 3. Use Generated Code

```dart
final user = User(name: "Alice", age: 30);

// copyWith
final updated = user.copyWith(age: 31);

// JSON
final json = user.toJson();
final fromJson = User.fromJson(json);
```

## 🔧 Annotation Reference

### `@Dataforge`

```dart
@Dataforge(
  includeFromJson: true,
  includeToJson: true,
  deepCopyWith: true, // Enables nested updates like user.copyWith.address.city(...)
)
class MyClass with _MyClass { ... }
```

### `@JsonKey`

Use `@JsonKey` to customize JSON serialization:

```dart
class Product with _Product {
  @JsonKey(name: 'product_id')
  final String id;

  @JsonKey(ignore: true)
  final String? temp;
}
```

## 🔗 Deep CopyWith (Nested Updates)

Access nested fields easily with the `.` syntax (enabled by default):

```dart
final updated = person.copyWith.address.city('New York');
```

## 🎯 Setting Null Values

Explicitly set nullable fields to `null` using the single-field accessor:

```dart
// Sets email to null, distinct from "not provided"
final noEmail = user.copyWith.email(null);
```