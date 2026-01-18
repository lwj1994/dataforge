/// Safe type conversion utility class for basic types
class SafeCasteUtil {
  /// Safely converts a value to the specified type with null safety
  /// Supports: int, double, String, bool (dynamic/Map work via `value is T` check)
  static T? safeCast<T>(dynamic value) {
    if (value == null) return null;

    try {
      if (value is T) return value;

      // Handle string conversions
      if (T == String) {
        return value.toString() as T;
      }

      // Handle numeric conversions
      if (T == int) {
        if (value is num) return value.toInt() as T;
        if (value is String) {
          final parsed = int.tryParse(value);
          return parsed as T?;
        }
      }

      if (T == double) {
        if (value is num) return value.toDouble() as T;
        if (value is String) {
          final parsed = double.tryParse(value);
          return parsed as T?;
        }
      }

      // Handle boolean conversions
      if (T == bool) {
        if (value is String) {
          final lower = value.toLowerCase();
          if (lower == 'true') return true as T;
          if (lower == 'false') return false as T;
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Safely reads a value from a map with type conversion
  static T? readValue<T>(Map<String, dynamic>? map, String key) {
    if (map == null || !map.containsKey(key)) return null;
    return safeCast<T>(map[key]);
  }

  /// Safely reads a required value from a map with type conversion
  static T readRequiredValue<T>(Map<String, dynamic> map, String key) {
    if (!map.containsKey(key)) {
      throw ArgumentError('Required key "$key" not found in map');
    }
    final value = safeCast<T>(map[key]);
    if (value == null) {
      throw ArgumentError(
          'Value for key "$key" cannot be converted to type $T');
    }
    return value;
  }

  /// Safely reads an object from a map using a factory function
  static T? readObject<T>(
    Map<String, dynamic>? map,
    String key,
    T Function(Map<String, dynamic>) factory,
  ) {
    if (map == null || !map.containsKey(key)) return null;
    return parseObject(map[key], factory);
  }

  /// Safely reads a required object from a map using a factory function
  static T readRequiredObject<T>(
    Map<String, dynamic> map,
    String key,
    T Function(Map<String, dynamic>) factory,
  ) {
    if (!map.containsKey(key)) {
      throw ArgumentError('Required key "$key" not found in map');
    }
    final value = parseObject(map[key], factory);
    if (value == null) {
      throw ArgumentError(
          'Value for key "$key" cannot be converted to type $T');
    }
    return value;
  }

  static T? parseObject<T>(
    dynamic value,
    T Function(Map<String, dynamic>) factory,
  ) {
    if (value == null) return null;
    final map = safeCast<Map<String, dynamic>>(value);
    if (map == null) return null;
    return factory(map);
  }
}
