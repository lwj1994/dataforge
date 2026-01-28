import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:dataforge_annotation/dataforge_annotation.dart' as df;
import 'package:source_gen_test/annotations.dart';

@ShouldGenerate(r'''
mixin _BasicUser {
  abstract final String name;
  abstract final int age;
  @pragma('vm:prefer-inline')
  _BasicUserCopyWith<BasicUser> get copyWith =>
      _BasicUserCopyWith<BasicUser>._(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BasicUser) return false;

    return other.name == name && other.age == age;
  }

  @override
  int get hashCode => Object.hashAll([name, age]);

  @override
  String toString() => 'BasicUser(name: $name, age: $age)';

  Map<String, dynamic> toJson() {
    return {'name': name, 'age': age};
  }

  static BasicUser fromJson(Map<String, dynamic> json) {
    return BasicUser(
      name: SafeCasteUtil.readRequiredValue<String>(json, 'name'),
      age: SafeCasteUtil.readRequiredValue<int>(json, 'age'),
    );
  }
}

class _BasicUserCopyWith<R> {
  final _BasicUser _instance;
  final R Function(BasicUser)? _then;
  _BasicUserCopyWith._(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({
    Object? name = dataforgeUndefined,
    Object? age = dataforgeUndefined,
  }) {
    final res = BasicUser(
      name: SafeCasteUtil.copyWithCast<String>(name, 'name', _instance.name),
      age: SafeCasteUtil.copyWithCast<int>(age, 'age', _instance.age),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R name(String value) {
    final res = call(name: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  R age(int value) {
    final res = call(age: value);
    return res;
  }
}
''')
@Dataforge()
class BasicUser {
  final String name;
  final int age;
  BasicUser({required this.name, required this.age});
}

@ShouldGenerate(r'''
mixin _DefaultValues {
  abstract final int intValue;
  abstract final String stringValue;
  abstract final bool boolValue;
  @pragma('vm:prefer-inline')
  _DefaultValuesCopyWith<DefaultValues> get copyWith =>
      _DefaultValuesCopyWith<DefaultValues>._(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DefaultValues) return false;

    return other.intValue == intValue &&
        other.stringValue == stringValue &&
        other.boolValue == boolValue;
  }

  @override
  int get hashCode => Object.hashAll([intValue, stringValue, boolValue]);

  @override
  String toString() =>
      'DefaultValues(intValue: $intValue, stringValue: $stringValue, boolValue: $boolValue)';

  Map<String, dynamic> toJson() {
    return {
      'intValue': intValue,
      'stringValue': stringValue,
      'boolValue': boolValue,
    };
  }

  static DefaultValues fromJson(Map<String, dynamic> json) {
    return DefaultValues(
      intValue: ((SafeCasteUtil.readValue<int>(json, 'intValue')) ?? (42)),
      stringValue:
          ((SafeCasteUtil.readValue<String>(json, 'stringValue')) ??
          ('default')),
      boolValue: ((SafeCasteUtil.readValue<bool>(json, 'boolValue')) ?? (true)),
    );
  }
}

class _DefaultValuesCopyWith<R> {
  final _DefaultValues _instance;
  final R Function(DefaultValues)? _then;
  _DefaultValuesCopyWith._(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({
    Object? intValue = dataforgeUndefined,
    Object? stringValue = dataforgeUndefined,
    Object? boolValue = dataforgeUndefined,
  }) {
    final res = DefaultValues(
      intValue: SafeCasteUtil.copyWithCast<int>(
        intValue,
        'intValue',
        _instance.intValue,
      ),
      stringValue: SafeCasteUtil.copyWithCast<String>(
        stringValue,
        'stringValue',
        _instance.stringValue,
      ),
      boolValue: SafeCasteUtil.copyWithCast<bool>(
        boolValue,
        'boolValue',
        _instance.boolValue,
      ),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R intValue(int value) {
    final res = call(intValue: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  R stringValue(String value) {
    final res = call(stringValue: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  R boolValue(bool value) {
    final res = call(boolValue: value);
    return res;
  }
}
''')
@Dataforge()
class DefaultValues {
  final int intValue;
  final String stringValue;
  final bool boolValue;

  const DefaultValues({
    this.intValue = 42,
    this.stringValue = 'default',
    this.boolValue = true,
  });
}

@ShouldGenerate(r'''
mixin _PrefixedExample {
  abstract final String name;
  @pragma('vm:prefer-inline')
  _PrefixedExampleCopyWith<PrefixedExample> get copyWith =>
      _PrefixedExampleCopyWith<PrefixedExample>._(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PrefixedExample) return false;

    return other.name == name;
  }

  @override
  int get hashCode => Object.hashAll([name]);

  @override
  String toString() => 'PrefixedExample(name: $name)';

  Map<String, dynamic> toJson() {
    return {'name': name};
  }

  static PrefixedExample fromJson(Map<String, dynamic> json) {
    return PrefixedExample(
      name: df.SafeCasteUtil.readRequiredValue<String>(json, 'name'),
    );
  }
}

class _PrefixedExampleCopyWith<R> {
  final _PrefixedExample _instance;
  final R Function(PrefixedExample)? _then;
  _PrefixedExampleCopyWith._(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({Object? name = df.dataforgeUndefined}) {
    final res = PrefixedExample(
      name: df.SafeCasteUtil.copyWithCast<String>(name, 'name', _instance.name),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R name(String value) {
    final res = call(name: value);
    return res;
  }
}
''')
@df.Dataforge()
class PrefixedExample {
  final String name;
  PrefixedExample({required this.name});
}

@ShouldGenerate(r'''
mixin _DoubleExample {
  abstract final double value;
  abstract final double? optionalValue;
  @pragma('vm:prefer-inline')
  _DoubleExampleCopyWith<DoubleExample> get copyWith =>
      _DoubleExampleCopyWith<DoubleExample>._(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DoubleExample) return false;

    return other.value == value && other.optionalValue == optionalValue;
  }

  @override
  int get hashCode => Object.hashAll([value, optionalValue]);

  @override
  String toString() =>
      'DoubleExample(value: $value, optionalValue: $optionalValue)';

  Map<String, dynamic> toJson() {
    return {'value': value, 'optionalValue': optionalValue};
  }

  static DoubleExample fromJson(Map<String, dynamic> json) {
    return DoubleExample(
      value: SafeCasteUtil.readRequiredValue<double>(json, 'value'),
      optionalValue: SafeCasteUtil.readValue<double>(json, 'optionalValue'),
    );
  }
}

class _DoubleExampleCopyWith<R> {
  final _DoubleExample _instance;
  final R Function(DoubleExample)? _then;
  _DoubleExampleCopyWith._(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({
    Object? value = dataforgeUndefined,
    Object? optionalValue = dataforgeUndefined,
  }) {
    final res = DoubleExample(
      value: SafeCasteUtil.copyWithCast<double>(
        value,
        'value',
        _instance.value,
      ),
      optionalValue: SafeCasteUtil.copyWithCastNullable<double>(
        optionalValue,
        'optionalValue',
        _instance.optionalValue,
      ),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R value(double value) {
    final res = call(value: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  R optionalValue(double? value) {
    final res = call(optionalValue: value);
    return res;
  }
}
''')
@Dataforge()
class DoubleExample {
  final double value;
  final double? optionalValue;
  DoubleExample({required this.value, this.optionalValue});
}

@ShouldGenerate(r'''
mixin _NumExample {
  abstract final num value;
  abstract final num? optionalValue;
  @pragma('vm:prefer-inline')
  _NumExampleCopyWith<NumExample> get copyWith =>
      _NumExampleCopyWith<NumExample>._(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NumExample) return false;

    return other.value == value && other.optionalValue == optionalValue;
  }

  @override
  int get hashCode => Object.hashAll([value, optionalValue]);

  @override
  String toString() =>
      'NumExample(value: $value, optionalValue: $optionalValue)';

  Map<String, dynamic> toJson() {
    return {'value': value, 'optionalValue': optionalValue};
  }

  static NumExample fromJson(Map<String, dynamic> json) {
    return NumExample(
      value: json['value'],
      optionalValue: json['optionalValue'],
    );
  }
}

class _NumExampleCopyWith<R> {
  final _NumExample _instance;
  final R Function(NumExample)? _then;
  _NumExampleCopyWith._(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({
    Object? value = dataforgeUndefined,
    Object? optionalValue = dataforgeUndefined,
  }) {
    final res = NumExample(
      value: SafeCasteUtil.copyWithCast<num>(value, 'value', _instance.value),
      optionalValue: SafeCasteUtil.copyWithCastNullable<num>(
        optionalValue,
        'optionalValue',
        _instance.optionalValue,
      ),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R value(num value) {
    final res = call(value: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  R optionalValue(num? value) {
    final res = call(optionalValue: value);
    return res;
  }
}
''')
@Dataforge()
class NumExample {
  final num value;
  final num? optionalValue;
  NumExample({required this.value, this.optionalValue});
}
