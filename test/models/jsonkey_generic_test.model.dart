import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:collection/collection.dart';

part 'jsonkey_generic_test.model.data.dart';

/// Test class to demonstrate JsonKey fromJson/toJson with generics
/// Similar to json_serializable implementation
@Dataforge()
class ApiResponse<T> with _ApiResponse {
  @override
  final bool success;
  @override
  final String message;

  /// Using JsonKey with fromJson and toJson parameters for generic type handling
  @override
  @JsonKey(
    name: 'data',
    fromJson: _dataFromJson,
    toJson: _dataToJson,
  )
  final T? data;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  /// Static method to handle fromJson conversion for generic type T
  /// This method will be called during deserialization
  static T? _dataFromJson<T>(dynamic json) {
    if (json == null) return null;

    // Handle Map<String, dynamic> for complex types
    if (json is Map<String, dynamic>) {
      // Try to call T.fromJson if T is User type
      if (T == User) {
        return User.fromJson(json) as T;
      }
      // Handle ListResponse<User> type
      if (T.toString().startsWith('ListResponse<')) {
        return ListResponse<User>.fromJson(json) as T;
      }
      // For other types, direct cast
      return json as T;
    }

    // Handle primitive types
    return json as T;
  }

  /// Static method to handle toJson conversion for generic type T
  /// This method will be called during serialization
  static dynamic _dataToJson<T>(T? data) {
    if (data == null) return null;

    // If T has a toJson method, use it
    if (data is Map<String, dynamic>) {
      return data;
    }

    // Try to call toJson method if available
    try {
      final dynamic result = (data as dynamic).toJson();
      return result;
    } catch (e) {
      // Fallback to direct conversion
      return data;
    }
  }

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return _ApiResponse.fromJson(json);
  }
}

/// Test data class for generic type testing
@Dataforge()
class User with _User {
  @override
  final int id;
  @override
  final String name;
  @override
  final String email;
  @override
  final int? age;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.age,
  });
  factory User.fromJson(Map<String, dynamic> json) {
    return _User.fromJson(json);
  }
}

/// Another test class for list generics
@Dataforge()
class ListResponse<T> with _ListResponse {
  @override
  final int total;

  @override
  @JsonKey(
    name: 'items',
    fromJson: _itemsFromJson,
    toJson: _itemsToJson,
  )
  final List<T>? items;

  const ListResponse({
    required this.total,
    this.items,
  });

  /// Handle list conversion for generic type
  static List<T>? _itemsFromJson<T>(dynamic json) {
    if (json == null) return null;
    if (json is! List) return null;

    return json.map((item) {
      if (item is Map<String, dynamic>) {
        // Try to call T.fromJson if T is User type
        if (T == User) {
          return User.fromJson(item) as T;
        }
        // For other types, direct cast
        return item as T;
      }
      return item as T;
    }).toList();
  }

  /// Handle list serialization for generic type
  static dynamic _itemsToJson<T>(List<T>? items) {
    if (items == null) return null;

    return items.map((item) {
      try {
        return (item as dynamic).toJson();
      } catch (e) {
        return item;
      }
    }).toList();
  }

  factory ListResponse.fromJson(Map<String, dynamic> json) {
    return _ListResponse.fromJson(json);
  }
}
