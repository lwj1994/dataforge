# Dart Dataforge

[![Pub Version](https://img.shields.io/pub/v/dataforge)](https://pub.dev/packages/dataforge)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A high-performance Dart data class generator that's **multiple times faster** than `build_runner`. Generate perfect data classes with `copyWith`, `==`, `hashCode`, `toJson`, `fromJson`, and more.

## ✨ Features

- ⚡ **Lightning Fast**: Multiple times faster than `build_runner`
- 🎯 **Zero Configuration**: Works out of the box
- 📦 **Complete Generation**: `copyWith`, `==`, `hashCode`, `toJson`, `fromJson`, `toString`
- 🔗 **Chained CopyWith**: Advanced nested object updates
- 🔧 **Flexible**: Custom field mapping, ignore fields, alternate names
- 🌟 **Type Safe**: Full compile-time type checking
- 🚀 **Easy to Use**: Simple annotations, minimal setup

## 📦 Installation

### 1. Add Dependency

```yaml
dependencies:
  dataforge_annotation: ^0.2.0
```

### 2. Install CLI Tool

```bash
dart pub global activate dataforge
```

## 🚀 Quick Start

### 1. Create Your Data Class

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

### 2. Generate Code

```bash
# Generate for current directory
dataforge .

# Generate for specific files
dataforge lib/models/user.dart
```

### 3. Use Generated Methods

```dart
void main() {
  // Create instance
  final user = User(name: "John", age: 25, hobbies: ["coding"]);
  
  // Copy with changes
  final updated = user.copyWith(age: 26);
  
  // JSON serialization
  final json = user.toJson();
  final fromJson = User.fromJson(json);
  
  // Object comparison
  print(user == updated); // false
  print(user.toString()); // User(name: John, age: 25, hobbies: [coding])
}
```

## 🔧 Configuration

### @Dataforge Annotation

```dart
@Dataforge(
  includeFromJson: true,    // Generate fromJson method (default: false)
  includeToJson: true,      // Generate toJson method (default: false)
  chainedCopyWith: false,   // Disable chained copyWith (default: true)
)
class MyClass with _MyClass {
  // ...
}
```

### @JsonKey Annotation

```dart
class User with _User {
  // Custom JSON field name
  @JsonKey(name: "user_name")
  final String name;
  
  // Multiple possible field names
  @JsonKey(alternateNames: ["user_age", "age"])
  final int age;
  
  // Ignore field in JSON
  @JsonKey(ignore: true)
  final String? password;
  
  // Exclude null values from JSON
  @JsonKey(includeIfNull: false)
  final String? nickname;
  
  // Custom value reading
  @JsonKey(readValue: parseDate)
  final DateTime createdAt;
  
  static Object? parseDate(Map map, String key) {
    final value = map[key];
    return value is String ? DateTime.parse(value) : value;
  }
}
```

## 🔗 Advanced CopyWith Features

Dataforge provides multiple copyWith patterns to suit different coding styles and use cases:

### 1. Traditional CopyWith (Default)

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

// Usage
final user = User(name: 'John', age: 25, email: 'john@example.com');
final updated = user.copyWith(name: 'Jane', age: 30);
```

### 2. Chained CopyWith (Fluent API)

Enable chained copyWith for a more fluent API experience:

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

// Chained updates
final updated1 = user.copyWith.name('Jane').build();
final updated2 = user.copyWith.name('Jane').age(30).build();
final updated3 = user.copyWith.email(null).build();

// Traditional copyWith still available
final updated4 = user.copyWith(name: 'Jane', age: 30);
```

### 3. Nested Object Updates

For complex nested objects, use the traditional copyWith method:

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

// Nested updates using traditional copyWith
final profile = Profile(
  user: User(name: 'John', age: 25),
  address: Address(street: '123 Main St', city: 'New York', zipCode: '10001'),
  tags: ['developer'],
);

// Update nested user
final updated1 = profile.copyWith(
  user: profile.user.copyWith(name: 'Jane')
);

// Update nested address
final updated2 = profile.copyWith(
  address: profile.address.copyWith(
    street: '999 Executive Blvd',
    city: 'San Francisco'
  )
);

// Multiple nested updates
final updated3 = profile.copyWith(
  user: profile.user.copyWith(name: 'Alice', age: 35),
  address: profile.address.copyWith(city: 'Los Angeles'),
  tags: ['senior-developer', 'team-lead']
);
```

### 4. Chained CopyWith with Nested Objects

When using chained copyWith, you can still update nested objects:

```dart
@Dataforge(chainedCopyWith: true)
class Profile with _Profile {
  // ... same as above
}

// Chained updates with nested objects
final updated1 = profile.copyWith
  .user(profile.user.copyWith(name: 'Jane'))
  .build();
  
final updated2 = profile.copyWith
  .address(profile.address.copyWith(city: 'San Francisco'))
  .build();
```

### 5. Mixed Usage Patterns

```dart
// Traditional copyWith for simple cases
final simple = user.copyWith(name: 'Simple Update');

// Chained for fluent API
final fluent = user.copyWith.name('Fluent').age(25).build();

// Nested object updates
final nested = profile.copyWith(
  user: User(name: 'New User', age: 40),  // Replace entire object
  tags: ['new-tag']                       // Update list
);
```

## 📋 Supported Types

- **Basic Types**: `String`, `int`, `double`, `bool`, `num`
- **Date/Time**: `DateTime`, `Duration`
- **Collections**: `List<T>`, `Set<T>`, `Map<K, V>`
- **Optional Types**: `String?`, `int?`, etc.
- **Nested Objects**: Custom classes with `fromJson`
- **Complex Collections**: `List<User>`, `Map<String, User>`, etc.

## 🔄 Migration from build_runner

Migrating from `json_annotation` + `build_runner`? It's easy:

**Before (build_runner):**
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

**After (Dataforge):**
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

## 🎯 Why Dataforge?

| Feature | Dataforge | build_runner |
|---------|-----------|-------------|
| **Speed** | ⚡ Multiple times faster | 🐌 Slow |
| **Setup** | ✅ Zero config | ❌ Complex setup |
| **Dependencies** | ✅ Lightweight | ❌ Heavy |
| **Generated Code** | ✅ Clean & readable | ❌ Complex |
| **Chained CopyWith** | ✅ Built-in | ❌ Not available |
| **Learning Curve** | ✅ Minimal | ❌ Steep |

## 🛠️ Development

```bash
# Clone repository
git clone https://github.com/lwj1994/dataforge.git
cd dataforge

# Install dependencies
dart pub get

# Run tests
dart test

# Format code
dart tools/format_project.dart
```

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📞 Support

If you encounter any issues or have feature requests, please create an issue on [GitHub](https://github.com/lwj1994/dataforge/issues).