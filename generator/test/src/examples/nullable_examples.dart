import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:source_gen_test/annotations.dart';

@ShouldGenerate(r'''
mixin _NullableFieldsExample {
  abstract final String? nullableString;
  abstract final int? nullableInt;
  abstract final double? nullableDouble;
  abstract final bool? nullableBool;
  @pragma('vm:prefer-inline')
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

  @pragma('vm:prefer-inline')
  R call({
    Object? nullableString = dataforgeUndefined,
    Object? nullableInt = dataforgeUndefined,
    Object? nullableDouble = dataforgeUndefined,
    Object? nullableBool = dataforgeUndefined,
  }) {
    final res = NullableFieldsExample(
      nullableString: SafeCasteUtil.copyWithCastNullable<String>(
        nullableString,
        'nullableString',
        _instance.nullableString,
      ),
      nullableInt: SafeCasteUtil.copyWithCastNullable<int>(
        nullableInt,
        'nullableInt',
        _instance.nullableInt,
      ),
      nullableDouble: SafeCasteUtil.copyWithCastNullable<double>(
        nullableDouble,
        'nullableDouble',
        _instance.nullableDouble,
      ),
      nullableBool: SafeCasteUtil.copyWithCastNullable<bool>(
        nullableBool,
        'nullableBool',
        _instance.nullableBool,
      ),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R nullableString(String? value) {
    final res = call(nullableString: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  R nullableInt(int? value) {
    final res = call(nullableInt: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  R nullableDouble(double? value) {
    final res = call(nullableDouble: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  R nullableBool(bool? value) {
    final res = call(nullableBool: value);
    return res;
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
  @pragma('vm:prefer-inline')
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

  @pragma('vm:prefer-inline')
  R call({
    Object? nullableName = dataforgeUndefined,
    Object? nullableAge = dataforgeUndefined,
  }) {
    final res = RequiredNullableExample(
      nullableName: SafeCasteUtil.copyWithCastNullable<String>(
        nullableName,
        'nullableName',
        _instance.nullableName,
      ),
      nullableAge: SafeCasteUtil.copyWithCastNullable<int>(
        nullableAge,
        'nullableAge',
        _instance.nullableAge,
      ),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R nullableName(String? value) {
    final res = call(nullableName: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  R nullableAge(int? value) {
    final res = call(nullableAge: value);
    return res;
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
  @pragma('vm:prefer-inline')
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

  @pragma('vm:prefer-inline')
  R call({
    Object? name = dataforgeUndefined,
    Object? count = dataforgeUndefined,
  }) {
    final res = NullableWithDefaultExample(
      name: SafeCasteUtil.copyWithCastNullable<String>(
        name,
        'name',
        _instance.name,
      ),
      count: SafeCasteUtil.copyWithCastNullable<int>(
        count,
        'count',
        _instance.count,
      ),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R name(String? value) {
    final res = call(name: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  R count(int? value) {
    final res = call(count: value);
    return res;
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
