import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'example.data.dart';

/// Built-in converter for DateTime objects that supports nullable values.
/// Accepts any object type and tries to convert it to DateTime.
/// - If input is a number (13-digit milliseconds timestamp), uses DateTime.fromMillisecondsSinceEpoch
/// - If input is a number with less than 13 digits, pads it to 13 digits
/// - Otherwise tries to parse using DateTime.parse as fallback
class MyDateTimeConverter extends JsonTypeConverter<DateTime, String> {
  const MyDateTimeConverter();

  @override
  DateTime? fromJson(Object? json) {
    if (json == null) return null;

    // Handle numeric timestamps (milliseconds since epoch)
    if (json is int) {
      final timestamp = json.toString();
      if (timestamp.length <= 13) {
        // Pad to 13 digits if needed (to handle seconds or other shorter timestamps)
        final paddedTimestamp = timestamp.padRight(13, '0');
        return DateTime.fromMillisecondsSinceEpoch(int.parse(paddedTimestamp));
      }
      return DateTime.fromMillisecondsSinceEpoch(json);
    }

    // Handle string timestamps
    if (json is String) {
      // Handle empty string
      if (json.isEmpty) {
        return null;
      }

      // Try to parse as number first
      if (RegExp(r'^\d+$').hasMatch(json)) {
        final timestamp = json;
        if (timestamp.length <= 13) {
          // Pad to 13 digits if needed
          final paddedTimestamp = timestamp.padRight(13, '0');
          return DateTime.fromMillisecondsSinceEpoch(
              int.parse(paddedTimestamp));
        }
        return DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
      }

      // Otherwise try to parse as ISO date string
      try {
        return DateTime.parse(json);
      } catch (e) {
        // Ignore parsing errors and try next method
      }
    }

    // Last resort: try to convert to string and parse
    try {
      return DateTime.parse(json.toString());
    } catch (e) {
      // If all conversion attempts fail, return null instead of throwing
      return null;
    }
  }

  @override
  String? toJson(DateTime? object) {
    if (object == null) return null;
    return object.millisecondsSinceEpoch.toString();
  }
}

@Dataforge()
class DateTimeExample with _DateTimeExample {
  @override
  final DateTime? dateTime;

  @override
  @JsonKey(converter: MyDateTimeConverter())
  final DateTime? dateTime2;

  DateTimeExample({
    this.dateTime,
    this.dateTime2,
  });

  factory DateTimeExample.fromJson(Map<String, dynamic> json) =>
      _DateTimeExample.fromJson(json);
}

/// Example user class using dataforge
@Dataforge()
class User with _User {
  @override
  final String name;
  @override
  final int age;
  @override
  final String? email;

  User({
    required this.name,
    required this.age,
    this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) => _User.fromJson(json);
}

/// Example with nullable nested fields
@Dataforge(deepCopyWith: true)
class NullableComplexUser with _NullableComplexUser {
  NullableComplexUser({
    required this.user,
    this.address,
    required this.nickname,
  });

  @override
  final User? user; // Nullable nested
  @override
  final Address? address; // Nullable nested
  @override
  final String nickname;
}

/// Product class example
@Dataforge()
class Product with _Product {
  @override
  final String id;

  @override
  @JsonKey(name: 'product_name')
  final String productName;

  @override
  @JsonKey(name: 'unit_price')
  final double unitPrice;

  @override
  @JsonKey(ignore: true)
  final DateTime? createdAt;

  Product({
    required this.id,
    required this.productName,
    required this.unitPrice,
    this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) =>
      _Product.fromJson(json);
}

/// Example with generic parameters
@Dataforge()
class Result<T> with _Result<T> {
  @override
  final T? data;
  @override
  final String? error;
  @override
  final bool success;

  Result({
    this.data,
    this.error,
    required this.success,
  });

  factory Result.fromJson(Map<String, dynamic> json) => _Result.fromJson(json);
}

/// Example with chained copyWith
@Dataforge(deepCopyWith: true)
class Address with _Address {
  @override
  final String street;
  @override
  final String city;
  @override
  final String country;

  Address({
    required this.street,
    required this.city,
    required this.country,
  });

  factory Address.fromJson(Map<String, dynamic> json) =>
      _Address.fromJson(json);
}

/// Example demonstrating Nested (Chained) CopyWith
@Dataforge(deepCopyWith: true)
class ComplexUser with _ComplexUser {
  @override
  final User user;
  @override
  final Address address;
  @override
  final String nickname;

  ComplexUser({
    required this.user,
    required this.address,
    required this.nickname,
  });

  factory ComplexUser.fromJson(Map<String, dynamic> json) =>
      _ComplexUser.fromJson(json);
}

@Dataforge(deepCopyWith: true)
class ListExample with _ListExample {
  ListExample({
    required this.user,
    required this.nickname,
  });

  @override
  final List<User> user; // Nullable nested
  @override
  final String nickname;
}
