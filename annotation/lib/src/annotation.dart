// @author luwenjie on 2025/4/19 17:37:49

import 'converter.dart';

class Dataforge {
  final String name;
  @Deprecated('Use includeFromJson and includeToJson instead')
  final bool? fromMap;
  final bool? includeFromJson;
  final bool? includeToJson;

  /// Enable chained copyWith syntax like object.copyWith.field(value)
  final bool deepCopyWith;

  const Dataforge({
    this.name = "",
    @Deprecated('Use includeFromJson and includeToJson instead') this.fromMap,
    this.includeFromJson,
    this.includeToJson,
    this.deepCopyWith = true,
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
  final JsonTypeConverter? converter;
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

/// Sentinel value used by copyWith to distinguish between null and absent parameters.
///
/// When a parameter is not provided to copyWith, it defaults to this sentinel value,
/// allowing the method to differentiate between:
/// - Parameter not provided (use current value)
/// - Parameter explicitly set to null (update to null)
const Object dataforgeUndefined = Object();
