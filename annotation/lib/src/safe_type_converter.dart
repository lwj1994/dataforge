/// Safe type conversion utility class for basic types
class SafeCasteUtil {
  /// Safely converts a value to the specified type with null safety
  /// Supports: int, double, String, bool
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
}
