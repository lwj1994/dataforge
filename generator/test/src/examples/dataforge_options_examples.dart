import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:source_gen_test/annotations.dart';

@ShouldGenerate(r'''
mixin _NoFromJsonExample {
  abstract final String name;
  abstract final int age;
  @pragma('vm:prefer-inline')
  _NoFromJsonExampleCopyWith<NoFromJsonExample> get copyWith =>
      _NoFromJsonExampleCopyWith<NoFromJsonExample>._(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NoFromJsonExample) return false;

    return other.name == name && other.age == age;
  }

  @override
  int get hashCode => Object.hashAll([name, age]);

  @override
  String toString() => 'NoFromJsonExample(name: $name, age: $age)';

  Map<String, dynamic> toJson() {
    return {'name': name, 'age': age};
  }
}

class _NoFromJsonExampleCopyWith<R> {
  final _NoFromJsonExample _instance;
  final R Function(NoFromJsonExample)? _then;
  _NoFromJsonExampleCopyWith._(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({
    Object? name = dataforgeUndefined,
    Object? age = dataforgeUndefined,
  }) {
    final res = NoFromJsonExample(
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
@Dataforge(includeFromJson: false)
class NoFromJsonExample {
  final String name;
  final int age;

  NoFromJsonExample({required this.name, required this.age});
}

@ShouldGenerate(r'''
mixin _NoToJsonExample {
  abstract final String name;
  abstract final int age;
  @pragma('vm:prefer-inline')
  _NoToJsonExampleCopyWith<NoToJsonExample> get copyWith =>
      _NoToJsonExampleCopyWith<NoToJsonExample>._(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NoToJsonExample) return false;

    return other.name == name && other.age == age;
  }

  @override
  int get hashCode => Object.hashAll([name, age]);

  @override
  String toString() => 'NoToJsonExample(name: $name, age: $age)';

  static NoToJsonExample fromJson(Map<String, dynamic> json) {
    return NoToJsonExample(
      name: SafeCasteUtil.readRequiredValue<String>(json, 'name'),
      age: SafeCasteUtil.readRequiredValue<int>(json, 'age'),
    );
  }
}

class _NoToJsonExampleCopyWith<R> {
  final _NoToJsonExample _instance;
  final R Function(NoToJsonExample)? _then;
  _NoToJsonExampleCopyWith._(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({
    Object? name = dataforgeUndefined,
    Object? age = dataforgeUndefined,
  }) {
    final res = NoToJsonExample(
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
@Dataforge(includeToJson: false)
class NoToJsonExample {
  final String name;
  final int age;

  NoToJsonExample({required this.name, required this.age});
}

@ShouldGenerate(r'''
mixin _NoJsonExample {
  abstract final String name;
  abstract final int age;
  @pragma('vm:prefer-inline')
  _NoJsonExampleCopyWith<NoJsonExample> get copyWith =>
      _NoJsonExampleCopyWith<NoJsonExample>._(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NoJsonExample) return false;

    return other.name == name && other.age == age;
  }

  @override
  int get hashCode => Object.hashAll([name, age]);

  @override
  String toString() => 'NoJsonExample(name: $name, age: $age)';
}

class _NoJsonExampleCopyWith<R> {
  final _NoJsonExample _instance;
  final R Function(NoJsonExample)? _then;
  _NoJsonExampleCopyWith._(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({
    Object? name = dataforgeUndefined,
    Object? age = dataforgeUndefined,
  }) {
    final res = NoJsonExample(
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
@Dataforge(includeFromJson: false, includeToJson: false)
class NoJsonExample {
  final String name;
  final int age;

  NoJsonExample({required this.name, required this.age});
}

@ShouldGenerate(r'''
mixin _NoCopyWithChainExample {
  abstract final String name;
  abstract final int age;
  @pragma('vm:prefer-inline')
  NoCopyWithChainExample copyWith({String? name, int? age}) {
    return NoCopyWithChainExample(
      name: (name ?? this.name),
      age: (age ?? this.age),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NoCopyWithChainExample) return false;

    return other.name == name && other.age == age;
  }

  @override
  int get hashCode => Object.hashAll([name, age]);

  @override
  String toString() => 'NoCopyWithChainExample(name: $name, age: $age)';

  Map<String, dynamic> toJson() {
    return {'name': name, 'age': age};
  }

  static NoCopyWithChainExample fromJson(Map<String, dynamic> json) {
    return NoCopyWithChainExample(
      name: SafeCasteUtil.readRequiredValue<String>(json, 'name'),
      age: SafeCasteUtil.readRequiredValue<int>(json, 'age'),
    );
  }
}
''')
@Dataforge(deepCopyWith: false)
class NoCopyWithChainExample {
  final String name;
  final int age;

  NoCopyWithChainExample({required this.name, required this.age});
}

@ShouldGenerate(r'''
mixin _CustomMixinName {
  abstract final String value;
  @pragma('vm:prefer-inline')
  _CustomMixinNameCopyWith<CustomMixinName> get copyWith =>
      _CustomMixinNameCopyWith<CustomMixinName>._(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CustomMixinName) return false;

    return other.value == value;
  }

  @override
  int get hashCode => Object.hashAll([value]);

  @override
  String toString() => 'CustomMixinName(value: $value)';

  Map<String, dynamic> toJson() {
    return {'value': value};
  }

  static CustomMixinName fromJson(Map<String, dynamic> json) {
    return CustomMixinName(
      value: SafeCasteUtil.readRequiredValue<String>(json, 'value'),
    );
  }
}

class _CustomMixinNameCopyWith<R> {
  final _CustomMixinName _instance;
  final R Function(CustomMixinName)? _then;
  _CustomMixinNameCopyWith._(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({Object? value = dataforgeUndefined}) {
    final res = CustomMixinName(
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
@Dataforge(name: 'CustomMixinName')
class CustomMixinName {
  final String value;

  CustomMixinName({required this.value});
}
