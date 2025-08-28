/// Basic user information class
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

/// Product information class - demonstrates field name mapping
class Product {
  final String name;
  final String id;
  final double price;
  final bool isAvailable;

  const Product({
    required this.name,
    required this.id,
    required this.price,
    this.isAvailable = true,
  });

  /// Create Product object from JSON with field name mapping support
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['name'] as String,
      id: json['product_id'] as String, // Field name mapping
      price: json['unit_price'] as double, // Field name mapping
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }

  /// Convert Product object to JSON using mapped field names
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'product_id': id,
      'unit_price': price,
      'isAvailable': isAvailable,
    };
  }
}

/// User profile class - demonstrates alternate field names
class UserProfile {
  final String name;
  final int age;
  final String email;
  final bool isActive;

  const UserProfile({
    required this.name,
    required this.age,
    required this.email,
    required this.isActive,
  });

  /// Create UserProfile object from JSON with multiple alternate field names support
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String,
      // Support multiple alternate field names
      age: (json['user_age'] ?? json['age'] ?? json['years']) as int,
      email: (json['email'] ??
          json['email_address'] ??
          json['mail'] ??
          json['e_mail']) as String,
      isActive:
          (json['is_active'] ?? json['active'] ?? json['enabled']) as bool,
    );
  }

  /// Convert UserProfile object to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'user_age': age,
      'email': email,
      'is_active': isActive,
    };
  }
}

/// Account class - demonstrates ignored fields
class Account {
  final String username;
  final String? password; // Ignored field, not serialized
  final String email;
  final String? secretToken; // Ignored field, not serialized

  const Account({
    required this.username,
    this.password,
    required this.email,
    this.secretToken,
  });

  /// Create Account object from JSON, ignoring sensitive fields
  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      username: json['username'] as String,
      email: json['email'] as String,
      // password and secretToken are ignored, not read from JSON
    );
  }

  /// Convert Account object to JSON, ignoring sensitive fields
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      // password and secretToken are ignored, not written to JSON
    };
  }
}

/// Configuration class - demonstrates default values
class Config {
  final String name;
  final bool isEnabled;
  final List<String> tags;
  final int maxRetries;

  const Config({
    required this.name,
    this.isEnabled = true,
    this.tags = const [],
    this.maxRetries = 3,
  });

  /// Create Config object from JSON with default values support
  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(
      name: json['name'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      maxRetries: json['maxRetries'] as int? ?? 3,
    );
  }

  /// Convert Config object to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isEnabled': isEnabled,
      'tags': tags,
      'maxRetries': maxRetries,
    };
  }
}

/// Main function demonstrating how to use data classes
void main() {
  print('=== Dataforge Data Class Usage Examples ===\n');

  // 1. Basic usage
  print('1. Basic usage:');
  final user = User(
    name: 'John Doe',
    age: 30,
    email: 'john@example.com',
  );
  print('Created user: ${user.name}, age: ${user.age}');

  // Create object from JSON
  final userJson = {
    'name': 'Jane Smith',
    'age': 25,
    'email': 'jane@example.com',
  };
  final userFromJson = User.fromJson(userJson);
  print('User created from JSON: ${userFromJson.name}\n');

  // 2. Product example - field name mapping
  print('2. Field name mapping example:');
  final productJson = {
    'name': 'iPhone',
    'product_id': 'IP001',
    'unit_price': 999.99,
    'isAvailable': true,
  };
  final product = Product.fromJson(productJson);
  print(
      'Product: ${product.name}, ID: ${product.id}, price: ${product.price}\n');

  // 3. User profile - alternate field names
  print('3. Alternate field names example:');
  final profileJson1 = {
    'name': 'Alice',
    'user_age': 28,
    'email_address': 'alice@example.com',
    'is_active': true,
  };
  final profile1 = UserProfile.fromJson(profileJson1);

  final profileJson2 = {
    'name': 'Bob',
    'age': 32, // Using alternate field name
    'mail': 'bob@example.com', // Using alternate field name
    'active': false, // Using alternate field name
  };
  final profile2 = UserProfile.fromJson(profileJson2);
  print('Profile1: ${profile1.name}, age: ${profile1.age}');
  print('Profile2: ${profile2.name}, age: ${profile2.age}\n');

  // 4. Account - ignored fields
  print('4. Ignored fields example:');
  final accountJson = {
    'username': 'testuser',
    'email': 'test@example.com',
    'password': 'secret123', // This field will be ignored
    'secretToken': 'token123', // This field will also be ignored
  };
  final account = Account.fromJson(accountJson);
  print('Account: ${account.username}, email: ${account.email}');
  print('Password ignored: ${account.password}\n'); // Should be null

  // 5. Configuration - default values
  print('5. Default values example:');
  final configJson = {
    'name': 'MyApp',
    // isEnabled and tags use default values
  };
  final config = Config.fromJson(configJson);
  print(
      'Config: ${config.name}, enabled: ${config.isEnabled}, tags: ${config.tags}');

  // 6. Serialize to JSON
  print('\n6. Serialize to JSON:');
  print('User JSON: ${user.toJson()}');
  print('Product JSON: ${product.toJson()}');
  print('Config JSON: ${config.toJson()}');
}
