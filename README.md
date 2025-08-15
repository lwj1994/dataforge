# Dart Data Class Generator

[![Pub Version](https://img.shields.io/pub/v/data_class_gen)](https://pub.dev/packages/data_class_gen)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A high-performance Dart data class code generator that's multiple times faster than `build_runner`.

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
  dataclass_annotation:
    git:
      url: https://github.com/lwj1994/dart_data_class_gen
      ref: main
      path: annotation
```

Install CLI tool:

```bash
dart pub global activate --source git https://github.com/lwj1994/dart_data_class_gen
```

## Quick Start

Create a data class:

```dart
import 'package:data_class_annotation/data_class_annotation.dart';

part 'user.data.dart';

@DataClass(includeFromJson: true, includeToJson: true)
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
data_class_gen .
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

**@DataClass**: Configure code generation
```dart
@DataClass(includeFromJson: true, includeToJson: true)
```

**@JsonKey**: Customize field serialization
```dart
@JsonKey(name: "custom_name")           // Rename field
@JsonKey(ignore: true)                  // Skip field
@JsonKey(alternateNames: ["alt1"])      // Multiple names
@JsonKey(includeIfNull: false)          // Exclude null values from JSON
```

## Supported Types

- Basic: `String`, `int`, `double`, `bool`, optional types
- Collections: `List<T>`, `Set<T>`, `Map<K, V>`
- Complex: Nested objects, custom classes

## Development

```bash
git clone https://github.com/lwj1994/dart_data_class_gen.git
cd dart_data_class_gen
dart pub get
dart test
```