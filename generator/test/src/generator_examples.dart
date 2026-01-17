import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:source_gen_test/annotations.dart';

@ShouldGenerate(r'''
mixin _BasicUser {
  abstract final String name;
  abstract final int age;
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
      name: SafeCasteUtil.safeCast<String>(json['name']) ?? '',
      age: SafeCasteUtil.safeCast<int>(json['age']) ?? 0,
    );
  }
}

class _BasicUserCopyWith<R> {
  final _BasicUser _instance;
  final R Function(BasicUser)? _then;
  _BasicUserCopyWith._(this._instance, [this._then]);

  R call({String? name, int? age}) {
    final res = BasicUser(
      name: name ?? _instance.name,
      age: age ?? _instance.age,
    );
    return _then != null ? _then!(res) : res as R;
  }

  R name(String value) {
    return call(name: value);
  }

  R age(int value) {
    return call(age: value);
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
mixin _GenericResult<T> {
  abstract final T? data;
  _GenericResultCopyWith<T, GenericResult<T>> get copyWith =>
      _GenericResultCopyWith<T, GenericResult<T>>._(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GenericResult) return false;

    return other.data == data;
  }

  @override
  int get hashCode => Object.hashAll([data]);

  @override
  String toString() => 'GenericResult(data: $data)';

  Map<String, dynamic> toJson() {
    return {'data': data};
  }

  static GenericResult<T> fromJson<T>(Map<String, dynamic> json) {
    return GenericResult(data: json['data']);
  }
}

class _GenericResultCopyWith<T, R> {
  final _GenericResult<T> _instance;
  final R Function(GenericResult<T>)? _then;
  _GenericResultCopyWith._(this._instance, [this._then]);

  R call({T? data}) {
    final res = GenericResult<T>(data: data ?? _instance.data);
    return _then != null ? _then!(res) : res as R;
  }

  R data(T? value) {
    return call(data: value);
  }
}
''')
@Dataforge()
class GenericResult<T> {
  final T? data;
  GenericResult({this.data});
}

@ShouldGenerate(r'''
mixin _Product {
  abstract final String id;
  abstract final String secret;
  abstract final String name;
  _ProductCopyWith<Product> get copyWith => _ProductCopyWith<Product>._(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Product) return false;

    return other.id == id && other.secret == secret && other.name == name;
  }

  @override
  int get hashCode => Object.hashAll([id, secret, name]);

  @override
  String toString() => 'Product(id: $id, secret: $secret, name: $name)';

  Map<String, dynamic> toJson() {
    return {'product_id': id, 'name': name};
  }

  static Product fromJson(Map<String, dynamic> json) {
    return Product(
      id: SafeCasteUtil.safeCast<String>(json['product_id']) ?? '',
      name: SafeCasteUtil.safeCast<String>(json['name']) ?? '',
    );
  }
}

class _ProductCopyWith<R> {
  final _Product _instance;
  final R Function(Product)? _then;
  _ProductCopyWith._(this._instance, [this._then]);

  R call({String? id, String? secret, String? name}) {
    final res = Product(
      id: id ?? _instance.id,
      secret: secret ?? _instance.secret,
      name: name ?? _instance.name,
    );
    return _then != null ? _then!(res) : res as R;
  }

  R id(String value) {
    return call(id: value);
  }

  R secret(String value) {
    return call(secret: value);
  }

  R name(String value) {
    return call(name: value);
  }
}
''')
@Dataforge()
class Product {
  @JsonKey(name: 'product_id')
  final String id;

  @JsonKey(ignore: true)
  final String secret;

  final String name;

  Product({required this.id, required this.secret, required this.name});
}

@ShouldGenerate(r'''
mixin _DateTimeExample {
  abstract final DateTime? dateTime;
  _DateTimeExampleCopyWith<DateTimeExample> get copyWith =>
      _DateTimeExampleCopyWith<DateTimeExample>._(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DateTimeExample) return false;

    return other.dateTime == dateTime;
  }

  @override
  int get hashCode => Object.hashAll([dateTime]);

  @override
  String toString() => 'DateTimeExample(dateTime: $dateTime)';

  Map<String, dynamic> toJson() {
    return {'dateTime': const DefaultDateTimeConverter().toJson(dateTime)};
  }

  static DateTimeExample fromJson(Map<String, dynamic> json) {
    return DateTimeExample(
      dateTime: const DefaultDateTimeConverter().fromJson(json['dateTime']),
    );
  }
}

class _DateTimeExampleCopyWith<R> {
  final _DateTimeExample _instance;
  final R Function(DateTimeExample)? _then;
  _DateTimeExampleCopyWith._(this._instance, [this._then]);

  R call({DateTime? dateTime}) {
    final res = DateTimeExample(dateTime: dateTime ?? _instance.dateTime);
    return _then != null ? _then!(res) : res as R;
  }

  R dateTime(DateTime? value) {
    return call(dateTime: value);
  }
}
''')
@Dataforge()
class DateTimeExample {
  final DateTime? dateTime;
  DateTimeExample({this.dateTime});
}

@ShouldGenerate(r'''
mixin _EnumTypes {
  abstract final Status status;
  _EnumTypesCopyWith<EnumTypes> get copyWith =>
      _EnumTypesCopyWith<EnumTypes>._(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EnumTypes) return false;

    return other.status == status;
  }

  @override
  int get hashCode => Object.hashAll([status]);

  @override
  String toString() => 'EnumTypes(status: $status)';

  Map<String, dynamic> toJson() {
    return {'status': DefaultEnumConverter(Status.values).toJson(status)};
  }

  static EnumTypes fromJson(Map<String, dynamic> json) {
    return EnumTypes(
      status:
          DefaultEnumConverter(
            Status.values,
          ).fromJson(SafeCasteUtil.safeCast<String>(json['status'])) ??
          Status.values.first,
    );
  }
}

class _EnumTypesCopyWith<R> {
  final _EnumTypes _instance;
  final R Function(EnumTypes)? _then;
  _EnumTypesCopyWith._(this._instance, [this._then]);

  R call({Status? status}) {
    final res = EnumTypes(status: status ?? _instance.status);
    return _then != null ? _then!(res) : res as R;
  }

  R status(Status value) {
    return call(status: value);
  }
}
''')
@Dataforge()
class EnumTypes {
  final Status status;
  EnumTypes({required this.status});
}

enum Status { active, inactive, pending }

@ShouldGenerate(r'''
mixin _DefaultValues {
  abstract final int intValue;
  abstract final String stringValue;
  abstract final bool boolValue;
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
      intValue: SafeCasteUtil.safeCast<int>(json['intValue']) ?? 0,
      stringValue: SafeCasteUtil.safeCast<String>(json['stringValue']) ?? '',
      boolValue: SafeCasteUtil.safeCast<bool>(json['boolValue']) ?? false,
    );
  }
}

class _DefaultValuesCopyWith<R> {
  final _DefaultValues _instance;
  final R Function(DefaultValues)? _then;
  _DefaultValuesCopyWith._(this._instance, [this._then]);

  R call({int? intValue, String? stringValue, bool? boolValue}) {
    final res = DefaultValues(
      intValue: intValue ?? _instance.intValue,
      stringValue: stringValue ?? _instance.stringValue,
      boolValue: boolValue ?? _instance.boolValue,
    );
    return _then != null ? _then!(res) : res as R;
  }

  R intValue(int value) {
    return call(intValue: value);
  }

  R stringValue(String value) {
    return call(stringValue: value);
  }

  R boolValue(bool value) {
    return call(boolValue: value);
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
mixin _AlternateNamesTest {
  abstract final String name;
  abstract final int age;
  abstract final String email;
  abstract final bool isActive;
  abstract final List<String> tags;
  _AlternateNamesTestCopyWith<AlternateNamesTest> get copyWith =>
      _AlternateNamesTestCopyWith<AlternateNamesTest>._(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AlternateNamesTest) return false;

    return other.name == name &&
        other.age == age &&
        other.email == email &&
        other.isActive == isActive &&
        other.tags == tags;
  }

  @override
  int get hashCode => Object.hashAll([name, age, email, isActive, tags]);

  @override
  String toString() =>
      'AlternateNamesTest(name: $name, age: $age, email: $email, isActive: $isActive, tags: $tags)';

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'user_age': age,
      'email': email,
      'is_active': isActive,
      'tags': tags,
    };
  }

  static AlternateNamesTest fromJson(Map<String, dynamic> json) {
    return AlternateNamesTest(
      name: SafeCasteUtil.safeCast<String>(json['name']) ?? '',
      age:
          SafeCasteUtil.safeCast<int>(
            (json['user_age'] ?? json['age'] ?? json['years']),
          ) ??
          0,
      email:
          SafeCasteUtil.safeCast<String>(
            (json['email'] ??
                json['email_address'] ??
                json['mail'] ??
                json['e_mail']),
          ) ??
          '',
      isActive:
          SafeCasteUtil.safeCast<bool>(
            (json['is_active'] ?? json['active'] ?? json['enabled']),
          ) ??
          false,
      tags:
          ((json['tags'] ?? json['tags_list'] ?? json['labels'])
                  as List<dynamic>?)
              ?.cast<String>(),
    );
  }
}

class _AlternateNamesTestCopyWith<R> {
  final _AlternateNamesTest _instance;
  final R Function(AlternateNamesTest)? _then;
  _AlternateNamesTestCopyWith._(this._instance, [this._then]);

  R call({
    String? name,
    int? age,
    String? email,
    bool? isActive,
    List<String>? tags,
  }) {
    final res = AlternateNamesTest(
      name: name ?? _instance.name,
      age: age ?? _instance.age,
      email: email ?? _instance.email,
      isActive: isActive ?? _instance.isActive,
      tags: tags ?? _instance.tags,
    );
    return _then != null ? _then!(res) : res as R;
  }

  R name(String value) {
    return call(name: value);
  }

  R age(int value) {
    return call(age: value);
  }

  R email(String value) {
    return call(email: value);
  }

  R isActive(bool value) {
    return call(isActive: value);
  }

  R tags(List<String> value) {
    return call(tags: value);
  }
}
''')
@Dataforge()
class AlternateNamesTest {
  final String name;

  @JsonKey(name: "user_age", alternateNames: ["age", "years"])
  final int age;

  @JsonKey(alternateNames: ["email_address", "mail", "e_mail"])
  final String email;

  @JsonKey(name: "is_active", alternateNames: ["active", "enabled"])
  final bool isActive;

  @JsonKey(alternateNames: ["tags_list", "labels"])
  final List<String> tags;

  AlternateNamesTest({
    required this.name,
    required this.age,
    required this.email,
    required this.isActive,
    this.tags = const [],
  });
}

@ShouldGenerate(r'''
mixin _CustomReadValue {
  abstract final String id;
  abstract final String name;
  abstract final String title;
  abstract final int count;
  abstract final bool enabled;
  _CustomReadValueCopyWith<CustomReadValue> get copyWith =>
      _CustomReadValueCopyWith<CustomReadValue>._(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CustomReadValue) return false;

    return other.id == id &&
        other.name == name &&
        other.title == title &&
        other.count == count &&
        other.enabled == enabled;
  }

  @override
  int get hashCode => Object.hashAll([id, name, title, count, enabled]);

  @override
  String toString() =>
      'CustomReadValue(id: $id, name: $name, title: $title, count: $count, enabled: $enabled)';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'count': count,
      'enabled': enabled,
    };
  }

  static CustomReadValue fromJson(Map<String, dynamic> json) {
    return CustomReadValue(
      id: SafeCasteUtil.safeCast<String>(json['id']) ?? '',
      name: SafeCasteUtil.safeCast<String>(json['name']) ?? '',
      title:
          SafeCasteUtil.safeCast<String>(
            CustomReadValue._readValue(json, 'title'),
          ) ??
          '',
      count:
          SafeCasteUtil.safeCast<int>(
            CustomReadValue._readValue(json, 'count'),
          ) ??
          0,
      enabled:
          SafeCasteUtil.safeCast<bool>(
            CustomReadValue._readValue(json, 'enabled'),
          ) ??
          false,
    );
  }
}

class _CustomReadValueCopyWith<R> {
  final _CustomReadValue _instance;
  final R Function(CustomReadValue)? _then;
  _CustomReadValueCopyWith._(this._instance, [this._then]);

  R call({String? id, String? name, String? title, int? count, bool? enabled}) {
    final res = CustomReadValue(
      id: id ?? _instance.id,
      name: name ?? _instance.name,
      title: title ?? _instance.title,
      count: count ?? _instance.count,
      enabled: enabled ?? _instance.enabled,
    );
    return _then != null ? _then!(res) : res as R;
  }

  R id(String value) {
    return call(id: value);
  }

  R name(String value) {
    return call(name: value);
  }

  R title(String value) {
    return call(title: value);
  }

  R count(int value) {
    return call(count: value);
  }

  R enabled(bool value) {
    return call(enabled: value);
  }
}
''')
@Dataforge()
class CustomReadValue {
  final String id;
  final String name;
  @JsonKey(readValue: CustomReadValue._readValue)
  final String title;
  @JsonKey(readValue: CustomReadValue._readValue)
  final int count;
  @JsonKey(readValue: CustomReadValue._readValue)
  final bool enabled;

  CustomReadValue({
    required this.id,
    required this.name,
    required this.title,
    required this.count,
    required this.enabled,
  });

  static Object? _readValue(Map<dynamic, dynamic> map, String key) => map[key];
}

@ShouldGenerate(r'''
mixin _GenericContainer<T> {
  abstract final T data;
  _GenericContainerCopyWith<T, GenericContainer<T>> get copyWith =>
      _GenericContainerCopyWith<T, GenericContainer<T>>._(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GenericContainer) return false;

    return other.data == data;
  }

  @override
  int get hashCode => Object.hashAll([data]);

  @override
  String toString() => 'GenericContainer(data: $data)';

  Map<String, dynamic> toJson() {
    return {'data': data};
  }

  static GenericContainer<T> fromJson<T>(Map<String, dynamic> json) {
    return GenericContainer(data: json['data']);
  }
}

class _GenericContainerCopyWith<T, R> {
  final _GenericContainer<T> _instance;
  final R Function(GenericContainer<T>)? _then;
  _GenericContainerCopyWith._(this._instance, [this._then]);

  R call({T? data}) {
    final res = GenericContainer<T>(data: data ?? _instance.data);
    return _then != null ? _then!(res) : res as R;
  }

  R data(T value) {
    return call(data: value);
  }
}
''')
@Dataforge()
class GenericContainer<T> {
  final T data;
  GenericContainer({required this.data});
}

@ShouldGenerate(r'''
mixin _NestedDefaultValues {
  abstract final String name;
  abstract final DefaultValues nested;
  _NestedDefaultValuesCopyWith<NestedDefaultValues> get copyWith =>
      _NestedDefaultValuesCopyWith<NestedDefaultValues>._(this);

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
      name: SafeCasteUtil.safeCast<String>(json['name']) ?? '',
      nested: json['nested'],
    );
  }
}

class _NestedDefaultValuesCopyWith<R> {
  final _NestedDefaultValues _instance;
  final R Function(NestedDefaultValues)? _then;
  _NestedDefaultValuesCopyWith._(this._instance, [this._then]);

  R call({String? name, DefaultValues? nested}) {
    final res = NestedDefaultValues(
      name: name ?? _instance.name,
      nested: nested ?? _instance.nested,
    );
    return _then != null ? _then!(res) : res as R;
  }

  R name(String value) {
    return call(name: value);
  }

  R nested(DefaultValues value) {
    return call(nested: value);
  }

  R nestedIntValue(int value) {
    return call(nested: _instance.nested.copyWith(intValue: value));
  }

  R nestedStringValue(String value) {
    return call(nested: _instance.nested.copyWith(stringValue: value));
  }

  R nestedBoolValue(bool value) {
    return call(nested: _instance.nested.copyWith(boolValue: value));
  }
}
''')
@Dataforge()
class NestedDefaultValues {
  final String name;
  final DefaultValues nested;
  NestedDefaultValues({
    this.name = 'nested_default',
    this.nested = const DefaultValues(),
  });
}

@ShouldGenerate(r'''
mixin _ChainedExample {
  abstract final String id;
  abstract final BasicUser user;
  _ChainedExampleCopyWith<ChainedExample> get copyWith =>
      _ChainedExampleCopyWith<ChainedExample>._(this);

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
      id: SafeCasteUtil.safeCast<String>(json['id']) ?? '',
      user: json['user'],
    );
  }
}

class _ChainedExampleCopyWith<R> {
  final _ChainedExample _instance;
  final R Function(ChainedExample)? _then;
  _ChainedExampleCopyWith._(this._instance, [this._then]);

  R call({String? id, BasicUser? user}) {
    final res = ChainedExample(
      id: id ?? _instance.id,
      user: user ?? _instance.user,
    );
    return _then != null ? _then!(res) : res as R;
  }

  R id(String value) {
    return call(id: value);
  }

  R user(BasicUser value) {
    return call(user: value);
  }

  R userName(String value) {
    return call(user: _instance.user.copyWith(name: value));
  }

  R userAge(int value) {
    return call(user: _instance.user.copyWith(age: value));
  }
}
''')
@Dataforge(chainedCopyWith: true)
class ChainedExample {
  final String id;
  final BasicUser user;
  ChainedExample({required this.id, required this.user});
}

@ShouldGenerate(r'''
mixin _CustomFunctionExample {
  abstract final String name;
  _CustomFunctionExampleCopyWith<CustomFunctionExample> get copyWith =>
      _CustomFunctionExampleCopyWith<CustomFunctionExample>._(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CustomFunctionExample) return false;

    return other.name == name;
  }

  @override
  int get hashCode => Object.hashAll([name]);

  @override
  String toString() => 'CustomFunctionExample(name: $name)';

  Map<String, dynamic> toJson() {
    return {'name': _customToJson(name)};
  }

  static CustomFunctionExample fromJson(Map<String, dynamic> json) {
    return CustomFunctionExample(name: _customFromJson(json['name']) as String);
  }
}

class _CustomFunctionExampleCopyWith<R> {
  final _CustomFunctionExample _instance;
  final R Function(CustomFunctionExample)? _then;
  _CustomFunctionExampleCopyWith._(this._instance, [this._then]);

  R call({String? name}) {
    final res = CustomFunctionExample(name: name ?? _instance.name);
    return _then != null ? _then!(res) : res as R;
  }

  R name(String value) {
    return call(name: value);
  }
}
''')
@Dataforge()
class CustomFunctionExample {
  @JsonKey(fromJson: _customFromJson, toJson: _customToJson)
  final String name;
  CustomFunctionExample({required this.name});
}

String _customFromJson(dynamic json) => json as String;
String _customToJson(String value) => value;

class MyDateTimeConverter extends TypeConverter<DateTime, String> {
  const MyDateTimeConverter();
  @override
  DateTime? fromJson(Object? json) => null;
  @override
  String? toJson(DateTime? object) => null;
}
