import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:source_gen_test/annotations.dart';

// Helper class for collection tests
@Dataforge()
class SimpleUser {
  final String name;
  final int age;
  SimpleUser({required this.name, required this.age});
}

@ShouldGenerate(r'''
mixin _ListObjectExample {
  abstract final List<SimpleUser> users;
  @pragma('vm:prefer-inline')
  ListObjectExampleCopyWith<ListObjectExample> get copyWith =>
      ListObjectExampleCopyWith<ListObjectExample>(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ListObjectExample) return false;

    if (!const DeepCollectionEquality().equals(users, other.users)) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hashAll([const DeepCollectionEquality().hash(users)]);

  @override
  String toString() => 'ListObjectExample(users: $users)';

  Map<String, dynamic> toJson() {
    return {'users': users.map((e) => e.toJson()).toList()};
  }

  static ListObjectExample fromJson(Map<String, dynamic> json) {
    return ListObjectExample(
      users:
          (SafeCasteUtil.readObjectList(json['users'], SimpleUser.fromJson) ??
          (const [])),
    );
  }
}

class ListObjectExampleCopyWith<R> {
  final _ListObjectExample _instance;
  final R Function(ListObjectExample)? _then;
  // ignore: library_private_types_in_public_api
  ListObjectExampleCopyWith(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({Object? users = dataforgeUndefined}) {
    final res = ListObjectExample(
      users: SafeCasteUtil.copyWithCastList<SimpleUser>(
        users,
        'users',
        _instance.users,
      ),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R users(List<SimpleUser> value) {
    final res = call(users: value);
    return res;
  }
}
''')
@Dataforge()
class ListObjectExample {
  final List<SimpleUser> users;
  ListObjectExample({this.users = const []});
}

@Dataforge()
class ImageBean {
  final String url;
  ImageBean({required this.url});
}

@ShouldGenerate(r'''
mixin _ImageListModel {
  abstract final String id;
  abstract final List<ImageBean> watermarkImages;
  @pragma('vm:prefer-inline')
  ImageListModelCopyWith<ImageListModel> get copyWith =>
      ImageListModelCopyWith<ImageListModel>(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ImageListModel) return false;

    if (id != other.id) {
      return false;
    }
    if (!const DeepCollectionEquality().equals(
      watermarkImages,
      other.watermarkImages,
    )) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    const DeepCollectionEquality().hash(watermarkImages),
  ]);

  @override
  String toString() =>
      'ImageListModel(id: $id, watermarkImages: $watermarkImages)';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'watermarkImages': watermarkImages.map((e) => e.toJson()).toList(),
    };
  }

  static ImageListModel fromJson(Map<String, dynamic> json) {
    return ImageListModel(
      id: SafeCasteUtil.readRequiredValue<String>(json, 'id'),
      watermarkImages:
          (SafeCasteUtil.readObjectList(
            ImageListModel._readValue(json, 'watermarkImages'),
            ImageBean.fromJson,
          ) ??
          (const [])),
    );
  }
}

class ImageListModelCopyWith<R> {
  final _ImageListModel _instance;
  final R Function(ImageListModel)? _then;
  // ignore: library_private_types_in_public_api
  ImageListModelCopyWith(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({
    Object? id = dataforgeUndefined,
    Object? watermarkImages = dataforgeUndefined,
  }) {
    final res = ImageListModel(
      id: SafeCasteUtil.copyWithCast<String>(id, 'id', _instance.id),
      watermarkImages: SafeCasteUtil.copyWithCastList<ImageBean>(
        watermarkImages,
        'watermarkImages',
        _instance.watermarkImages,
      ),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R id(String value) {
    final res = call(id: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  R watermarkImages(List<ImageBean> value) {
    final res = call(watermarkImages: value);
    return res;
  }
}
''')
@Dataforge()
class ImageListModel {
  final String id;
  @JsonKey(readValue: ImageListModel._readValue)
  final List<ImageBean> watermarkImages;

  ImageListModel({required this.id, this.watermarkImages = const []});

  static Object? _readValue(Map<dynamic, dynamic> map, String key) {
    return map[key];
  }
}

@ShouldGenerate(r'''
mixin _RequiredListModel {
  abstract final List<SimpleUser> users;
  @pragma('vm:prefer-inline')
  RequiredListModelCopyWith<RequiredListModel> get copyWith =>
      RequiredListModelCopyWith<RequiredListModel>(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RequiredListModel) return false;

    if (!const DeepCollectionEquality().equals(users, other.users)) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hashAll([const DeepCollectionEquality().hash(users)]);

  @override
  String toString() => 'RequiredListModel(users: $users)';

  Map<String, dynamic> toJson() {
    return {'users': users.map((e) => e.toJson()).toList()};
  }

  static RequiredListModel fromJson(Map<String, dynamic> json) {
    return RequiredListModel(
      users:
          (SafeCasteUtil.readObjectList(json['users'], SimpleUser.fromJson) ??
          (const [])),
    );
  }
}

class RequiredListModelCopyWith<R> {
  final _RequiredListModel _instance;
  final R Function(RequiredListModel)? _then;
  // ignore: library_private_types_in_public_api
  RequiredListModelCopyWith(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({Object? users = dataforgeUndefined}) {
    final res = RequiredListModel(
      users: SafeCasteUtil.copyWithCastList<SimpleUser>(
        users,
        'users',
        _instance.users,
      ),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R users(List<SimpleUser> value) {
    final res = call(users: value);
    return res;
  }
}
''')
@Dataforge()
class RequiredListModel {
  final List<SimpleUser> users;
  RequiredListModel({required this.users});
}

@ShouldGenerate(r'''
mixin _ListPrimitiveExample {
  abstract final List<String> names;
  abstract final List<int> numbers;
  abstract final List<double> values;
  abstract final List<bool> flags;
  @pragma('vm:prefer-inline')
  ListPrimitiveExampleCopyWith<ListPrimitiveExample> get copyWith =>
      ListPrimitiveExampleCopyWith<ListPrimitiveExample>(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ListPrimitiveExample) return false;

    if (!const DeepCollectionEquality().equals(names, other.names)) {
      return false;
    }
    if (!const DeepCollectionEquality().equals(numbers, other.numbers)) {
      return false;
    }
    if (!const DeepCollectionEquality().equals(values, other.values)) {
      return false;
    }
    if (!const DeepCollectionEquality().equals(flags, other.flags)) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([
    const DeepCollectionEquality().hash(names),
    const DeepCollectionEquality().hash(numbers),
    const DeepCollectionEquality().hash(values),
    const DeepCollectionEquality().hash(flags),
  ]);

  @override
  String toString() =>
      'ListPrimitiveExample(names: $names, numbers: $numbers, values: $values, flags: $flags)';

  Map<String, dynamic> toJson() {
    return {
      'names': names,
      'numbers': numbers,
      'values': values,
      'flags': flags,
    };
  }

  static ListPrimitiveExample fromJson(Map<String, dynamic> json) {
    return ListPrimitiveExample(
      names:
          (((SafeCasteUtil.readValue<List<dynamic>>(
            json,
            'names',
          )?.map((e) => (SafeCasteUtil.safeCast<String>(e) ?? '')).toList())) ??
          (const [])),
      numbers:
          (((SafeCasteUtil.readValue<List<dynamic>>(
            json,
            'numbers',
          )?.map((e) => (SafeCasteUtil.safeCast<int>(e) ?? 0)).toList())) ??
          (const [])),
      values:
          (((SafeCasteUtil.readValue<List<dynamic>>(json, 'values')
              ?.map((e) => (SafeCasteUtil.safeCast<double>(e) ?? 0.0))
              .toList())) ??
          (const [])),
      flags:
          (((SafeCasteUtil.readValue<List<dynamic>>(json, 'flags')
              ?.map((e) => (SafeCasteUtil.safeCast<bool>(e) ?? false))
              .toList())) ??
          (const [])),
    );
  }
}

class ListPrimitiveExampleCopyWith<R> {
  final _ListPrimitiveExample _instance;
  final R Function(ListPrimitiveExample)? _then;
  // ignore: library_private_types_in_public_api
  ListPrimitiveExampleCopyWith(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({
    Object? names = dataforgeUndefined,
    Object? numbers = dataforgeUndefined,
    Object? values = dataforgeUndefined,
    Object? flags = dataforgeUndefined,
  }) {
    final res = ListPrimitiveExample(
      names: SafeCasteUtil.copyWithCastList<String>(
        names,
        'names',
        _instance.names,
      ),
      numbers: SafeCasteUtil.copyWithCastList<int>(
        numbers,
        'numbers',
        _instance.numbers,
      ),
      values: SafeCasteUtil.copyWithCastList<double>(
        values,
        'values',
        _instance.values,
      ),
      flags: SafeCasteUtil.copyWithCastList<bool>(
        flags,
        'flags',
        _instance.flags,
      ),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R names(List<String> value) {
    final res = call(names: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  R numbers(List<int> value) {
    final res = call(numbers: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  R values(List<double> value) {
    final res = call(values: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  R flags(List<bool> value) {
    final res = call(flags: value);
    return res;
  }
}
''')
@Dataforge()
class ListPrimitiveExample {
  final List<String> names;
  final List<int> numbers;
  final List<double> values;
  final List<bool> flags;

  ListPrimitiveExample({
    this.names = const [],
    this.numbers = const [],
    this.values = const [],
    this.flags = const [],
  });
}

@ShouldGenerate(r'''
mixin _NullableListExample {
  abstract final List<String>? nullableNames;
  abstract final List<int>? nullableNumbers;
  @pragma('vm:prefer-inline')
  NullableListExampleCopyWith<NullableListExample> get copyWith =>
      NullableListExampleCopyWith<NullableListExample>(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NullableListExample) return false;

    if (!const DeepCollectionEquality().equals(
      nullableNames,
      other.nullableNames,
    )) {
      return false;
    }
    if (!const DeepCollectionEquality().equals(
      nullableNumbers,
      other.nullableNumbers,
    )) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([
    const DeepCollectionEquality().hash(nullableNames),
    const DeepCollectionEquality().hash(nullableNumbers),
  ]);

  @override
  String toString() =>
      'NullableListExample(nullableNames: $nullableNames, nullableNumbers: $nullableNumbers)';

  Map<String, dynamic> toJson() {
    return {'nullableNames': nullableNames, 'nullableNumbers': nullableNumbers};
  }

  static NullableListExample fromJson(Map<String, dynamic> json) {
    return NullableListExample(
      nullableNames: ((SafeCasteUtil.readValue<List<dynamic>>(
        json,
        'nullableNames',
      )?.map((e) => (SafeCasteUtil.safeCast<String>(e) ?? '')).toList())),
      nullableNumbers: ((SafeCasteUtil.readValue<List<dynamic>>(
        json,
        'nullableNumbers',
      )?.map((e) => (SafeCasteUtil.safeCast<int>(e) ?? 0)).toList())),
    );
  }
}

class NullableListExampleCopyWith<R> {
  final _NullableListExample _instance;
  final R Function(NullableListExample)? _then;
  // ignore: library_private_types_in_public_api
  NullableListExampleCopyWith(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({
    Object? nullableNames = dataforgeUndefined,
    Object? nullableNumbers = dataforgeUndefined,
  }) {
    final res = NullableListExample(
      nullableNames: SafeCasteUtil.copyWithCastNullableList<String>(
        nullableNames,
        'nullableNames',
        _instance.nullableNames,
      ),
      nullableNumbers: SafeCasteUtil.copyWithCastNullableList<int>(
        nullableNumbers,
        'nullableNumbers',
        _instance.nullableNumbers,
      ),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R nullableNames(List<String>? value) {
    final res = call(nullableNames: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  R nullableNumbers(List<int>? value) {
    final res = call(nullableNumbers: value);
    return res;
  }
}
''')
@Dataforge()
class NullableListExample {
  final List<String>? nullableNames;
  final List<int>? nullableNumbers;

  NullableListExample({
    this.nullableNames,
    this.nullableNumbers,
  });
}

@ShouldGenerate(r'''
mixin _MapStringExample {
  abstract final Map<String, String> stringMap;
  abstract final Map<String, int> intMap;
  abstract final Map<String, dynamic> dynamicMap;
  @pragma('vm:prefer-inline')
  MapStringExampleCopyWith<MapStringExample> get copyWith =>
      MapStringExampleCopyWith<MapStringExample>(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MapStringExample) return false;

    if (!const DeepCollectionEquality().equals(stringMap, other.stringMap)) {
      return false;
    }
    if (!const DeepCollectionEquality().equals(intMap, other.intMap)) {
      return false;
    }
    if (!const DeepCollectionEquality().equals(dynamicMap, other.dynamicMap)) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([
    const DeepCollectionEquality().hash(stringMap),
    const DeepCollectionEquality().hash(intMap),
    const DeepCollectionEquality().hash(dynamicMap),
  ]);

  @override
  String toString() =>
      'MapStringExample(stringMap: $stringMap, intMap: $intMap, dynamicMap: $dynamicMap)';

  Map<String, dynamic> toJson() {
    return {'stringMap': stringMap, 'intMap': intMap, 'dynamicMap': dynamicMap};
  }

  static MapStringExample fromJson(Map<String, dynamic> json) {
    return MapStringExample(
      stringMap:
          ((SafeCasteUtil.readValue<Map<String, dynamic>>(
            json,
            'stringMap',
          )?.cast<String, String>()) ??
          (const {})),
      intMap:
          ((SafeCasteUtil.readValue<Map<String, dynamic>>(
            json,
            'intMap',
          )?.cast<String, int>()) ??
          (const {})),
      dynamicMap:
          ((SafeCasteUtil.readValue<Map<String, dynamic>>(
            json,
            'dynamicMap',
          )?.cast<String, dynamic>()) ??
          (const {})),
    );
  }
}

class MapStringExampleCopyWith<R> {
  final _MapStringExample _instance;
  final R Function(MapStringExample)? _then;
  // ignore: library_private_types_in_public_api
  MapStringExampleCopyWith(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({
    Object? stringMap = dataforgeUndefined,
    Object? intMap = dataforgeUndefined,
    Object? dynamicMap = dataforgeUndefined,
  }) {
    final res = MapStringExample(
      stringMap: SafeCasteUtil.copyWithCastMap<String, String>(
        stringMap,
        'stringMap',
        _instance.stringMap,
      ),
      intMap: SafeCasteUtil.copyWithCastMap<String, int>(
        intMap,
        'intMap',
        _instance.intMap,
      ),
      dynamicMap: SafeCasteUtil.copyWithCastMap<String, dynamic>(
        dynamicMap,
        'dynamicMap',
        _instance.dynamicMap,
      ),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R stringMap(Map<String, String> value) {
    final res = call(stringMap: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  R intMap(Map<String, int> value) {
    final res = call(intMap: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  R dynamicMap(Map<String, dynamic> value) {
    final res = call(dynamicMap: value);
    return res;
  }
}
''')
@Dataforge()
class MapStringExample {
  final Map<String, String> stringMap;
  final Map<String, int> intMap;
  final Map<String, dynamic> dynamicMap;

  MapStringExample({
    this.stringMap = const {},
    this.intMap = const {},
    this.dynamicMap = const {},
  });
}

@ShouldGenerate(r'''
mixin _MapObjectExample {
  abstract final Map<String, SimpleUser> userMap;
  @pragma('vm:prefer-inline')
  MapObjectExampleCopyWith<MapObjectExample> get copyWith =>
      MapObjectExampleCopyWith<MapObjectExample>(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MapObjectExample) return false;

    if (!const DeepCollectionEquality().equals(userMap, other.userMap)) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hashAll([const DeepCollectionEquality().hash(userMap)]);

  @override
  String toString() => 'MapObjectExample(userMap: $userMap)';

  Map<String, dynamic> toJson() {
    return {'userMap': userMap.map((k, v) => MapEntry(k, v.toJson()))};
  }

  static MapObjectExample fromJson(Map<String, dynamic> json) {
    return MapObjectExample(
      userMap:
          (((SafeCasteUtil.readValue<Map<String, dynamic>>(
            json,
            'userMap',
          )?.map(
            (k, v) => MapEntry(
              k.toString(),
              (SimpleUser.fromJson(v as Map<String, dynamic>)),
            ),
          ))) ??
          (const {})),
    );
  }
}

class MapObjectExampleCopyWith<R> {
  final _MapObjectExample _instance;
  final R Function(MapObjectExample)? _then;
  // ignore: library_private_types_in_public_api
  MapObjectExampleCopyWith(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({Object? userMap = dataforgeUndefined}) {
    final res = MapObjectExample(
      userMap: SafeCasteUtil.copyWithCastMap<String, SimpleUser>(
        userMap,
        'userMap',
        _instance.userMap,
      ),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R userMap(Map<String, SimpleUser> value) {
    final res = call(userMap: value);
    return res;
  }
}
''')
@Dataforge()
class MapObjectExample {
  final Map<String, SimpleUser> userMap;

  MapObjectExample({
    this.userMap = const {},
  });
}

enum SimpleStatus { active, inactive }

@ShouldGenerate(r'''
mixin _SetPrimitiveExample {
  abstract final Set<String> tags;
  @pragma('vm:prefer-inline')
  SetPrimitiveExampleCopyWith<SetPrimitiveExample> get copyWith =>
      SetPrimitiveExampleCopyWith<SetPrimitiveExample>(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SetPrimitiveExample) return false;

    if (!const DeepCollectionEquality().equals(tags, other.tags)) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hashAll([const DeepCollectionEquality().hash(tags)]);

  @override
  String toString() => 'SetPrimitiveExample(tags: $tags)';

  Map<String, dynamic> toJson() {
    return {'tags': tags.toList()};
  }

  static SetPrimitiveExample fromJson(Map<String, dynamic> json) {
    return SetPrimitiveExample(
      tags: (SafeCasteUtil.readRequiredValue<List<dynamic>>(
        json,
        'tags',
      ).map((e) => (SafeCasteUtil.safeCast<String>(e) ?? '')).toSet()),
    );
  }
}

class SetPrimitiveExampleCopyWith<R> {
  final _SetPrimitiveExample _instance;
  final R Function(SetPrimitiveExample)? _then;
  // ignore: library_private_types_in_public_api
  SetPrimitiveExampleCopyWith(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({Object? tags = dataforgeUndefined}) {
    final res = SetPrimitiveExample(
      tags: SafeCasteUtil.copyWithCastSet<String>(tags, 'tags', _instance.tags),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R tags(Set<String> value) {
    final res = call(tags: value);
    return res;
  }
}
''')
@Dataforge()
class SetPrimitiveExample {
  final Set<String> tags;

  SetPrimitiveExample({required this.tags});
}

@ShouldGenerate(r'''
mixin _SetEnumExample {
  abstract final Set<SimpleStatus> statuses;
  @pragma('vm:prefer-inline')
  SetEnumExampleCopyWith<SetEnumExample> get copyWith =>
      SetEnumExampleCopyWith<SetEnumExample>(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SetEnumExample) return false;

    if (!const DeepCollectionEquality().equals(statuses, other.statuses)) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hashAll([const DeepCollectionEquality().hash(statuses)]);

  @override
  String toString() => 'SetEnumExample(statuses: $statuses)';

  Map<String, dynamic> toJson() {
    return {
      'statuses': statuses
          .map(
            (e) => const DefaultEnumConverter<SimpleStatus>(
              SimpleStatus.values,
            ).toJson(e),
          )
          .toList(),
    };
  }

  static SetEnumExample fromJson(Map<String, dynamic> json) {
    return SetEnumExample(
      statuses: (SafeCasteUtil.readRequiredValue<List<dynamic>>(json, 'statuses')
          .map(
            (e) => (e is SimpleStatus
                ? e
                : ((const DefaultEnumConverter<SimpleStatus>(
                        SimpleStatus.values,
                      ).fromJson(SafeCasteUtil.safeCast<String>(e))) ??
                      (throw ArgumentError(
                        'Required field "statuses" (type: SimpleStatus) is missing or invalid.',
                      )))),
          )
          .toSet()),
    );
  }
}

class SetEnumExampleCopyWith<R> {
  final _SetEnumExample _instance;
  final R Function(SetEnumExample)? _then;
  // ignore: library_private_types_in_public_api
  SetEnumExampleCopyWith(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({Object? statuses = dataforgeUndefined}) {
    final res = SetEnumExample(
      statuses: SafeCasteUtil.copyWithCastSet<SimpleStatus>(
        statuses,
        'statuses',
        _instance.statuses,
      ),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R statuses(Set<SimpleStatus> value) {
    final res = call(statuses: value);
    return res;
  }
}
''')
@Dataforge()
class SetEnumExample {
  final Set<SimpleStatus> statuses;

  SetEnumExample({required this.statuses});
}
