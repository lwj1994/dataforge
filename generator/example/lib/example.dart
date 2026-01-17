import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'example.data.dart';

/// Built-in converter for DateTime objects that supports nullable values.
/// Accepts any object type and tries to convert it to DateTime.
/// - If input is a number (13-digit milliseconds timestamp), uses DateTime.fromMillisecondsSinceEpoch
/// - If input is a number with less than 13 digits, pads it to 13 digits
/// - Otherwise tries to parse using DateTime.parse as fallback
class MyDateTimeConverter extends TypeConverter<DateTime, String> {
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
  final DateTime? dateTime;

  @JsonKey(converter: MyDateTimeConverter())
  final DateTime? dateTime2;

  DateTimeExample({
    this.dateTime,
    this.dateTime2,
  });

  factory DateTimeExample.fromJson(Map<String, dynamic> json) =>
      _DateTimeExample.fromJson(json);
}

/// Example user class using dataforge_generator
@Dataforge()
class User with _User {
  final String name;
  final int age;
  final String? email;

  User({
    required this.name,
    required this.age,
    this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) => _User.fromJson(json);
}

/// Example with JsonKey annotations
@Dataforge()
class Product with _Product {
  final String id;

  @JsonKey(name: 'product_name')
  final String productName;

  @JsonKey(name: 'unit_price')
  final double unitPrice;

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
  final T? data;
  final String? error;
  final bool success;

  Result({
    this.data,
    this.error,
    required this.success,
  });

  factory Result.fromJson(Map<String, dynamic> json) => _Result.fromJson(json);
}

/// Example with chained copyWith
@Dataforge(chainedCopyWith: true)
class Address with _Address {
  final String street;
  final String city;
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
@Dataforge(chainedCopyWith: true)
class ComplexUser with _ComplexUser {
  final User user;
  final Address address;
  final String nickname;

  ComplexUser({
    required this.user,
    required this.address,
    required this.nickname,
  });

  factory ComplexUser.fromJson(Map<String, dynamic> json) =>
      _ComplexUser.fromJson(json);
}
