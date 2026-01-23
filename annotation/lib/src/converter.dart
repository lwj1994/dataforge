// @author luwenjie on 2025/4/19 17:37:49

/// Abstract base class for type converters that can convert between JSON values and Dart objects.
///
/// Type converters are used to handle custom serialization/deserialization logic
/// for specific field types that require special handling.
///
///
abstract class JsonTypeConverter<T, S> {
  const JsonTypeConverter();

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
///
/// Accepts various input formats and converts them to DateTime:
/// - DateTime objects are returned as-is
/// - Numeric timestamps (milliseconds since Unix epoch):
///   * 13-digit numbers: treated as milliseconds (e.g., 1737619200000)
///   * 10-digit numbers: treated as seconds and converted to milliseconds (e.g., 1737619200)
///   * Other lengths: throws FormatException to avoid ambiguous interpretation
/// - String values: parsed using DateTime.parse() which supports ISO 8601 format
///
/// ## Timestamp Format Examples
/// ```dart
/// // Milliseconds (13 digits) - Preferred for precise timestamps
/// fromJson(1737619200000) // => 2026-01-23 08:00:00.000Z
///
/// // Seconds (10 digits) - Common in Unix timestamps
/// fromJson(1737619200)    // => 2026-01-23 08:00:00.000Z
///
/// // ISO 8601 string - Standard date format
/// fromJson("2026-01-23T08:00:00.000Z") // => 2026-01-23 08:00:00.000Z
/// ```
///
/// ## Error Handling
/// - Ambiguous timestamp lengths (not 10 or 13 digits) will throw FormatException
/// - Invalid date strings will return null instead of throwing
/// - Null input always returns null
class DefaultDateTimeConverter extends JsonTypeConverter<DateTime, String> {
  const DefaultDateTimeConverter();

  @override
  DateTime? fromJson(Object? json) {
    if (json is DateTime) return json;
    if (json == null) return null;

    // Handle numeric timestamps (milliseconds or seconds since epoch)
    final maybeInt = int.tryParse(json.toString());

    if (json is num || maybeInt != null) {
      final timestamp = json.toString();
      final length = timestamp.length;

      // Standard milliseconds timestamp (13 digits)
      if (length == 13) {
        return DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
      }

      // Standard seconds timestamp (10 digits) - convert to milliseconds
      if (length == 10) {
        return DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp) * 1000);
      }

      // Reject ambiguous timestamp lengths to prevent incorrect conversions
      // Examples of problematic cases:
      // - "123" could be seconds, milliseconds, or invalid
      // - "12345678" could be partial timestamp or invalid
      throw FormatException(
        'Ambiguous timestamp length: $length digits. '
        'Expected 10 digits (seconds) or 13 digits (milliseconds). '
        'Received: $timestamp',
      );
    }

    // Try to parse as ISO 8601 or other standard date string format
    try {
      return DateTime.parse(json.toString());
    } catch (e) {
      // If parsing fails, return null instead of throwing
      // This allows graceful handling of invalid date strings
      return null;
    }
  }

  @override
  String? toJson(DateTime? object) {
    if (object == null) return null;
    // Always serialize as milliseconds timestamp for consistency
    return object.millisecondsSinceEpoch.toString();
  }
}

/// Built-in converter for Enum objects.
/// Converts Enum to/from string using the enum name.
class DefaultEnumConverter<T extends Enum>
    extends JsonTypeConverter<T, String> {
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
