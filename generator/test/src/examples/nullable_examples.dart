import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:source_gen_test/annotations.dart';

@ShouldGenerate(r'''
mixin _NullableFieldsExample {
  abstract final String? nullableString;
  abstract final int? nullableInt;
  abstract final double? nullableDouble;
  abstract final bool? nullableBool;
  _NullableFieldsExampleCopyWith<NullableFieldsExample> get copyWith =>
      _NullableFieldsExampleCopyWith<NullableFieldsExample>._(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NullableFieldsExample) return false;

    return other.nullableString == nullableString &&
        other.nullableInt == nullableInt &&
        other.nullableDouble == nullableDouble &&
        other.nullableBool == nullableBool;
  }

  @override
  int get hashCode => Object.hashAll([
    nullableString,
    nullableInt,
    nullableDouble,
    nullableBool,
  ]);

  @override
  String toString() =>
      'NullableFieldsExample(nullableString: $nullableString, nullableInt: $nullableInt, nullableDouble: $nullableDouble, nullableBool: $nullableBool)';

  Map<String, dynamic> toJson() {
    return {
      'nullableString': nullableString,
      'nullableInt': nullableInt,
      'nullableDouble': nullableDouble,
      'nullableBool': nullableBool,
    };
  }

  static NullableFieldsExample fromJson(Map<String, dynamic> json) {
    return NullableFieldsExample(
      nullableString: SafeCasteUtil.readValue<String>(json, 'nullableString'),
      nullableInt: SafeCasteUtil.readValue<int>(json, 'nullableInt'),
      nullableDouble: SafeCasteUtil.readValue<double>(json, 'nullableDouble'),
      nullableBool: SafeCasteUtil.readValue<bool>(json, 'nullableBool'),
    );
  }
}

class _NullableFieldsExampleCopyWith<R> {
  final _NullableFieldsExample _instance;
  final R Function(NullableFieldsExample)? _then;
  _NullableFieldsExampleCopyWith._(this._instance, [this._then]);

  R call({
    Object? nullableString = dataforgeUndefined,
    Object? nullableInt = dataforgeUndefined,
    Object? nullableDouble = dataforgeUndefined,
    Object? nullableBool = dataforgeUndefined,
  }) {
    final res = NullableFieldsExample(
      nullableString: (nullableString == dataforgeUndefined
          ? _instance.nullableString
          : nullableString as String?),
      nullableInt: (nullableInt == dataforgeUndefined
          ? _instance.nullableInt
          : nullableInt as int?),
      nullableDouble: (nullableDouble == dataforgeUndefined
          ? _instance.nullableDouble
          : nullableDouble as double?),
      nullableBool: (nullableBool == dataforgeUndefined
          ? _instance.nullableBool
          : nullableBool as bool?),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  R nullableString(String? value) {
    final res = NullableFieldsExample(
      nullableString: value,
      nullableInt: _instance.nullableInt,
      nullableDouble: _instance.nullableDouble,
      nullableBool: _instance.nullableBool,
    );
    return (_then != null ? _then!(res) : res as R);
  }

  R nullableInt(int? value) {
    final res = NullableFieldsExample(
      nullableString: _instance.nullableString,
      nullableInt: value,
      nullableDouble: _instance.nullableDouble,
      nullableBool: _instance.nullableBool,
    );
    return (_then != null ? _then!(res) : res as R);
  }

  R nullableDouble(double? value) {
    final res = NullableFieldsExample(
      nullableString: _instance.nullableString,
      nullableInt: _instance.nullableInt,
      nullableDouble: value,
      nullableBool: _instance.nullableBool,
    );
    return (_then != null ? _then!(res) : res as R);
  }

  R nullableBool(bool? value) {
    final res = NullableFieldsExample(
      nullableString: _instance.nullableString,
      nullableInt: _instance.nullableInt,
      nullableDouble: _instance.nullableDouble,
      nullableBool: value,
    );
    return (_then != null ? _then!(res) : res as R);
  }
}
''')
@Dataforge()
class NullableFieldsExample {
  final String? nullableString;
  final int? nullableInt;
  final double? nullableDouble;
  final bool? nullableBool;

  NullableFieldsExample({
    this.nullableString,
    this.nullableInt,
    this.nullableDouble,
    this.nullableBool,
  });
}

@ShouldGenerate(r'''
mixin _RequiredNullableExample {
  abstract final String? nullableName;
  abstract final int? nullableAge;
  _RequiredNullableExampleCopyWith<RequiredNullableExample> get copyWith =>
      _RequiredNullableExampleCopyWith<RequiredNullableExample>._(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RequiredNullableExample) return false;

    return other.nullableName == nullableName &&
        other.nullableAge == nullableAge;
  }

  @override
  int get hashCode => Object.hashAll([nullableName, nullableAge]);

  @override
  String toString() =>
      'RequiredNullableExample(nullableName: $nullableName, nullableAge: $nullableAge)';

  Map<String, dynamic> toJson() {
    return {'nullableName': nullableName, 'nullableAge': nullableAge};
  }

  static RequiredNullableExample fromJson(Map<String, dynamic> json) {
    return RequiredNullableExample(
      nullableName: SafeCasteUtil.readValue<String>(json, 'nullableName'),
      nullableAge: SafeCasteUtil.readValue<int>(json, 'nullableAge'),
    );
  }
}

class _RequiredNullableExampleCopyWith<R> {
  final _RequiredNullableExample _instance;
  final R Function(RequiredNullableExample)? _then;
  _RequiredNullableExampleCopyWith._(this._instance, [this._then]);

  R call({
    Object? nullableName = dataforgeUndefined,
    Object? nullableAge = dataforgeUndefined,
  }) {
    final res = RequiredNullableExample(
      nullableName: (nullableName == dataforgeUndefined
          ? _instance.nullableName
          : nullableName as String?),
      nullableAge: (nullableAge == dataforgeUndefined
          ? _instance.nullableAge
          : nullableAge as int?),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  R nullableName(String? value) {
    final res = RequiredNullableExample(
      nullableName: value,
      nullableAge: _instance.nullableAge,
    );
    return (_then != null ? _then!(res) : res as R);
  }

  R nullableAge(int? value) {
    final res = RequiredNullableExample(
      nullableName: _instance.nullableName,
      nullableAge: value,
    );
    return (_then != null ? _then!(res) : res as R);
  }
}
''')
@Dataforge()
class RequiredNullableExample {
  final String? nullableName;
  final int? nullableAge;

  RequiredNullableExample({
    required this.nullableName,
    required this.nullableAge,
  });
}

@ShouldGenerate(r'''
mixin _NullableWithDefaultExample {
  abstract final String? name;
  abstract final int? count;
  _NullableWithDefaultExampleCopyWith<NullableWithDefaultExample>
  get copyWith =>
      _NullableWithDefaultExampleCopyWith<NullableWithDefaultExample>._(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NullableWithDefaultExample) return false;

    return other.name == name && other.count == count;
  }

  @override
  int get hashCode => Object.hashAll([name, count]);

  @override
  String toString() => 'NullableWithDefaultExample(name: $name, count: $count)';

  Map<String, dynamic> toJson() {
    return {'name': name, 'count': count};
  }

  static NullableWithDefaultExample fromJson(Map<String, dynamic> json) {
    return NullableWithDefaultExample(
      name: ((SafeCasteUtil.readValue<String>(json, 'name')) ?? ('default')),
      count: ((SafeCasteUtil.readValue<int>(json, 'count')) ?? (10)),
    );
  }
}

class _NullableWithDefaultExampleCopyWith<R> {
  final _NullableWithDefaultExample _instance;
  final R Function(NullableWithDefaultExample)? _then;
  _NullableWithDefaultExampleCopyWith._(this._instance, [this._then]);

  R call({
    Object? name = dataforgeUndefined,
    Object? count = dataforgeUndefined,
  }) {
    final res = NullableWithDefaultExample(
      name: (name == dataforgeUndefined ? _instance.name : name as String?),
      count: (count == dataforgeUndefined ? _instance.count : count as int?),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  R name(String? value) {
    final res = NullableWithDefaultExample(name: value, count: _instance.count);
    return (_then != null ? _then!(res) : res as R);
  }

  R count(int? value) {
    final res = NullableWithDefaultExample(name: _instance.name, count: value);
    return (_then != null ? _then!(res) : res as R);
  }
}
''')
@Dataforge()
class NullableWithDefaultExample {
  final String? name;
  final int? count;

  NullableWithDefaultExample({
    this.name = 'default',
    this.count = 10,
  });
}
