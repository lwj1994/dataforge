# Dart Dataforge

[![Pub Version](https://img.shields.io/pub/v/dataforge)](https://pub.dev/packages/dataforge)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A high-performance Dart data class forge that crafts perfect code structures multiple times faster than `build_runner`.

## Features

- ⚡ **Lightning Fast**: Multiple times faster than `build_runner`
- 🎯 **Zero Configuration**: Works out of the box
- 📦 **Complete**: Auto-generates `copyWith`, `==`, `hashCode`, `toJson`, `toString`
- 🔄 **Automatic `fromJson`**: Automatically adds `fromJson` factory method to original file when `includeFromJson` is true
- 🔧 **Flexible**: Supports nested objects, collections, custom field mapping

## Installation

Add dependency to `pubspec.yaml`:

```yaml
dependencies:
  dataforge_annotation:
    git:
      url: https://github.com/lwj1994/dataforge
      ref: main
      path: annotation
```

Install CLI tool:

```bash
dart pub global activate --source git https://github.com/lwj1994/dataforge
```

## Quick Start

Create a data class:

```dart
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'user.data.dart';

@Dataforge(includeFromJson: true, includeToJson: true)
class User with _User {
  @override
  final String name;
  
  @override
  @JsonKey(name: "user_age")
  final int age;
  
  @override
  final List<String> hobbies;

  const User({
    required this.name,
    this.age = 0,
    this.hobbies = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) => _User.fromJson(json);
}
```

Generate code:

```bash
dataforge .
```

Use generated methods:

```dart
final user = User(name: "John", age: 25);
final updated = user.copyWith(age: 26);
final json = user.toJson();
final fromJson = User.fromJson(json);
print(user.toString()); // User(name: John, age: 25, hobbies: [])
```

## Annotations

**@Dataforge**: Configure code generation
```dart
@Dataforge(includeFromJson: true, includeToJson: true)
```

**@JsonKey**: Customize field serialization
```dart
@JsonKey(name: "custom_name")           // Rename field
@JsonKey(ignore: true)                  // Skip field
@JsonKey(alternateNames: ["alt1"])      // Multiple names
@JsonKey(includeIfNull: false)          // Exclude null values from JSON
```

## Backward Compatibility

**⚠️ Migration from data_class_gen**

If you're migrating from the old `data_class_gen` package, the `@DataClass` annotation is still supported but **deprecated**. We recommend migrating to `@Dataforge` for new projects.

**Legacy Support (Deprecated):**
```dart
// ❌ Deprecated - still works but not recommended
@DataClass(includeFromJson: true, includeToJson: true)
class User with _User {
  // ...
}

// ✅ Recommended - use the new annotation
@Dataforge(includeFromJson: true, includeToJson: true)
class User with _User {
  // ...
}
```

**Migration Steps:**
1. Replace `@DataClass` with `@Dataforge`
2. Replace `@dataClass` with `@dataforge`
3. Update import from `data_class_annotation` to `dataforge_annotation`
4. Update CLI command from `data_class_gen` to `dataforge`

**Why migrate?**
- Better naming that reflects the tool's purpose as a "data forge"
- Future features will only be available in `@Dataforge`
- Cleaner, more intuitive API

## Supported Types

- Basic: `String`, `int`, `double`, `bool`, optional types
- Collections: `List<T>`, `Set<T>`, `Map<K, V>`
- Complex: Nested objects, custom classes

## Development

```bash
git clone https://github.com/lwj1994/dataforge.git
cd dataforge
dart pub get
dart test
```