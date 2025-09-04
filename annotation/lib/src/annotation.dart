// @author luwenjie on 2025/4/19 17:37:49

import 'converter.dart';

class Dataforge {
  final String name;
  @Deprecated('Use includeFromJson and includeToJson instead')
  final bool? fromMap;
  final bool? includeFromJson;
  final bool? includeToJson;

  /// Enable chained copyWith syntax like object.copyWith.field(value)
  final bool chainedCopyWith;

  const Dataforge({
    this.name = "",
    @Deprecated('Use includeFromJson and includeToJson instead') this.fromMap,
    this.includeFromJson,
    this.includeToJson,
    this.chainedCopyWith = true,
  });
}

const dataforge = Dataforge();

// Keep DataClass as deprecated alias for backward compatibility
@Deprecated('Use Dataforge instead')
typedef DataClass = Dataforge;

@Deprecated('Use dataforge instead')
const dataClass = Dataforge();

class JsonKey {
  final String name;
  final List<String> alternateNames;
  final bool ignore;
  final Object? Function(Map<dynamic, dynamic> map, String key)? readValue;
  final TypeConverter? converter;
  final bool? includeIfNull;

  /// Custom function for deserializing field value from JSON
  /// Similar to json_serializable's fromJson parameter
  final Function? fromJson;

  /// Custom function for serializing field value to JSON
  /// Similar to json_serializable's toJson parameter
  final Function? toJson;

  const JsonKey({
    this.name = "",
    this.alternateNames = const [],
    this.readValue,
    this.ignore = false,
    this.converter,
    this.includeIfNull,
    this.fromJson,
    this.toJson,
  });
}
