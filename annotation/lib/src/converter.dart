// @author luwenjie on 2025/4/19 17:37:49

/// Abstract base class for type converters that can convert between JSON values and Dart objects.
///
/// Type converters are used to handle custom serialization/deserialization logic
/// for specific field types that require special handling.
abstract class TypeConverter<T, S> {
  const TypeConverter();

  /// Converts a JSON value [json] of type [S] to a Dart object of type [T].
  /// This method is called during deserialization (fromJson).
  T fromJson(S json);

  /// Converts a Dart object [object] of type [T] to a JSON value of type [S].
  /// This method is called during serialization (toJson).
  S toJson(T object);
}

/// Built-in converter for DateTime objects.
/// Converts DateTime to/from ISO 8601 string format.
class DateTimeConverter extends TypeConverter<DateTime, String> {
  const DateTimeConverter();

  @override
  DateTime fromJson(String json) {
    return DateTime.parse(json);
  }

  @override
  String toJson(DateTime object) {
    return object.toIso8601String();
  }
}

/// Built-in converter for DateTime objects to/from milliseconds timestamp.
/// Converts DateTime to/from integer milliseconds since epoch.
class DateTimeMillisecondsConverter extends TypeConverter<DateTime, int> {
  const DateTimeMillisecondsConverter();

  @override
  DateTime fromJson(int json) {
    return DateTime.fromMillisecondsSinceEpoch(json);
  }

  @override
  int toJson(DateTime object) {
    return object.millisecondsSinceEpoch;
  }
}

/// Built-in converter for Duration objects.
/// Converts Duration to/from microseconds integer.
class DurationConverter extends TypeConverter<Duration, int> {
  const DurationConverter();

  @override
  Duration fromJson(int json) {
    return Duration(microseconds: json);
  }

  @override
  int toJson(Duration object) {
    return object.inMicroseconds;
  }
}

/// Built-in converter for Duration objects to/from milliseconds.
/// Converts Duration to/from milliseconds integer.
class DurationMillisecondsConverter extends TypeConverter<Duration, int> {
  const DurationMillisecondsConverter();

  @override
  Duration fromJson(int json) {
    return Duration(milliseconds: json);
  }

  @override
  int toJson(Duration object) {
    return object.inMilliseconds;
  }
}

/// Built-in converter for Enum objects.
/// Converts Enum to/from string using the enum name.
class EnumConverter<T extends Enum> extends TypeConverter<T, String> {
  final List<T> values;

  const EnumConverter(this.values);

  @override
  T fromJson(String json) {
    return values.firstWhere(
      (e) => e.name == json,
      orElse: () => throw ArgumentError('Unknown enum value: $json'),
    );
  }

  @override
  String toJson(T object) {
    return object.name;
  }
}

/// Built-in converter for Enum objects to/from index.
/// Converts Enum to/from integer index.
class EnumIndexConverter<T extends Enum> extends TypeConverter<T, int> {
  final List<T> values;

  const EnumIndexConverter(this.values);

  @override
  T fromJson(int json) {
    if (json < 0 || json >= values.length) {
      throw ArgumentError('Enum index out of range: $json');
    }
    return values[json];
  }

  @override
  int toJson(T object) {
    return object.index;
  }
}
