```dart
class User {
  final String name;
  final int age;
  final String email;

  const User({
    required this.name,
    required this.age,
    required this.email,
  });

  /// Create User object from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] as String,
      age: json['age'] as int,
      email: json['email'] as String,
    );
  }

  /// Convert User object to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'email': email,
    };
  }
}

```