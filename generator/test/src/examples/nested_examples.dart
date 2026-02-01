import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:source_gen_test/annotations.dart';

// Helper classes for nested tests
@Dataforge()
class InnerUser {
  final String name;
  final int age;
  InnerUser({required this.name, required this.age});
}

@Dataforge()
class InnerDefaultValues {
  final int intValue;
  final String stringValue;
  final bool boolValue;

  const InnerDefaultValues({
    this.intValue = 42,
    this.stringValue = 'default',
    this.boolValue = true,
  });
}

@ShouldGenerate(r'''
mixin _NestedDefaultValues {
  abstract final String name;
  abstract final InnerDefaultValues nested;
  @pragma('vm:prefer-inline')
  NestedDefaultValuesCopyWith<NestedDefaultValues> get copyWith =>
      NestedDefaultValuesCopyWith<NestedDefaultValues>(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NestedDefaultValues) return false;

    return other.name == name && other.nested == nested;
  }

  @override
  int get hashCode => Object.hashAll([name, nested]);

  @override
  String toString() => 'NestedDefaultValues(name: $name, nested: $nested)';

  Map<String, dynamic> toJson() {
    return {'name': name, 'nested': nested};
  }

  static NestedDefaultValues fromJson(Map<String, dynamic> json) {
    return NestedDefaultValues(
      name:
          ((SafeCasteUtil.readValue<String>(json, 'name')) ??
          ('nested_default')),
      nested:
          ((SafeCasteUtil.readObject(
            json['nested'],
            InnerDefaultValues.fromJson,
          )) ??
          (const InnerDefaultValues())),
    );
  }
}

class NestedDefaultValuesCopyWith<R> {
  final _NestedDefaultValues _instance;
  final R Function(NestedDefaultValues)? _then;
  NestedDefaultValuesCopyWith(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({
    Object? name = dataforgeUndefined,
    Object? nested = dataforgeUndefined,
  }) {
    final res = NestedDefaultValues(
      name: SafeCasteUtil.copyWithCast<String>(name, 'name', _instance.name),
      nested: SafeCasteUtil.copyWithCast<InnerDefaultValues>(
        nested,
        'nested',
        _instance.nested,
      ),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R name(String value) {
    final res = call(name: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  R nested(InnerDefaultValues value) {
    final res = call(nested: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  InnerDefaultValuesCopyWith<R> get $nested =>
      InnerDefaultValuesCopyWith<R>(
        _instance.nested,
        (v) => call(nested: v),
      );
}
''')
@Dataforge()
class NestedDefaultValues {
  final String name;
  final InnerDefaultValues nested;
  NestedDefaultValues({
    this.name = 'nested_default',
    this.nested = const InnerDefaultValues(),
  });
}

@ShouldGenerate(r'''
mixin _ChainedExample {
  abstract final String id;
  abstract final InnerUser user;
  @pragma('vm:prefer-inline')
  ChainedExampleCopyWith<ChainedExample> get copyWith =>
      ChainedExampleCopyWith<ChainedExample>(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ChainedExample) return false;

    return other.id == id && other.user == user;
  }

  @override
  int get hashCode => Object.hashAll([id, user]);

  @override
  String toString() => 'ChainedExample(id: $id, user: $user)';

  Map<String, dynamic> toJson() {
    return {'id': id, 'user': user};
  }

  static ChainedExample fromJson(Map<String, dynamic> json) {
    return ChainedExample(
      id: SafeCasteUtil.readRequiredValue<String>(json, 'id'),
      user: SafeCasteUtil.readRequiredObject(json['user'], InnerUser.fromJson),
    );
  }
}

class ChainedExampleCopyWith<R> {
  final _ChainedExample _instance;
  final R Function(ChainedExample)? _then;
  ChainedExampleCopyWith(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({Object? id = dataforgeUndefined, Object? user = dataforgeUndefined}) {
    final res = ChainedExample(
      id: SafeCasteUtil.copyWithCast<String>(id, 'id', _instance.id),
      user: SafeCasteUtil.copyWithCast<InnerUser>(user, 'user', _instance.user),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R id(String value) {
    final res = call(id: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  R user(InnerUser value) {
    final res = call(user: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  InnerUserCopyWith<R> get $user =>
      InnerUserCopyWith<R>(_instance.user, (v) => call(user: v));
}
''')
@Dataforge(deepCopyWith: true)
class ChainedExample {
  final String id;
  final InnerUser user;
  ChainedExample({required this.id, required this.user});
}

@ShouldGenerate(r'''
mixin _NullableNestedExample {
  abstract final String name;
  abstract final InnerUser? optionalUser;
  @pragma('vm:prefer-inline')
  NullableNestedExampleCopyWith<NullableNestedExample> get copyWith =>
      NullableNestedExampleCopyWith<NullableNestedExample>(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NullableNestedExample) return false;

    return other.name == name && other.optionalUser == optionalUser;
  }

  @override
  int get hashCode => Object.hashAll([name, optionalUser]);

  @override
  String toString() =>
      'NullableNestedExample(name: $name, optionalUser: $optionalUser)';

  Map<String, dynamic> toJson() {
    return {'name': name, 'optionalUser': optionalUser};
  }

  static NullableNestedExample fromJson(Map<String, dynamic> json) {
    return NullableNestedExample(
      name: SafeCasteUtil.readRequiredValue<String>(json, 'name'),
      optionalUser: SafeCasteUtil.readObject(
        json['optionalUser'],
        InnerUser.fromJson,
      ),
    );
  }
}

class NullableNestedExampleCopyWith<R> {
  final _NullableNestedExample _instance;
  final R Function(NullableNestedExample)? _then;
  NullableNestedExampleCopyWith(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({
    Object? name = dataforgeUndefined,
    Object? optionalUser = dataforgeUndefined,
  }) {
    final res = NullableNestedExample(
      name: SafeCasteUtil.copyWithCast<String>(name, 'name', _instance.name),
      optionalUser: SafeCasteUtil.copyWithCastNullable<InnerUser>(
        optionalUser,
        'optionalUser',
        _instance.optionalUser,
      ),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R name(String value) {
    final res = call(name: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  R optionalUser(InnerUser? value) {
    final res = call(optionalUser: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  InnerUserCopyWith<R>? get $optionalUser => _instance.optionalUser == null
      ? null
      : InnerUserCopyWith<R>(
          _instance.optionalUser!,
          (v) => call(optionalUser: v),
        );
}
''')
@Dataforge()
class NullableNestedExample {
  final String name;
  final InnerUser? optionalUser;

  NullableNestedExample({
    required this.name,
    this.optionalUser,
  });
}

// Helper class for multi-level nesting
@Dataforge()
class Address {
  final String street;
  final String city;
  Address({required this.street, required this.city});
}

@Dataforge()
class Person {
  final String name;
  final Address address;
  Person({required this.name, required this.address});
}

@ShouldGenerate(r'''
mixin _MultiLevelNestedExample {
  abstract final String id;
  abstract final Person person;
  @pragma('vm:prefer-inline')
  MultiLevelNestedExampleCopyWith<MultiLevelNestedExample> get copyWith =>
      MultiLevelNestedExampleCopyWith<MultiLevelNestedExample>(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MultiLevelNestedExample) return false;

    return other.id == id && other.person == person;
  }

  @override
  int get hashCode => Object.hashAll([id, person]);

  @override
  String toString() => 'MultiLevelNestedExample(id: $id, person: $person)';

  Map<String, dynamic> toJson() {
    return {'id': id, 'person': person};
  }

  static MultiLevelNestedExample fromJson(Map<String, dynamic> json) {
    return MultiLevelNestedExample(
      id: SafeCasteUtil.readRequiredValue<String>(json, 'id'),
      person: SafeCasteUtil.readRequiredObject(json['person'], Person.fromJson),
    );
  }
}

class MultiLevelNestedExampleCopyWith<R> {
  final _MultiLevelNestedExample _instance;
  final R Function(MultiLevelNestedExample)? _then;
  MultiLevelNestedExampleCopyWith(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({
    Object? id = dataforgeUndefined,
    Object? person = dataforgeUndefined,
  }) {
    final res = MultiLevelNestedExample(
      id: SafeCasteUtil.copyWithCast<String>(id, 'id', _instance.id),
      person: SafeCasteUtil.copyWithCast<Person>(
        person,
        'person',
        _instance.person,
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
  R person(Person value) {
    final res = call(person: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  PersonCopyWith<R> get $person =>
      PersonCopyWith<R>(_instance.person, (v) => call(person: v));
}
''')
@Dataforge(deepCopyWith: true)
class MultiLevelNestedExample {
  final String id;
  final Person person;

  MultiLevelNestedExample({
    required this.id,
    required this.person,
  });
}

@ShouldGenerate(r'''
mixin _DeepRootExample {
  abstract final String id;
  abstract final NestedDefaultValues root;
  @pragma('vm:prefer-inline')
  DeepRootExampleCopyWith<DeepRootExample> get copyWith =>
      DeepRootExampleCopyWith<DeepRootExample>(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DeepRootExample) return false;

    return other.id == id && other.root == root;
  }

  @override
  int get hashCode => Object.hashAll([id, root]);

  @override
  String toString() => 'DeepRootExample(id: $id, root: $root)';

  Map<String, dynamic> toJson() {
    return {'id': id, 'root': root};
  }

  static DeepRootExample fromJson(Map<String, dynamic> json) {
    return DeepRootExample(
      id: SafeCasteUtil.readRequiredValue<String>(json, 'id'),
      root: SafeCasteUtil.readRequiredObject(
        json['root'],
        NestedDefaultValues.fromJson,
      ),
    );
  }
}

class DeepRootExampleCopyWith<R> {
  final _DeepRootExample _instance;
  final R Function(DeepRootExample)? _then;
  DeepRootExampleCopyWith(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({Object? id = dataforgeUndefined, Object? root = dataforgeUndefined}) {
    final res = DeepRootExample(
      id: SafeCasteUtil.copyWithCast<String>(id, 'id', _instance.id),
      root: SafeCasteUtil.copyWithCast<NestedDefaultValues>(
        root,
        'root',
        _instance.root,
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
  R root(NestedDefaultValues value) {
    final res = call(root: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  NestedDefaultValuesCopyWith<R> get $root =>
      NestedDefaultValuesCopyWith<R>(_instance.root, (v) => call(root: v));
}
''')
@Dataforge()
class DeepRootExample {
  final String id;
  final NestedDefaultValues root;
  DeepRootExample({required this.id, required this.root});
}

@ShouldGenerate(r'''
mixin _SuperDeepRoot {
  abstract final DeepRootExample root;
  @pragma('vm:prefer-inline')
  SuperDeepRootCopyWith<SuperDeepRoot> get copyWith =>
      SuperDeepRootCopyWith<SuperDeepRoot>(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SuperDeepRoot) return false;

    return other.root == root;
  }

  @override
  int get hashCode => Object.hashAll([root]);

  @override
  String toString() => 'SuperDeepRoot(root: $root)';

  Map<String, dynamic> toJson() {
    return {'root': root};
  }

  static SuperDeepRoot fromJson(Map<String, dynamic> json) {
    return SuperDeepRoot(
      root: SafeCasteUtil.readRequiredObject(
        json['root'],
        DeepRootExample.fromJson,
      ),
    );
  }
}

class SuperDeepRootCopyWith<R> {
  final _SuperDeepRoot _instance;
  final R Function(SuperDeepRoot)? _then;
  SuperDeepRootCopyWith(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({Object? root = dataforgeUndefined}) {
    final res = SuperDeepRoot(
      root: SafeCasteUtil.copyWithCast<DeepRootExample>(
        root,
        'root',
        _instance.root,
      ),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R root(DeepRootExample value) {
    final res = call(root: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  DeepRootExampleCopyWith<R> get $root =>
      DeepRootExampleCopyWith<R>(_instance.root, (v) => call(root: v));
}
''')
@Dataforge()
class SuperDeepRoot {
  final DeepRootExample root;
  SuperDeepRoot({required this.root});
}
