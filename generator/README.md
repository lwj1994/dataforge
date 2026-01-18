# Dataforge Generator

A powerful code generator that produces immutable data classes, JSON serialization logic, and deep copy methods for Dart applications. Designed to work seamlessly with `dataforge_annotation`.

## Features

- **Immutable Data Classes**: Generates `mixin`s with `copyWith`, `operator ==`, `hashCode`, and `toString`.
- **JSON Serialization**: comprehensive `fromJson` and `toJson` support.
- **Deep Copy**: Supports chained `copyWith` (e.g., `user.address.street("New St")`) for nested objects.
- **Type Safety**: Built-in safe casting (`SafeCasteUtil`) handles type mismatches gracefully (e.g., String "123" to int).
- **Smart Converters**: Automatic handling of `DateTime` and `Enum` types.

## Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  dataforge_annotation: ^latest_version

dev_dependencies:
  build_runner: ^latest_version
  dataforge: ^latest_version
```

## Usage

### 1. Create a Data Class

Define your class with the `@Dataforge()` annotation and mix in the generated code.
The generated mixin name follows the pattern `_${ClassName}`.

```dart
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'user.data.dart'; // 1. Add part directive

@Dataforge()
class User with _User { // 2. Add mixin
  final String name;
  final int age;

  // Optional: Rename JSON keys
  @JsonKey(name: 'user_email')
  final String email;

  User({
    required this.name,
    required this.age,
    required this.email,
  });

  // 3. Add factory for fromJson
  factory User.fromJson(Map<String, dynamic> json) => _User.fromJson(json);
}
```

### 2. Run the Generator

Run `build_runner` to generate the code:

```bash
dart run build_runner build
```

or watch for changes:

```bash
dart run build_runner watch
```

## Features Deep Dive

### Immutable Operations

The generator provides a standard `copyWith` method and value equality.

```dart
final user = User(name: 'Alice', age: 30, email: 'alice@example.com');
final updated = user.copyWith(age: 31);

print(user == updated); // false
print(user.name == updated.name); // true
```

### Deep Copy (Chained CopyWith)

**What is it?**
Deep Copy (or "Chained CopyWith") allows you to update nested immutable structures without the verbose "staircase" syntax.

**Comparison:**

*Traditional Way:*
```dart
final newProfile = profile.copyWith(
  address: profile.address.copyWith(
    street: 'New St',
  ),
);
```

*Dataforge Way:*
```dart
final newProfile = profile.copyWith.address.street('New St');
```

This feature is **enabled by default**. To disable it (e.g., to generate less code for simple classes), set `deepCopyWith` to `false`:

```dart
@Dataforge(deepCopyWith: false)
class User with _User { ... }
```

If you have nested Dataforge objects, you can update deeply nested fields easily without manually recreating the entire tree.

```dart
@Dataforge()
class Address with _Address {
  final String city;
  final String street;
  // ... constructor & fromJson
}

@Dataforge()
class Profile with _Profile {
  final Address address;
  // ...
}

void main() {
  final profile = Profile(address: Address(city: 'NY', street: '5th Ave'));

  // Update nested field directly!
  final newProfile = profile.copyWith.address$street('4th Ave');
}
```

### JSON Serialization

`fromJson` and `toJson` handle complex scenarios automatically.

- **Safe Casting**: Automatically attempts to parse Strings to `int`/`double`/`bool` if the API returns mismatching types.
- **Null Safety**: Respected based on your field definitions.
- **Enums**: Automatically converted to/from string values matching the enum name.
- **DateTime**: Automatically converts to/from ISO-8601 strings or milliseconds (depending on implementation, ISO inferred).

### Annotations

#### @Dataforge
Configuration for the entire class.

| Property | Description | Default |
|----------|-------------|---------|
| `includeFromJson` | Generate `fromJson` method | `true` |
| `includeToJson` | Generate `toJson` method | `true` |
| `deepCopyWith` | Enable chained copyWith syntax | `true` |

#### @JsonKey
Configuration for individual fields.

| Property | Description |
|----------|-------------|
| `name` | The JSON key name. Defaults to field name. |
| `alternateNames` | List of other keys to check if the primary key is missing. |
| `ignore` | If `true`, the field is excluded from JSON serialization. |
| `readValue` | Custom function to extract value from Map. |
| `converter` | Custom `JsonConverter` class to use. |

## Defaults

- **Constructors**: Your class must implement a constructor that initializes all final fields.
- **Part File**: The generator produces properties in a `.data.dart` file (configurable via build.yaml, but defaults to `.data.dart` based on builder).

## Example with Annotations

```dart
@Dataforge(deepCopyWith: false)
class Product with _Product {
  @JsonKey(name: 'product_id', alternateNames: ['id', 'uuid'])
  final String id;

  @JsonKey(ignore: true)
  final String secretCode;

  final DateTime createdAt; // Automatically handled

  Product({
    required this.id,
    this.secretCode = '',
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) => _Product.fromJson(json);
}
```