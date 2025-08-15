// @author luwenjie on 2025/4/19 17:37:49

class DataClass {
  final String name;
  @Deprecated('Use includeFromJson and includeToJson instead')
  final bool? fromMap;
  final bool? includeFromJson;
  final bool? includeToJson;

  const DataClass({
    this.name = "",
    @Deprecated('Use includeFromJson and includeToJson instead') this.fromMap,
    this.includeFromJson,
    this.includeToJson,
  });
}

const dataClass = DataClass();

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

class JsonKey {
  final String name;
  final List<String> alternateNames;
  final bool ignore;
  final Object? Function(Map<dynamic, dynamic> map, String key)? readValue;
  final TypeConverter? converter;
  final bool? includeIfNull;

  const JsonKey({
    this.name = "",
    this.alternateNames = const [],
    this.readValue,
    this.ignore = false,
    this.converter,
    this.includeIfNull,
  });
}
