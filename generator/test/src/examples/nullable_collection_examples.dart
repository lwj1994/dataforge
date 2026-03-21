import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:source_gen_test/annotations.dart';

// Helper class for nullable collection tests
@Dataforge()
class Tag {
  final String label;
  Tag({required this.label});
}

@ShouldGenerate(r'''
mixin _NullableMapExample {
  abstract final Map<String, String>? nullableStringMap;
  abstract final Map<String, int>? nullableIntMap;
  @pragma('vm:prefer-inline')
  NullableMapExampleCopyWith<NullableMapExample> get copyWith =>
      NullableMapExampleCopyWith<NullableMapExample>(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NullableMapExample) return false;

    if (!const DeepCollectionEquality().equals(
      nullableStringMap,
      other.nullableStringMap,
    )) {
      return false;
    }
    if (!const DeepCollectionEquality().equals(
      nullableIntMap,
      other.nullableIntMap,
    )) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([
    const DeepCollectionEquality().hash(nullableStringMap),
    const DeepCollectionEquality().hash(nullableIntMap),
  ]);

  @override
  String toString() =>
      'NullableMapExample(nullableStringMap: $nullableStringMap, nullableIntMap: $nullableIntMap)';

  Map<String, dynamic> toJson() {
    return {
      'nullableStringMap': nullableStringMap,
      'nullableIntMap': nullableIntMap,
    };
  }

  static NullableMapExample fromJson(Map<String, dynamic> json) {
    return NullableMapExample(
      nullableStringMap:
          (SafeCasteUtil.readValue<Map<String, dynamic>>(
            json,
            'nullableStringMap',
          )?.map(
            (k, v) => MapEntry(
              k.toString(),
              (SafeCasteUtil.safeCast<String>(v) ?? ''),
            ),
          )),
      nullableIntMap:
          (SafeCasteUtil.readValue<Map<String, dynamic>>(
            json,
            'nullableIntMap',
          )?.map(
            (k, v) =>
                MapEntry(k.toString(), (SafeCasteUtil.safeCast<int>(v) ?? 0)),
          )),
    );
  }
}

class NullableMapExampleCopyWith<R> {
  final _NullableMapExample _instance;
  final R Function(NullableMapExample)? _then;
  // ignore: library_private_types_in_public_api
  NullableMapExampleCopyWith(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({
    Object? nullableStringMap = dataforgeUndefined,
    Object? nullableIntMap = dataforgeUndefined,
  }) {
    final res = NullableMapExample(
      nullableStringMap: SafeCasteUtil.copyWithCastNullableMap<String, String>(
        nullableStringMap,
        'nullableStringMap',
        _instance.nullableStringMap,
      ),
      nullableIntMap: SafeCasteUtil.copyWithCastNullableMap<String, int>(
        nullableIntMap,
        'nullableIntMap',
        _instance.nullableIntMap,
      ),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R nullableStringMap(Map<String, String>? value) {
    final res = call(nullableStringMap: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  R nullableIntMap(Map<String, int>? value) {
    final res = call(nullableIntMap: value);
    return res;
  }
}
''')
@Dataforge()
class NullableMapExample {
  final Map<String, String>? nullableStringMap;
  final Map<String, int>? nullableIntMap;

  NullableMapExample({this.nullableStringMap, this.nullableIntMap});
}

@ShouldGenerate(r'''
mixin _NullableSetExample {
  abstract final Set<String>? nullableTags;
  abstract final Set<int>? nullableIds;
  @pragma('vm:prefer-inline')
  NullableSetExampleCopyWith<NullableSetExample> get copyWith =>
      NullableSetExampleCopyWith<NullableSetExample>(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NullableSetExample) return false;

    if (!const DeepCollectionEquality().equals(
      nullableTags,
      other.nullableTags,
    )) {
      return false;
    }
    if (!const DeepCollectionEquality().equals(
      nullableIds,
      other.nullableIds,
    )) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([
    const DeepCollectionEquality().hash(nullableTags),
    const DeepCollectionEquality().hash(nullableIds),
  ]);

  @override
  String toString() =>
      'NullableSetExample(nullableTags: $nullableTags, nullableIds: $nullableIds)';

  Map<String, dynamic> toJson() {
    return {
      'nullableTags': nullableTags?.toList(),
      'nullableIds': nullableIds?.toList(),
    };
  }

  static NullableSetExample fromJson(Map<String, dynamic> json) {
    return NullableSetExample(
      nullableTags: ((SafeCasteUtil.readValue<List<dynamic>>(
        json,
        'nullableTags',
      )?.map((e) => (SafeCasteUtil.safeCast<String>(e) ?? '')).toSet())),
      nullableIds: ((SafeCasteUtil.readValue<List<dynamic>>(
        json,
        'nullableIds',
      )?.map((e) => (SafeCasteUtil.safeCast<int>(e) ?? 0)).toSet())),
    );
  }
}

class NullableSetExampleCopyWith<R> {
  final _NullableSetExample _instance;
  final R Function(NullableSetExample)? _then;
  // ignore: library_private_types_in_public_api
  NullableSetExampleCopyWith(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({
    Object? nullableTags = dataforgeUndefined,
    Object? nullableIds = dataforgeUndefined,
  }) {
    final res = NullableSetExample(
      nullableTags: SafeCasteUtil.copyWithCastNullableSet<String>(
        nullableTags,
        'nullableTags',
        _instance.nullableTags,
      ),
      nullableIds: SafeCasteUtil.copyWithCastNullableSet<int>(
        nullableIds,
        'nullableIds',
        _instance.nullableIds,
      ),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R nullableTags(Set<String>? value) {
    final res = call(nullableTags: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  R nullableIds(Set<int>? value) {
    final res = call(nullableIds: value);
    return res;
  }
}
''')
@Dataforge()
class NullableSetExample {
  final Set<String>? nullableTags;
  final Set<int>? nullableIds;

  NullableSetExample({this.nullableTags, this.nullableIds});
}

@ShouldGenerate(r'''
mixin _NullableObjectListExample {
  abstract final List<Tag>? tags;
  @pragma('vm:prefer-inline')
  NullableObjectListExampleCopyWith<NullableObjectListExample> get copyWith =>
      NullableObjectListExampleCopyWith<NullableObjectListExample>(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NullableObjectListExample) return false;

    if (!const DeepCollectionEquality().equals(tags, other.tags)) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hashAll([const DeepCollectionEquality().hash(tags)]);

  @override
  String toString() => 'NullableObjectListExample(tags: $tags)';

  Map<String, dynamic> toJson() {
    return {'tags': tags?.map((e) => e.toJson()).toList()};
  }

  static NullableObjectListExample fromJson(Map<String, dynamic> json) {
    return NullableObjectListExample(
      tags: SafeCasteUtil.readObjectList(json['tags'], Tag.fromJson),
    );
  }
}

class NullableObjectListExampleCopyWith<R> {
  final _NullableObjectListExample _instance;
  final R Function(NullableObjectListExample)? _then;
  // ignore: library_private_types_in_public_api
  NullableObjectListExampleCopyWith(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({Object? tags = dataforgeUndefined}) {
    final res = NullableObjectListExample(
      tags: SafeCasteUtil.copyWithCastNullableList<Tag>(
        tags,
        'tags',
        _instance.tags,
      ),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R tags(List<Tag>? value) {
    final res = call(tags: value);
    return res;
  }
}
''')
@Dataforge()
class NullableObjectListExample {
  final List<Tag>? tags;

  NullableObjectListExample({this.tags});
}

@ShouldGenerate(r'''
mixin _NullableMapObjectExample {
  abstract final Map<String, Tag>? tagMap;
  @pragma('vm:prefer-inline')
  NullableMapObjectExampleCopyWith<NullableMapObjectExample> get copyWith =>
      NullableMapObjectExampleCopyWith<NullableMapObjectExample>(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NullableMapObjectExample) return false;

    if (!const DeepCollectionEquality().equals(tagMap, other.tagMap)) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hashAll([const DeepCollectionEquality().hash(tagMap)]);

  @override
  String toString() => 'NullableMapObjectExample(tagMap: $tagMap)';

  Map<String, dynamic> toJson() {
    return {'tagMap': tagMap?.map((k, v) => MapEntry(k, v.toJson()))};
  }

  static NullableMapObjectExample fromJson(Map<String, dynamic> json) {
    return NullableMapObjectExample(
      tagMap: (SafeCasteUtil.readValue<Map<String, dynamic>>(json, 'tagMap')
          ?.map(
            (k, v) => MapEntry(
              k.toString(),
              (Tag.fromJson(v as Map<String, dynamic>)),
            ),
          )),
    );
  }
}

class NullableMapObjectExampleCopyWith<R> {
  final _NullableMapObjectExample _instance;
  final R Function(NullableMapObjectExample)? _then;
  // ignore: library_private_types_in_public_api
  NullableMapObjectExampleCopyWith(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({Object? tagMap = dataforgeUndefined}) {
    final res = NullableMapObjectExample(
      tagMap: SafeCasteUtil.copyWithCastNullableMap<String, Tag>(
        tagMap,
        'tagMap',
        _instance.tagMap,
      ),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R tagMap(Map<String, Tag>? value) {
    final res = call(tagMap: value);
    return res;
  }
}
''')
@Dataforge()
class NullableMapObjectExample {
  final Map<String, Tag>? tagMap;

  NullableMapObjectExample({this.tagMap});
}

@ShouldGenerate(r'''
mixin _MapPrimitiveVariantsExample {
  abstract final Map<String, double> doubleMap;
  abstract final Map<String, bool> boolMap;
  @pragma('vm:prefer-inline')
  MapPrimitiveVariantsExampleCopyWith<MapPrimitiveVariantsExample>
  get copyWith =>
      MapPrimitiveVariantsExampleCopyWith<MapPrimitiveVariantsExample>(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MapPrimitiveVariantsExample) return false;

    if (!const DeepCollectionEquality().equals(doubleMap, other.doubleMap)) {
      return false;
    }
    if (!const DeepCollectionEquality().equals(boolMap, other.boolMap)) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([
    const DeepCollectionEquality().hash(doubleMap),
    const DeepCollectionEquality().hash(boolMap),
  ]);

  @override
  String toString() =>
      'MapPrimitiveVariantsExample(doubleMap: $doubleMap, boolMap: $boolMap)';

  Map<String, dynamic> toJson() {
    return {'doubleMap': doubleMap, 'boolMap': boolMap};
  }

  static MapPrimitiveVariantsExample fromJson(Map<String, dynamic> json) {
    return MapPrimitiveVariantsExample(
      doubleMap:
          (((SafeCasteUtil.readValue<Map<String, dynamic>>(
            json,
            'doubleMap',
          )?.map(
            (k, v) => MapEntry(
              k.toString(),
              (SafeCasteUtil.safeCast<double>(v) ?? 0.0),
            ),
          ))) ??
          (const {})),
      boolMap:
          (((SafeCasteUtil.readValue<Map<String, dynamic>>(
            json,
            'boolMap',
          )?.map(
            (k, v) => MapEntry(
              k.toString(),
              (SafeCasteUtil.safeCast<bool>(v) ?? false),
            ),
          ))) ??
          (const {})),
    );
  }
}

class MapPrimitiveVariantsExampleCopyWith<R> {
  final _MapPrimitiveVariantsExample _instance;
  final R Function(MapPrimitiveVariantsExample)? _then;
  // ignore: library_private_types_in_public_api
  MapPrimitiveVariantsExampleCopyWith(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({
    Object? doubleMap = dataforgeUndefined,
    Object? boolMap = dataforgeUndefined,
  }) {
    final res = MapPrimitiveVariantsExample(
      doubleMap: SafeCasteUtil.copyWithCastMap<String, double>(
        doubleMap,
        'doubleMap',
        _instance.doubleMap,
      ),
      boolMap: SafeCasteUtil.copyWithCastMap<String, bool>(
        boolMap,
        'boolMap',
        _instance.boolMap,
      ),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R doubleMap(Map<String, double> value) {
    final res = call(doubleMap: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  R boolMap(Map<String, bool> value) {
    final res = call(boolMap: value);
    return res;
  }
}
''')
@Dataforge()
class MapPrimitiveVariantsExample {
  final Map<String, double> doubleMap;
  final Map<String, bool> boolMap;

  MapPrimitiveVariantsExample({
    this.doubleMap = const {},
    this.boolMap = const {},
  });
}

@ShouldGenerate(r'''
mixin _SetObjectExample {
  abstract final Set<Tag> tags;
  @pragma('vm:prefer-inline')
  SetObjectExampleCopyWith<SetObjectExample> get copyWith =>
      SetObjectExampleCopyWith<SetObjectExample>(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SetObjectExample) return false;

    if (!const DeepCollectionEquality().equals(tags, other.tags)) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hashAll([const DeepCollectionEquality().hash(tags)]);

  @override
  String toString() => 'SetObjectExample(tags: $tags)';

  Map<String, dynamic> toJson() {
    return {'tags': tags.map((e) => e.toJson()).toList()};
  }

  static SetObjectExample fromJson(Map<String, dynamic> json) {
    return SetObjectExample(
      tags: (SafeCasteUtil.readObjectList(
        SafeCasteUtil.readRequiredValue<List<dynamic>>(json, 'tags'),
        Tag.fromJson,
      )?.toSet()),
    );
  }
}

class SetObjectExampleCopyWith<R> {
  final _SetObjectExample _instance;
  final R Function(SetObjectExample)? _then;
  // ignore: library_private_types_in_public_api
  SetObjectExampleCopyWith(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({Object? tags = dataforgeUndefined}) {
    final res = SetObjectExample(
      tags: SafeCasteUtil.copyWithCastSet<Tag>(tags, 'tags', _instance.tags),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R tags(Set<Tag> value) {
    final res = call(tags: value);
    return res;
  }
}
''')
@Dataforge()
class SetObjectExample {
  final Set<Tag> tags;

  SetObjectExample({required this.tags});
}

enum Color { red, green, blue }

@ShouldGenerate(r'''
mixin _NullableEnumListExample {
  abstract final List<Color>? colors;
  @pragma('vm:prefer-inline')
  NullableEnumListExampleCopyWith<NullableEnumListExample> get copyWith =>
      NullableEnumListExampleCopyWith<NullableEnumListExample>(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NullableEnumListExample) return false;

    if (!const DeepCollectionEquality().equals(colors, other.colors)) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hashAll([const DeepCollectionEquality().hash(colors)]);

  @override
  String toString() => 'NullableEnumListExample(colors: $colors)';

  Map<String, dynamic> toJson() {
    return {
      'colors': colors
          ?.map(
            (e) => const DefaultEnumConverter<Color>(Color.values).toJson(e),
          )
          .toList(),
    };
  }

  static NullableEnumListExample fromJson(Map<String, dynamic> json) {
    return NullableEnumListExample(
      colors: ((SafeCasteUtil.safeCast<List<dynamic>>(json['colors'])
          ?.map(
            (e) => (e is Color
                ? e
                : ((const DefaultEnumConverter<Color>(
                        Color.values,
                      ).fromJson(SafeCasteUtil.safeCast<String>(e))) ??
                      (throw ArgumentError(
                        'Required field "colors" (type: Color) is missing or invalid.',
                      )))),
          )
          .toList())),
    );
  }
}

class NullableEnumListExampleCopyWith<R> {
  final _NullableEnumListExample _instance;
  final R Function(NullableEnumListExample)? _then;
  // ignore: library_private_types_in_public_api
  NullableEnumListExampleCopyWith(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({Object? colors = dataforgeUndefined}) {
    final res = NullableEnumListExample(
      colors: SafeCasteUtil.copyWithCastNullableList<Color>(
        colors,
        'colors',
        _instance.colors,
      ),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R colors(List<Color>? value) {
    final res = call(colors: value);
    return res;
  }
}
''')
@Dataforge()
class NullableEnumListExample {
  final List<Color>? colors;

  NullableEnumListExample({this.colors});
}

@ShouldGenerate(r'''
mixin _MapEnumExample {
  abstract final Map<String, Color> colorMap;
  @pragma('vm:prefer-inline')
  MapEnumExampleCopyWith<MapEnumExample> get copyWith =>
      MapEnumExampleCopyWith<MapEnumExample>(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MapEnumExample) return false;

    if (!const DeepCollectionEquality().equals(colorMap, other.colorMap)) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hashAll([const DeepCollectionEquality().hash(colorMap)]);

  @override
  String toString() => 'MapEnumExample(colorMap: $colorMap)';

  Map<String, dynamic> toJson() {
    return {
      'colorMap': colorMap.map(
        (k, e) => MapEntry(
          k,
          const DefaultEnumConverter<Color>(Color.values).toJson(e),
        ),
      ),
    };
  }

  static MapEnumExample fromJson(Map<String, dynamic> json) {
    return MapEnumExample(
      colorMap:
          (((SafeCasteUtil.readValue<Map<String, dynamic>>(
            json,
            'colorMap',
          )?.map(
            (k, v) => MapEntry(
              k.toString(),
              (v is Color
                  ? v
                  : ((const DefaultEnumConverter<Color>(
                          Color.values,
                        ).fromJson(SafeCasteUtil.safeCast<String>(v))) ??
                        (throw ArgumentError(
                          'Required field "colorMap" (type: Color) is missing or invalid.',
                        )))),
            ),
          ))) ??
          (const {})),
    );
  }
}

class MapEnumExampleCopyWith<R> {
  final _MapEnumExample _instance;
  final R Function(MapEnumExample)? _then;
  // ignore: library_private_types_in_public_api
  MapEnumExampleCopyWith(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({Object? colorMap = dataforgeUndefined}) {
    final res = MapEnumExample(
      colorMap: SafeCasteUtil.copyWithCastMap<String, Color>(
        colorMap,
        'colorMap',
        _instance.colorMap,
      ),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R colorMap(Map<String, Color> value) {
    final res = call(colorMap: value);
    return res;
  }
}
''')
@Dataforge()
class MapEnumExample {
  final Map<String, Color> colorMap;

  MapEnumExample({this.colorMap = const {}});
}

@ShouldGenerate(r'''
mixin _BoolFieldsExample {
  abstract final bool isActive;
  abstract final bool? isVerified;
  abstract final bool hasAccess;
  @pragma('vm:prefer-inline')
  BoolFieldsExampleCopyWith<BoolFieldsExample> get copyWith =>
      BoolFieldsExampleCopyWith<BoolFieldsExample>(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BoolFieldsExample) return false;

    return other.isActive == isActive &&
        other.isVerified == isVerified &&
        other.hasAccess == hasAccess;
  }

  @override
  int get hashCode => Object.hashAll([isActive, isVerified, hasAccess]);

  @override
  String toString() =>
      'BoolFieldsExample(isActive: $isActive, isVerified: $isVerified, hasAccess: $hasAccess)';

  Map<String, dynamic> toJson() {
    return {
      'isActive': isActive,
      'isVerified': isVerified,
      'hasAccess': hasAccess,
    };
  }

  static BoolFieldsExample fromJson(Map<String, dynamic> json) {
    return BoolFieldsExample(
      isActive: SafeCasteUtil.readRequiredValue<bool>(json, 'isActive'),
      isVerified: SafeCasteUtil.readValue<bool>(json, 'isVerified'),
      hasAccess:
          ((SafeCasteUtil.readValue<bool>(json, 'hasAccess')) ?? (false)),
    );
  }
}

class BoolFieldsExampleCopyWith<R> {
  final _BoolFieldsExample _instance;
  final R Function(BoolFieldsExample)? _then;
  // ignore: library_private_types_in_public_api
  BoolFieldsExampleCopyWith(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({
    Object? isActive = dataforgeUndefined,
    Object? isVerified = dataforgeUndefined,
    Object? hasAccess = dataforgeUndefined,
  }) {
    final res = BoolFieldsExample(
      isActive: SafeCasteUtil.copyWithCast<bool>(
        isActive,
        'isActive',
        _instance.isActive,
      ),
      isVerified: SafeCasteUtil.copyWithCastNullable<bool>(
        isVerified,
        'isVerified',
        _instance.isVerified,
      ),
      hasAccess: SafeCasteUtil.copyWithCast<bool>(
        hasAccess,
        'hasAccess',
        _instance.hasAccess,
      ),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R isActive(bool value) {
    final res = call(isActive: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  R isVerified(bool? value) {
    final res = call(isVerified: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  R hasAccess(bool value) {
    final res = call(hasAccess: value);
    return res;
  }
}
''')
@Dataforge()
class BoolFieldsExample {
  final bool isActive;
  final bool? isVerified;
  final bool hasAccess;

  BoolFieldsExample({
    required this.isActive,
    this.isVerified,
    this.hasAccess = false,
  });
}

@ShouldGenerate(r'''
mixin _SingleFieldExample {
  abstract final String value;
  @pragma('vm:prefer-inline')
  SingleFieldExampleCopyWith<SingleFieldExample> get copyWith =>
      SingleFieldExampleCopyWith<SingleFieldExample>(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SingleFieldExample) return false;

    return other.value == value;
  }

  @override
  int get hashCode => Object.hashAll([value]);

  @override
  String toString() => 'SingleFieldExample(value: $value)';

  Map<String, dynamic> toJson() {
    return {'value': value};
  }

  static SingleFieldExample fromJson(Map<String, dynamic> json) {
    return SingleFieldExample(
      value: SafeCasteUtil.readRequiredValue<String>(json, 'value'),
    );
  }
}

class SingleFieldExampleCopyWith<R> {
  final _SingleFieldExample _instance;
  final R Function(SingleFieldExample)? _then;
  // ignore: library_private_types_in_public_api
  SingleFieldExampleCopyWith(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({Object? value = dataforgeUndefined}) {
    final res = SingleFieldExample(
      value: SafeCasteUtil.copyWithCast<String>(
        value,
        'value',
        _instance.value,
      ),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R value(String value) {
    final res = call(value: value);
    return res;
  }
}
''')
@Dataforge()
class SingleFieldExample {
  final String value;

  SingleFieldExample({required this.value});
}
