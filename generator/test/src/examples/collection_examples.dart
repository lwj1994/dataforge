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
  _ListObjectExampleCopyWith<ListObjectExample> get copyWith =>
      _ListObjectExampleCopyWith<ListObjectExample>._(this);

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
    return {'users': users};
  }

  static ListObjectExample fromJson(Map<String, dynamic> json) {
    return ListObjectExample(
      users:
          (SafeCasteUtil.readObjectList(json['users'], SimpleUser.fromJson) ??
          (const [])),
    );
  }
}

class _ListObjectExampleCopyWith<R> {
  final _ListObjectExample _instance;
  final R Function(ListObjectExample)? _then;
  _ListObjectExampleCopyWith._(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({Object? users = dataforgeUndefined}) {
    final res = ListObjectExample(
      users: (users == dataforgeUndefined
          ? _instance.users
          : (users as List).cast<SimpleUser>()),
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
  _ImageListModelCopyWith<ImageListModel> get copyWith =>
      _ImageListModelCopyWith<ImageListModel>._(this);

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
    return {'id': id, 'watermarkImages': watermarkImages};
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

class _ImageListModelCopyWith<R> {
  final _ImageListModel _instance;
  final R Function(ImageListModel)? _then;
  _ImageListModelCopyWith._(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({
    Object? id = dataforgeUndefined,
    Object? watermarkImages = dataforgeUndefined,
  }) {
    final res = ImageListModel(
      id: SafeCasteUtil.copyWithCast<String>(id, 'id', _instance.id),
      watermarkImages: (watermarkImages == dataforgeUndefined
          ? _instance.watermarkImages
          : (watermarkImages as List).cast<ImageBean>()),
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
  _RequiredListModelCopyWith<RequiredListModel> get copyWith =>
      _RequiredListModelCopyWith<RequiredListModel>._(this);

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
    return {'users': users};
  }

  static RequiredListModel fromJson(Map<String, dynamic> json) {
    return RequiredListModel(
      users:
          (SafeCasteUtil.readObjectList(json['users'], SimpleUser.fromJson) ??
          (const [])),
    );
  }
}

class _RequiredListModelCopyWith<R> {
  final _RequiredListModel _instance;
  final R Function(RequiredListModel)? _then;
  _RequiredListModelCopyWith._(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({Object? users = dataforgeUndefined}) {
    final res = RequiredListModel(
      users: (users == dataforgeUndefined
          ? _instance.users
          : (users as List).cast<SimpleUser>()),
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
  _ListPrimitiveExampleCopyWith<ListPrimitiveExample> get copyWith =>
      _ListPrimitiveExampleCopyWith<ListPrimitiveExample>._(this);

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

class _ListPrimitiveExampleCopyWith<R> {
  final _ListPrimitiveExample _instance;
  final R Function(ListPrimitiveExample)? _then;
  _ListPrimitiveExampleCopyWith._(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({
    Object? names = dataforgeUndefined,
    Object? numbers = dataforgeUndefined,
    Object? values = dataforgeUndefined,
    Object? flags = dataforgeUndefined,
  }) {
    final res = ListPrimitiveExample(
      names: (names == dataforgeUndefined
          ? _instance.names
          : (names as List).cast<String>()),
      numbers: (numbers == dataforgeUndefined
          ? _instance.numbers
          : (numbers as List).cast<int>()),
      values: (values == dataforgeUndefined
          ? _instance.values
          : (values as List).cast<double>()),
      flags: (flags == dataforgeUndefined
          ? _instance.flags
          : (flags as List).cast<bool>()),
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
  _NullableListExampleCopyWith<NullableListExample> get copyWith =>
      _NullableListExampleCopyWith<NullableListExample>._(this);

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

class _NullableListExampleCopyWith<R> {
  final _NullableListExample _instance;
  final R Function(NullableListExample)? _then;
  _NullableListExampleCopyWith._(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({
    Object? nullableNames = dataforgeUndefined,
    Object? nullableNumbers = dataforgeUndefined,
  }) {
    final res = NullableListExample(
      nullableNames: (nullableNames == dataforgeUndefined
          ? _instance.nullableNames
          : (nullableNames as List?)?.cast<String>()),
      nullableNumbers: (nullableNumbers == dataforgeUndefined
          ? _instance.nullableNumbers
          : (nullableNumbers as List?)?.cast<int>()),
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
  _MapStringExampleCopyWith<MapStringExample> get copyWith =>
      _MapStringExampleCopyWith<MapStringExample>._(this);

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

class _MapStringExampleCopyWith<R> {
  final _MapStringExample _instance;
  final R Function(MapStringExample)? _then;
  _MapStringExampleCopyWith._(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({
    Object? stringMap = dataforgeUndefined,
    Object? intMap = dataforgeUndefined,
    Object? dynamicMap = dataforgeUndefined,
  }) {
    final res = MapStringExample(
      stringMap: (stringMap == dataforgeUndefined
          ? _instance.stringMap
          : (stringMap as Map).cast<String, String>()),
      intMap: (intMap == dataforgeUndefined
          ? _instance.intMap
          : (intMap as Map).cast<String, int>()),
      dynamicMap: (dynamicMap == dataforgeUndefined
          ? _instance.dynamicMap
          : (dynamicMap as Map).cast<String, dynamic>()),
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
  _MapObjectExampleCopyWith<MapObjectExample> get copyWith =>
      _MapObjectExampleCopyWith<MapObjectExample>._(this);

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
    return {'userMap': userMap};
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

class _MapObjectExampleCopyWith<R> {
  final _MapObjectExample _instance;
  final R Function(MapObjectExample)? _then;
  _MapObjectExampleCopyWith._(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({Object? userMap = dataforgeUndefined}) {
    final res = MapObjectExample(
      userMap: (userMap == dataforgeUndefined
          ? _instance.userMap
          : (userMap as Map).cast<String, SimpleUser>()),
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
