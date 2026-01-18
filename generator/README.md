# Dataforge Generator

[![Pub Version](https://img.shields.io/pub/v/dataforge)](https://pub.dev/packages/dataforge)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Pure `build_runner` based code generator** for creating immutable data classes in Dart with `copyWith`, `==`, `hashCode`, `toJson`, `fromJson`, and more. 

Built using **source_gen** and **analyzer**, dataforge seamlessly integrates with the Dart build system to generate boilerplate-free, type-safe data classes.

## 🏗️ Architecture Overview

Dataforge is a **pure build_runner implementation** consisting of three main components:

### Core Components

1. **`DataforgeGenerator`** (`lib/src/dataforge.dart`)
   - Extends `GeneratorForAnnotation<Dataforge>` from `source_gen`
   - Entry point for the build_runner pipeline
   - Coordinates parsing and code generation

2. **`GeneratorParser`** (`lib/src/parser.dart`)
   - Uses Dart **analyzer** API to inspect annotated classes
   - Extracts metadata from `@Dataforge` and `@JsonKey` annotations
   - Parses class structure, fields, generics, and type information

3. **`GeneratorWriter`** (`lib/src/writer.dart`)
   - Code generation engine
   - Writes mixins with `copyWith`, `==`, `hashCode`, `toString`
   - Generates JSON serialization (`toJson`/`fromJson`) if enabled
   - Implements chained copyWith for nested objects

4. **`builder.dart`** (Build integration)
   - Exports `dataforgeBuilder` for `build_runner`
   - Uses `PartBuilder` to generate `.data.dart` part files
   - Configured via `build.yaml`

### Build Configuration

The `build.yaml` file configures the code generator:

```yaml
builders:
  dataforge:
    import: "package:dataforge/builder.dart"
    builder_factories: ["dataforgeBuilder"]
    build_extensions: {".dart": [".data.dart"]}
    auto_apply: dependents
    build_to: source
```

This ensures that for every `.dart` file with a `@Dataforge` annotation, a corresponding `.data.dart` part file is generated.

## ✨ Features

- 📦 **Complete Mixin Generation**: `copyWith`, `==`, `hashCode`, `toJson`, `fromJson`, `toString`
- 🔗 **Nested CopyWith**: Flat accessor pattern with `$` separator (e.g., `user$address$city`)
- 🔧 **Flexible JSON Control**: Custom field names, alternate names, converters, `readValue`
- 🌟 **Type Safe**: Full compile-time checking with generics and nullable types
- 🎯 **Pure Build Runner**: No runtime dependencies, all code generated at build time
- 🧩 **Analyzer-Based**: Leverages Dart analyzer for robust AST inspection
- ⚡ **Incremental Builds**: Only regenerates changed files via `build_runner watch`

## 📦 Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  dataforge_annotation: ^0.4.0  # Runtime annotations

dev_dependencies:
  build_runner: ^2.4.0           # Build system
  dataforge: ^0.4.0              # Code generator
```

Then run:

```bash
dart pub get
```

## 🚀 Quick Start

### Step 1: Annotate Your Class

```dart
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'user.data.dart';  // Part directive for generated code

@Dataforge()
class User with _User {  // Mix in generated mixin
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

### Step 2: Run Code Generator

```bash
# One-time build
dart run build_runner build

# Watch mode (auto-rebuild on changes)
dart run build_runner watch

# Clean and rebuild
dart run build_runner build --delete-conflicting-outputs
```

This generates `user.data.dart` containing the `_User` mixin.

### Step 3: Use Generated Code

```dart
void main() {
  // Create instance
  final user = User(name: "Alice", age: 30, email: "alice@example.com");
  
  // copyWith
  final updated = user.copyWith(age: 31);
  
  // Equality
  print(user == updated); // false
  
  // toString
  print(user); // User(name: Alice, age: 30, email: alice@example.com)
  
  // JSON (if enabled via @Dataforge(includeToJson: true, includeFromJson: true))
  final json = user.toJson();
  final fromJson = User.fromJson(json);
}
```

## 🔧 Annotation Reference

### `@Dataforge`

Controls what code is generated for a class:

```dart
@Dataforge(
  includeFromJson: true,    // Generate static fromJson() method (default: true)
  includeToJson: true,      // Generate toJson() method (default: true)
  deepCopyWith: true,    // Enable nested field accessors (default: true)
)
class MyClass with _MyClass { ... }
```

**Fields:**
- `includeFromJson`: Generates `static MyClass fromJson(Map<String, dynamic> json)`
- `includeToJson`: Generates `Map<String, dynamic> toJson()`
- `deepCopyWith`: Enables `user$name(...)` syntax for nested Dataforge classes

### `@JsonKey`

Fine-grained control over field serialization:

```dart
class Product with _Product {
  @JsonKey(name: 'product_id')        // Custom JSON key
  final String id;
  
  @JsonKey(alternateNames: ['qty', 'count'])  // Try multiple keys on fromJson
  final int quantity;
  
  @JsonKey(ignore: true)               // Skip this field in JSON
  final String? tempData;
  
  @JsonKey(includeIfNull: false)       // Omit if null in toJson
  final String? description;
  
  @JsonKey(readValue: _parseDate)      // Custom pre-processor for fromJson
  final DateTime createdAt;
  
  @JsonKey(converter: MyConverter())   // Custom bi-directional converter
  final CustomType data;
  
  static Object? _parseDate(Map map, String key) {
    final value = map[key];
    return value is String ? DateTime.parse(value) : value;
  }
}
```

**Processing Priority (fromJson):**
1. `readValue` - Extracts/transforms raw JSON value first
2. `converter.fromJson()` - Custom type conversion
3. Auto-detection - Built-in converters for `DateTime`, enums, etc.

**Processing Priority (toJson):**
1. `converter.toJson()` - Custom serialization
2. Auto-detection - Built-in converters for `DateTime`, enums
3. Direct value (for basic types)

**Built-in Converters:**
- `DefaultDateTimeConverter` - Auto-applied to `DateTime` fields (ISO 8601 / milliseconds)
- `DefaultEnumConverter` - Auto-applied to enum fields (name-based)

## 🔗 Chained CopyWith (Nested Updates)

When `deepCopyWith: true` (default), the generator creates **flat accessors** for nested Dataforge classes using `$` separator:

### Example

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

**Generated `copyWith` class includes:**

```dart
class _PersonCopyWith<R> {
  // Regular field accessors
  R name(String value) { ... }
  R address(Address value) { ... }
  
  // Nested accessors (auto-generated for Dataforge fields)
  R address$city(String value) {
    return call(address: _instance.address.copyWith(city: value));
  }
  
  R address$country(String value) {
    return call(address: _instance.address.copyWith(country: value));
  }
}
```

### 🛡️ Null Safety

If any field in the chain is nullable (e.g., `Address? address`), the generated code handles it gracefully. If a parent field is `null`, the update is safely ignored (the original object remains unchanged) instead of throwing a runtime error.

```dart
// If person.address is null, this call safely returns the original person
// correctly handling the null path without crashing.
final updated = person.copyWith.address$city('New York');
```}
```

**Usage:**

```dart
final person = Person(
  name: 'Bob',
  address: Address(city: 'NYC', country: 'USA'),
);

// Update nested field directly
final moved = person.copyWith.address$city('LA');
// Result: Person(name: Bob, address: Address(city: LA, country: USA))

// Chain multiple updates
final updated = person
    .copyWith.name('Alice')
    .copyWith.address$country('Canada');
```

**Why `$` separator?**
- **No naming conflicts**: `user$name` won't clash with a field named `userName`
- **Clear hierarchy**: Explicitly shows nesting level
- **Type-safe**: Compiler verifies nested types
- **Auto-generated**: No manual boilerplate for every nested class

## 🎯 Setting Null Values

One of the key advantages of the **single-field accessor pattern** is the ability to explicitly set nullable fields to `null`, which is impossible with traditional `copyWith`:

### The Problem with Traditional CopyWith

```dart
class User {
  final String name;
  final String? email;  // Nullable field
  
  User copyWith({String? name, String? email}) {
    return User(
      name: name ?? this.name,
      email: email ?? this.email,  // ⚠️ Problem: Can't distinguish "not provided" from "set to null"
    );
  }
}

final user = User(name: 'Alice', email: 'alice@example.com');

// Trying to clear the email
final updated = user.copyWith(email: null);
print(updated.email);  // ❌ Still 'alice@example.com'! The null was ignored by ??
```

The `??` operator cannot distinguish between:
- **Not provided** (parameter omitted) → keep original value
- **Explicitly null** (parameter is `null`) → should set to `null`

### The Solution: Single-Field Accessors

Dataforge generates **individual accessor methods** that accept the exact field type:

```dart
// Generated code
class _UserCopyWith<R> {
  R call({String? name, String? email}) {
    final res = User(
      name: name ?? _instance.name,
      email: email ?? _instance.email,  // Traditional copyWith behavior
    );
    return _then != null ? _then!(res) : res as R;
  }
  
  // Single-field accessor - accepts exact type and assigns directly
  R email(String? value) {
    final res = User(
      name: _instance.name,
      email: value,  // ✅ Direct assignment - accepts null!
    );
    return _then != null ? _then!(res) : res as R;
  }
}
```

### Usage Example

```dart
@Dataforge()
class User with _User {
  final String name;
  final String? email;
  final int? age;
  
  const User({required this.name, this.email, this.age});
}

final user = User(name: 'Bob', email: 'bob@example.com', age: 30);

// ✅ Clear email using single-field accessor
final noEmail = user.copyWith.email(null);
print(noEmail.email);  // null

// ✅ Clear age
final noAge = user.copyWith.age(null);
print(noAge.age);  // null

// ✅ Chain multiple updates including nulls
final updated = user
    .copyWith.name('Alice')
    .copyWith.email(null)
    .copyWith.age(25);
// Result: User(name: 'Alice', email: null, age: 25)
```

### Benefits

✅ **Explicit null assignment**: Use `.fieldName(null)` to clear nullable fields  
✅ **Backwards compatible**: Traditional `copyWith(...)` still works for non-null updates  
✅ **Type-safe**: Compiler enforces correct types  
✅ **Chainable**: Combine with other updates fluently  

This design solves the longstanding Dart limitation elegantly without requiring wrapper types like `Optional<T>`.

## 📋 Type Support

The parser (`GeneratorParser`) automatically detects and handles:

- **Primitives**: `String`, `int`, `double`, `bool`, `num`
- **Date/Time**: `DateTime` (auto-converts via `DefaultDateTimeConverter`)
- **Enums**: Auto-converts via `DefaultEnumConverter` (by name)
- **Collections**: `List<T>`, `Set<T>`, `Map<K, V>` (with type-safe iteration)
- **Nullable**: `String?`, `int?`, etc.
- **Generics**: `Result<T>`, `Container<K, V>` (preserves type parameters)
- **Nested Dataforge**: Classes annotated with `@Dataforge` (enables chained copyWith)

## 🏗️ Build Process Internals

### How It Works

1. **Build Runner** scans for `.dart` files in your project
2. For each file containing `@Dataforge`, **`DataforgeGenerator`** is invoked
3. **`GeneratorParser`** uses the `analyzer` package to:
   - Read the `ClassElement` from the AST
   - Extract all fields, their types, nullability, and annotations
   - Determine if fields are Dataforge classes (for chained copyWith)
   - Parse generic type parameters
4. **`GeneratorWriter`** generates:
   - A mixin with abstract field declarations
   - `copyWith` methods (callable or chained accessor class)
   - `==`, `hashCode`, `toString` implementations
   - `toJson`/`fromJson` if enabled
5. Output is written to a `.data.dart` **part file**
6. You mix the generated mixin into your class via `with _ClassName`

### Generated Code Structure

```dart
// user.data.dart (generated)
part of 'user.dart';

mixin _User {
  abstract final String name;
  abstract final int age;
  
  _UserCopyWith<User> get copyWith => _UserCopyWith<User>._(this);
  
  @override
  bool operator ==(Object other) { ... }
  
  @override
  int get hashCode => Object.hashAll([name, age]);
  
  @override
  String toString() => 'User(name: $name, age: $age)';
  
  Map<String, dynamic> toJson() { ... }
  
  static User fromJson(Map<String, dynamic> json) { ... }
}

class _UserCopyWith<R> {
  final _User _instance;
  final R Function(User)? _then;
  
  R call({String? name, int? age}) { ... }
  R name(String value) { ... }
  R age(int value) { ... }
}
```

## 🔄 Migration from `json_serializable`

Dataforge provides a **superset** of `json_serializable` functionality with added `copyWith` and equality:

### Before (`json_serializable`)

```dart
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String name;
  final int age;
  
  User({required this.name, required this.age});
  
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
  
  // Must manually implement copyWith, ==, hashCode, toString
}
```

### After (Dataforge)

```dart
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'user.data.dart';

@Dataforge()
class User with _User {
  @override
  final String name;
  
  @override
  final int age;
  
  const User({required this.name, required this.age});
  
  // copyWith, ==, hashCode, toString, toJson, fromJson auto-generated!
}
```

**Advantages:**
- ✅ No need to write factory constructors
- ✅ `copyWith` included by default
- ✅ Equality and `toString` for free
- ✅ Chained accessors for nested objects
- ✅ Same `@JsonKey` annotations work

## 🛠️ Development

### Project Structure

```
dataforge/
├── generator/
│   ├── lib/
│   │   ├── builder.dart          # Build_runner entry point
│   │   └── src/
│   │       ├── dataforge.dart    # GeneratorForAnnotation
│   │       ├── parser.dart       # AST parsing logic
│   │       ├── writer.dart       # Code generation logic
│   │       └── model.dart        # Data models
│   ├── build.yaml                # Builder configuration
│   ├── example/                  # Usage examples
│   └── test/                     # Unit tests
├── annotation/
│   └── lib/
│       └── dataforge_annotation.dart  # @Dataforge, @JsonKey
└── view_model/                   # (Separate package)
```

### Running Tests

```bash
cd generator
dart pub get
dart test
```

### Debugging Generated Code

Use `--verbose` flag to see detailed build logs:

```bash
dart run build_runner build --verbose
```

Or check the generated `.data.dart` files directly in your source tree.

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Submit a pull request

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/lwj1994/dataforge/issues)
- **Discussions**: [GitHub Discussions](https://github.com/lwj1994/dataforge/discussions)