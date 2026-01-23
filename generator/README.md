# Dataforge Generator

A powerful code generator that produces immutable data classes, JSON serialization logic, and deep copy methods for Dart applications. Designed to work seamlessly with `dataforge_annotation`.

## Table of Contents

- [Why Dataforge?](#why-dataforge)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Features Deep Dive](#features-deep-dive)
  - [Immutable Operations](#immutable-operations)
  - [Deep Copy (Chained CopyWith)](#deep-copy-chained-copywith)
  - [JSON Serialization](#json-serialization)
  - [Annotations](#annotations)
- [CLI Tool](#cli-tool-faster-alternative)
- [Advanced Features](#advanced-features)
  - [Custom Type Converters](#custom-type-converters)
  - [Custom fromJson/toJson Functions](#custom-fromjsontojson-functions)
  - [Generic Types](#generic-types)
  - [Null Safety and Default Values](#null-safety-and-default-values)
- [Generated Code](#generated-code)
- [Important Notes](#important-notes)
- [Troubleshooting](#troubleshooting)
- [Migration Guide](#migration-guide)

## Why Dataforge?

- **Dual Mode Support**: Works seamlessly with both **build_runner** (standard Dart workflow) and a high-performance **CLI** tool for instant code generation with parallel processing.
- **Type-Safe Data Classes**: Automatically generates `copyWith`, `operator ==`, `hashCode`, and `toString` for robust immutable models with full null safety support.
- **Smart JSON Conversion**:
    - **Safe Casting**: Gracefully handles type mismatches (e.g., automatically parses a String `"123"` into an `int`, or converts an `int` to `String`) using built-in `SafeCasteUtil`.
    - **Flexible Extraction**: Supports `readValue` for custom key extraction logic, `alternateNames` for legacy API compatibility, and custom `JsonConverter`s for complex types.
    - **Automatic Type Handling**: Built-in converters for `DateTime` (timestamps/ISO-8601) and `Enum` types with configurable behavior.
- **Deep Immutable Updates**: Industry-leading chained `copyWith` syntax (e.g., `user.copyWith.$address.city('NY')`) for effortless nested state management without verbose boilerplate.
- **Production-Ready**: Handles generics, collections (List/Set/Map), circular dependency detection, and complex nested structures with ease.

| Package | Pub |
|---------|-----|
| [dataforge_annotation](https://pub.dev/packages/dataforge_annotation) | [![pub package](https://img.shields.io/pub/v/dataforge_annotation.svg)](https://pub.dev/packages/dataforge_annotation) |
| [dataforge_base](https://pub.dev/packages/dataforge_base) | [![pub package](https://img.shields.io/pub/v/dataforge_base.svg)](https://pub.dev/packages/dataforge_base) |
| [dataforge_cli](https://pub.dev/packages/dataforge_cli) | [![pub package](https://img.shields.io/pub/v/dataforge_cli.svg)](https://pub.dev/packages/dataforge_cli) |
| [dataforge](https://pub.dev/packages/dataforge) | [![pub package](https://img.shields.io/pub/v/dataforge.svg)](https://pub.dev/packages/dataforge) |

## Features

- **Immutable Data Classes**: Generates `mixin`s with `copyWith`, `operator ==` (using `DeepCollectionEquality`), `hashCode`, and `toString`.
- **JSON Serialization**: Comprehensive `fromJson` and `toJson` support with automatic type conversion and validation.
- **Deep Copy**: Supports chained `copyWith` (e.g., `user.copyWith.$address.street("New St")`) for nested Dataforge objects.
- **Type Safety**: Built-in safe casting (`SafeCasteUtil`) handles type mismatches gracefully (e.g., String `"123"` → int `123`, int `42` → String `"42"`).
- **Smart Converters**: Automatic handling of `DateTime` (timestamps/ISO-8601 strings) and `Enum` types with built-in converters.
- **Generic Support**: Full support for generic types with type parameters (e.g., `Result<T>`, `Response<List<User>>`).
- **Collection Support**: Handles `List<T>`, `Set<T>`, and `Map<K, V>` with proper type casting and equality checks.
- **Null Safety**: Complete null safety support with nullable fields and optional values.
- **Custom Converters**: Implement `JsonTypeConverter<T, S>` or use inline `fromJson`/`toJson` functions for custom types.
- **Legacy API Support**: Use `alternateNames` to support multiple JSON key names for backward compatibility.

## Installation

### Option 1: build_runner (Standard)

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  dataforge_annotation: ^latest_version

dev_dependencies:
  build_runner: ^latest_version
  dataforge: ^latest_version
```

### Option 2: CLI Tool (Recommended for faster generation)

Install globally:

```bash
dart pub global activate dataforge_cli
```

Then add only the annotation package to your project:

```yaml
dependencies:
  dataforge_annotation: ^latest_version
```

## Usage

### 1. Create a Data Class

Define your class with the `@Dataforge()` annotation and mix in the generated code.
The generated mixin name follows the pattern `_${ClassName}`.

**Important**: All fields must have the `@override` annotation for the mixin pattern to work correctly.

```dart
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'user.data.dart'; // 1. Add part directive

@Dataforge()
class User with _User { // 2. Add mixin
  @override  // 3. Add @override to all fields
  final String name;

  @override
  final int age;

  // Optional: Rename JSON keys
  @override
  @JsonKey(name: 'user_email')
  final String email;

  User({
    required this.name,
    required this.age,
    required this.email,
  });

  // 4. Add factory for fromJson
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
final newProfile = profile.copyWith.$address.street('New St');
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

  // Update nested field directly!
  final newProfile = profile.copyWith.$address.street('4th Ave');
  print(newProfile.address.street);  // 4th Ave
  print(newProfile.address.city);    // NY (unchanged)
}
```

### JSON Serialization

`fromJson` and `toJson` handle complex scenarios automatically with intelligent type conversion.

#### Built-in Type Handling

- **Safe Casting**: Automatically attempts to parse and convert mismatched types:
  - String `"123"` → int `123`
  - int `42` → String `"42"`
  - String `"true"` → bool `true`
  - Graceful fallback to default values for non-nullable types

- **Null Safety**: Respects nullable (`T?`) and non-nullable (`T`) field definitions with proper validation

- **Collections**: Handles `List<T>`, `Set<T>`, and `Map<K, V>` with inner type casting:
  ```dart
  // JSON: { "scores": ["1", "2", "3"] }
  // Dart: List<int> scores = [1, 2, 3]  // Automatically converted
  ```

- **Nested Objects**: Automatically deserializes Dataforge-annotated classes:
  ```dart
  @Dataforge()
  class Profile with _Profile {
    @override
    final User user;  // Calls User.fromJson() automatically

    @override
    final List<Address> addresses;  // Calls Address.fromJson() for each item

    // Constructor and factory...
  }
  ```

#### DateTime Conversion (DefaultDateTimeConverter)

Automatically handles multiple DateTime formats:

```dart
// Numeric timestamps
fromJson(1737619200000)  // 13-digit milliseconds → DateTime
fromJson(1737619200)     // 10-digit seconds → DateTime (converted to ms)

// ISO-8601 strings
fromJson("2026-01-23T08:00:00.000Z")  // Standard format → DateTime

// Serialization (always consistent)
toJson(dateTime)  // DateTime → milliseconds timestamp string
```

**Important**: Timestamps with ambiguous lengths (not 10 or 13 digits) will throw a `FormatException` to prevent incorrect conversions.

#### Enum Conversion (DefaultEnumConverter)

Enums are automatically converted to/from their string names:

```dart
enum Status { pending, active, completed }

@Dataforge()
class Task with _Task {
  @override
  final Status status;  // Auto-converted

  // Constructor and factory...
}

// JSON: { "status": "active" }
// Dart: Task(status: Status.active)
```

#### JSON Key Features

**Rename Keys:**
```dart
@JsonKey(name: 'user_email')
final String email;  // Maps to "user_email" in JSON
```

**Alternate Names (Legacy API Support):**
```dart
@JsonKey(name: 'product_id', alternateNames: ['id', 'uuid', 'productId'])
final String id;  // Checks all keys in order: product_id → id → uuid → productId
```

**Ignore Fields:**
```dart
@JsonKey(ignore: true)
final String secretCode;  // Excluded from fromJson and toJson
```

**Conditional Serialization:**
```dart
@JsonKey(includeIfNull: false)
final String? bio;  // Only included in JSON when non-null
```

**Custom Value Extraction:**
```dart
Object? customReadValue(Map map, String key) {
  // Custom logic to extract value from map
  return map['nested']?['deep']?[key];
}

@JsonKey(readValue: customReadValue)
final String value;
```

**Priority Order** for field deserialization:
1. `fromJson` function (highest priority)
2. `converter` (JsonTypeConverter)
3. Auto-matched converters (DateTime, Enum)
4. Safe type casting (SafeCasteUtil)
5. Direct assignment (lowest priority)

### Annotations

#### @Dataforge

Configuration for the entire class.

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `name` | String | `""` | Custom mixin name override (rarely needed) |
| `includeFromJson` | bool? | `true` | Generate `fromJson` method for deserialization |
| `includeToJson` | bool? | `true` | Generate `toJson` method for serialization |
| `deepCopyWith` | bool | `true` | Enable chained copyWith syntax (e.g., `obj.copyWith.$field.value()`) |

**Examples:**
```dart
@Dataforge()  // All defaults: fromJson ✓, toJson ✓, deepCopyWith ✓
class User with _User { ... }

@Dataforge(deepCopyWith: false)  // Disable chained copyWith
class SimpleModel with _SimpleModel { ... }

@Dataforge(includeFromJson: false, includeToJson: false)  // No JSON methods
class InternalModel with _InternalModel { ... }
```

#### @JsonKey

Configuration for individual fields.

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `name` | String | `""` | Custom JSON key name (overrides field name) |
| `alternateNames` | List\<String\> | `[]` | Fallback keys to check if primary key is missing |
| `ignore` | bool | `false` | Exclude field from JSON serialization completely |
| `includeIfNull` | bool? | `null` | Control whether null values are included in toJson |
| `readValue` | Function? | `null` | Custom function to extract value from Map |
| `converter` | JsonTypeConverter? | `null` | Custom type converter class instance |
| `fromJson` | Function? | `null` | Custom deserialization function (highest priority) |
| `toJson` | Function? | `null` | Custom serialization function (highest priority) |

**Examples:**
```dart
// Rename key
@JsonKey(name: 'user_name')
final String name;

// Multiple fallback names
@JsonKey(name: 'product_id', alternateNames: ['id', 'uuid'])
final String productId;

// Exclude from JSON
@JsonKey(ignore: true)
final String internalField;

// Conditional serialization
@JsonKey(includeIfNull: false)
final String? bio;

// Custom converter
@JsonKey(converter: PhoneNumberConverter())
final PhoneNumber phone;

// Inline functions (highest priority)
@JsonKey(fromJson: _parseDate, toJson: _formatDate)
final DateTime createdAt;

// Custom extraction logic
@JsonKey(readValue: _extractNestedValue)
final String deepValue;
```

## Defaults

- **Constructors**: Your class must implement a constructor that initializes all final fields.
- **Part File**: The generator produces properties in a `.data.dart` file (configurable via build.yaml, but defaults to `.data.dart` based on builder).

## Example with Annotations

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
  final DateTime createdAt; // Automatically handled

  Product({
    required this.id,
    this.secretCode = '',
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) => _Product.fromJson(json);
}
```

## CLI Tool (Faster Alternative)

For faster code generation, use the **dataforge CLI** instead of build_runner:

### Installation

```bash
dart pub global activate dataforge_cli
```

### Usage

```bash
# Generate for current directory (recursive)
dataforge .

# Generate for specific file
dataforge lib/models/user.dart

# Generate for specific directory
dataforge lib/models

# Debug mode (verbose output with timing metrics)
dataforge . --debug
```

### Performance

The CLI tool is significantly faster than build_runner:
- **Parallel Processing**: Multi-threaded file processing with CPU-aware concurrency
- **Smart Filtering**: Only processes files with `@Dataforge` annotations
- **Instant Output**: Generates `.data.dart` files immediately alongside source files

## Advanced Features

### Custom Type Converters

Implement `JsonTypeConverter<T, S>` for custom serialization logic:

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

### Custom fromJson/toJson Functions

For fine-grained control, use inline functions with `@JsonKey`:

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

### Generic Types

Dataforge supports full generic type parameters:

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

// Usage:
final userResult = Result<User>.fromJson(json);
final listResult = Result<List<User>>.fromJson(json);
```

### Null Safety and Default Values

```dart
@Dataforge()
class Config with _Config {
  @override
  final String name;           // Required field

  @override
  final String? nickname;      // Optional field (can be null)

  @override
  @JsonKey(includeIfNull: false)
  final String? bio;           // Excluded from JSON when null

  @override
  final int count;             // Required with default

  Config({
    required this.name,
    this.nickname,
    this.bio,
    this.count = 0,
  });

  factory Config.fromJson(Map<String, dynamic> json) => _Config.fromJson(json);
}
```

### Collection Handling

Dataforge automatically handles `List<T>`, `Set<T>`, and `Map<K, V>` with proper type casting:

```dart
@Dataforge()
class Team with _Team {
  @override
  final List<User> members;           // List of Dataforge objects

  @override
  final List<String> tags;            // List of primitives

  @override
  final Map<String, int> scores;      // Map with primitive values

  @override
  final Set<String> uniqueIds;        // Set of primitives

  @override
  final List<int>? optionalScores;    // Nullable list

  Team({
    required this.members,
    required this.tags,
    required this.scores,
    required this.uniqueIds,
    this.optionalScores,
  });

  factory Team.fromJson(Map<String, dynamic> json) => _Team.fromJson(json);
}

// Usage with type casting:
final json = {
  'members': [{'name': 'Alice', 'age': 30}],  // Each item → User.fromJson()
  'tags': ['dev', 'frontend'],                 // Direct assignment
  'scores': {'alice': '100', 'bob': 95},       // "100" → 100 (type cast)
  'uniqueIds': ['id1', 'id2', 'id1'],          // Converted to Set (duplicates removed)
};

final team = Team.fromJson(json);
```

**Collection Features:**
- Automatic type casting of elements (e.g., `["1", "2"]` → `[1, 2]`)
- Nested Dataforge objects automatically deserialized
- Value equality using `DeepCollectionEquality`
- Null-safe handling of optional collections
- Conversion from JSON arrays to Dart `Set<T>`

## Generated Code

For each `@Dataforge()` class, the generator creates:

- **Mixin**: `_ClassName` with all generated methods
- **copyWith()**: Traditional copy method with named parameters
- **copyWith (chained)**: Advanced nested update syntax (when `deepCopyWith: true`)
- **operator ==**: Value equality using `DeepCollectionEquality` for collections
- **hashCode**: Efficient hashing with `Object.hashAll`
- **toString()**: Readable string representation
- **fromJson()**: Deserialization with type safety
- **toJson()**: Serialization handling enums, DateTime, and nested objects

## Important Notes

### Required Patterns

1. **@override Annotation**: All fields must have `@override` for the mixin pattern:
   ```dart
   @override
   final String name;  // ✓ Correct
   final String name;  // ✗ Missing @override
   ```

2. **Factory Method**: Must manually add `fromJson` factory:
   ```dart
   factory User.fromJson(Map<String, dynamic> json) => _User.fromJson(json);
   ```

3. **Part Directive**: Include generated file with `part` statement:
   ```dart
   part 'user.data.dart';
   ```

### Best Practices

- Use `@JsonKey(ignore: true)` to exclude fields from JSON serialization
- Use `alternateNames` for backward compatibility with legacy APIs
- Use `deepCopyWith: false` for simple classes to reduce generated code size
- Use custom converters for complex types (e.g., colors, custom objects)
- Avoid circular references between classes (use ID references instead)
- For simple data classes without nesting, consider `deepCopyWith: false` to reduce code size
- Always add `@override` to fields - this is required for the mixin pattern

### Performance Tips

- **CLI vs build_runner**: Use the CLI tool (`dataforge .`) for faster development cycles
- **Parallel Generation**: The CLI automatically processes files in parallel
- **Selective Generation**: Only annotate classes that need code generation
- **Debug Mode**: Use `dataforge . --debug` to identify bottlenecks in large projects

### Comparison with Other Packages

| Feature | Dataforge | json_serializable | freezed |
|---------|-----------|-------------------|---------|
| JSON Serialization | ✅ | ✅ | ✅ |
| Immutable copyWith | ✅ | ❌ | ✅ |
| Deep/Chained copyWith | ✅ | ❌ | ❌ |
| Safe Type Casting | ✅ | ❌ | ❌ |
| CLI Tool | ✅ | ❌ | ❌ |
| Union Types | ❌ | ❌ | ✅ |
| Pattern Matching | ❌ | ❌ | ✅ |
| Mixin Pattern | ✅ | ❌ | ❌ |
| Code Size | Medium | Small | Large |

**When to choose Dataforge:**
- Need nested immutable updates with chained copyWith
- Working with unreliable APIs that return inconsistent types
- Want faster code generation with the CLI tool
- Prefer mixin pattern over code generation into the same file

**When to choose alternatives:**
- Need union types → Use `freezed`
- Need pattern matching → Use `freezed`
- Want minimal generated code → Use `json_serializable`
- Already heavily invested in another ecosystem

## Troubleshooting

### Common Errors

**Error: "Missing @override"**
- Solution: Add `@override` annotation to all fields in the class

**Error: "Ambiguous timestamp length"**
- Solution: DateTime timestamps must be 10 digits (seconds) or 13 digits (milliseconds)

**Error: "Circular dependency detected"**
- Solution: Use `@JsonKey(ignore: true)` on one side or reference by ID instead

### Build Configuration

Customize output file extension in `build.yaml`:

```yaml
targets:
  $default:
    builders:
      dataforge:dataforge:
        enabled: true
        options:
          # Custom options here

builders:
  dataforge:
    import: "package:dataforge/builder.dart"
    builder_factories: ["dataforgeBuilder"]
    build_extensions: {".dart": [".data.dart"]}
    auto_apply: dependents
    build_to: source
```

## Migration Guide

### From json_serializable

If you're migrating from `json_serializable`:

1. Replace `@JsonSerializable()` with `@Dataforge()`
2. Change `part 'user.g.dart'` to `part 'user.data.dart'`
3. Add `@override` to all fields
4. Mix in generated code: `class User with _User`
5. Update factory: `_$UserFromJson(json)` → `_User.fromJson(json)`

### From freezed

If you're migrating from `freezed`:

1. Replace `@freezed` with `@Dataforge()`
2. Change from abstract class to concrete class with mixin
3. Add explicit field declarations with `@override`
4. Keep the same `copyWith` and `fromJson` patterns

## Support and Community

- **Issues**: [GitHub Issues](https://github.com/luwenjie/dataforge/issues)
- **Documentation**: [pub.dev](https://pub.dev/packages/dataforge)
- **Examples**: See `example/` directory in the repository

## License

This package is released under the MIT License. See LICENSE file for details.