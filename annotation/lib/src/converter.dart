// @author luwenjie on 2025/4/19 17:37:49

/// Abstract base class for type converters that can convert between JSON values and Dart objects.
///
/// Type converters are used to handle custom serialization/deserialization logic
/// for specific field types that require special handling.
abstract class TypeConverter<T, S> {
  const TypeConverter();

  /// Converts a JSON value [json] of type [S] to a Dart object of type [T].
  /// This method is called during deserialization (fromJson).
  ///
  /// [json] can be null, and the return value can also be null.
  /// If the field is declared as non-nullable but receives a null value,
  /// an exception will be thrown during deserialization.
  T? fromJson(S? json);

  /// Converts a Dart object [object] of type [T] to a JSON value of type [S].
  /// This method is called during serialization (toJson).
  ///
  /// [object] can be null, and the return value can also be null.
  /// If the field is declared as non-nullable but receives a null value,
  /// an exception will be thrown during serialization.
  S? toJson(T? object);
}

/// Built-in converter for DateTime objects that supports nullable values.
/// Accepts any object type and tries to convert it to DateTime.
/// - If input is a number (13-digit milliseconds timestamp), uses DateTime.fromMillisecondsSinceEpoch
/// - If input is a number with less than 13 digits, pads it to 13 digits
/// - Otherwise tries to parse using DateTime.parse as fallback
class DefaultDateTimeConverter extends TypeConverter<DateTime, String> {
  const DefaultDateTimeConverter();

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

/// Built-in converter for Enum objects.
/// Converts Enum to/from string using the enum name.
class DefaultEnumConverter<T extends Enum> extends TypeConverter<T, String> {
  final List<T> values;

  const DefaultEnumConverter(this.values);

  @override
  T? fromJson(String? json) {
    if (json == null) return null;
    try {
      return values.firstWhere(
        (e) => e.name == json,
      );
    } catch (e) {
      //
      return null;
    }
  }

  @override
  String? toJson(T? object) {
    if (object == null) return null;
    return object.name;
  }
}
