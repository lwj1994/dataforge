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
      name: SafeCasteUtil.readValue<String>(json, 'name') ?? '',
      age: SafeCasteUtil.readValue<int>(json, 'age') ?? 0,
    );
  }
}

class _BasicUserCopyWith<R> {
  final _BasicUser _instance;
  final R Function(BasicUser)? _then;
  _BasicUserCopyWith._(this._instance, [this._then]);

  R call({
    Object? name = dataforgeUndefined,
    Object? age = dataforgeUndefined,
  }) {
    final res = BasicUser(
      name: name == dataforgeUndefined ? _instance.name : name as String,
      age: age == dataforgeUndefined ? _instance.age : age as int,
    );
    return _then != null ? _then!(res) : res as R;
  }

  R name(String value) {
    final res = BasicUser(name: value, age: _instance.age);
    return _then != null ? _then!(res) : res as R;
  }

  R age(int value) {
    final res = BasicUser(name: _instance.name, age: value);
    return _then != null ? _then!(res) : res as R;
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

  R call({Object? data = dataforgeUndefined}) {
    final res = GenericResult<T>(
      data: data == dataforgeUndefined ? _instance.data : data as T?,
    );
    return _then != null ? _then!(res) : res as R;
  }

  R data(T? value) {
    final res = GenericResult<T>(data: value);
    return _then != null ? _then!(res) : res as R;
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
      id: SafeCasteUtil.readValue<String>(json, 'product_id') ?? '',
      name: SafeCasteUtil.readValue<String>(json, 'name') ?? '',
    );
  }
}

class _ProductCopyWith<R> {
  final _Product _instance;
  final R Function(Product)? _then;
  _ProductCopyWith._(this._instance, [this._then]);

  R call({
    Object? id = dataforgeUndefined,
    Object? secret = dataforgeUndefined,
    Object? name = dataforgeUndefined,
  }) {
    final res = Product(
      id: id == dataforgeUndefined ? _instance.id : id as String,
      secret: secret == dataforgeUndefined
          ? _instance.secret
          : secret as String,
      name: name == dataforgeUndefined ? _instance.name : name as String,
    );
    return _then != null ? _then!(res) : res as R;
  }

  R id(String value) {
    final res = Product(
      id: value,
      secret: _instance.secret,
      name: _instance.name,
    );
    return _then != null ? _then!(res) : res as R;
  }

  R secret(String value) {
    final res = Product(id: _instance.id, secret: value, name: _instance.name);
    return _then != null ? _then!(res) : res as R;
  }

  R name(String value) {
    final res = Product(
      id: _instance.id,
      secret: _instance.secret,
      name: value,
    );
    return _then != null ? _then!(res) : res as R;
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

  R call({Object? dateTime = dataforgeUndefined}) {
    final res = DateTimeExample(
      dateTime: dateTime == dataforgeUndefined
          ? _instance.dateTime
          : dateTime as DateTime?,
    );
    return _then != null ? _then!(res) : res as R;
  }

  R dateTime(DateTime? value) {
    final res = DateTimeExample(dateTime: value);
    return _then != null ? _then!(res) : res as R;
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
          ).fromJson(SafeCasteUtil.readValue<String>(json, 'status')) ??
          Status.values.first,
    );
  }
}

class _EnumTypesCopyWith<R> {
  final _EnumTypes _instance;
  final R Function(EnumTypes)? _then;
  _EnumTypesCopyWith._(this._instance, [this._then]);

  R call({Object? status = dataforgeUndefined}) {
    final res = EnumTypes(
      status: status == dataforgeUndefined
          ? _instance.status
          : status as Status,
    );
    return _then != null ? _then!(res) : res as R;
  }

  R status(Status value) {
    final res = EnumTypes(status: value);
    return _then != null ? _then!(res) : res as R;
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
      intValue: SafeCasteUtil.readValue<int>(json, 'intValue') ?? 0,
      stringValue: SafeCasteUtil.readValue<String>(json, 'stringValue') ?? '',
      boolValue: SafeCasteUtil.readValue<bool>(json, 'boolValue') ?? false,
    );
  }
}

class _DefaultValuesCopyWith<R> {
  final _DefaultValues _instance;
  final R Function(DefaultValues)? _then;
  _DefaultValuesCopyWith._(this._instance, [this._then]);

  R call({
    Object? intValue = dataforgeUndefined,
    Object? stringValue = dataforgeUndefined,
    Object? boolValue = dataforgeUndefined,
  }) {
    final res = DefaultValues(
      intValue: intValue == dataforgeUndefined
          ? _instance.intValue
          : intValue as int,
      stringValue: stringValue == dataforgeUndefined
          ? _instance.stringValue
          : stringValue as String,
      boolValue: boolValue == dataforgeUndefined
          ? _instance.boolValue
          : boolValue as bool,
    );
    return _then != null ? _then!(res) : res as R;
  }

  R intValue(int value) {
    final res = DefaultValues(
      intValue: value,
      stringValue: _instance.stringValue,
      boolValue: _instance.boolValue,
    );
    return _then != null ? _then!(res) : res as R;
  }

  R stringValue(String value) {
    final res = DefaultValues(
      intValue: _instance.intValue,
      stringValue: value,
      boolValue: _instance.boolValue,
    );
    return _then != null ? _then!(res) : res as R;
  }

  R boolValue(bool value) {
    final res = DefaultValues(
      intValue: _instance.intValue,
      stringValue: _instance.stringValue,
      boolValue: value,
    );
    return _then != null ? _then!(res) : res as R;
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
      name: SafeCasteUtil.readValue<String>(json, 'name') ?? '',
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
    Object? name = dataforgeUndefined,
    Object? age = dataforgeUndefined,
    Object? email = dataforgeUndefined,
    Object? isActive = dataforgeUndefined,
    Object? tags = dataforgeUndefined,
  }) {
    final res = AlternateNamesTest(
      name: name == dataforgeUndefined ? _instance.name : name as String,
      age: age == dataforgeUndefined ? _instance.age : age as int,
      email: email == dataforgeUndefined ? _instance.email : email as String,
      isActive: isActive == dataforgeUndefined
          ? _instance.isActive
          : isActive as bool,
      tags: tags == dataforgeUndefined ? _instance.tags : tags as List<String>,
    );
    return _then != null ? _then!(res) : res as R;
  }

  R name(String value) {
    final res = AlternateNamesTest(
      name: value,
      age: _instance.age,
      email: _instance.email,
      isActive: _instance.isActive,
      tags: _instance.tags,
    );
    return _then != null ? _then!(res) : res as R;
  }

  R age(int value) {
    final res = AlternateNamesTest(
      name: _instance.name,
      age: value,
      email: _instance.email,
      isActive: _instance.isActive,
      tags: _instance.tags,
    );
    return _then != null ? _then!(res) : res as R;
  }

  R email(String value) {
    final res = AlternateNamesTest(
      name: _instance.name,
      age: _instance.age,
      email: value,
      isActive: _instance.isActive,
      tags: _instance.tags,
    );
    return _then != null ? _then!(res) : res as R;
  }

  R isActive(bool value) {
    final res = AlternateNamesTest(
      name: _instance.name,
      age: _instance.age,
      email: _instance.email,
      isActive: value,
      tags: _instance.tags,
    );
    return _then != null ? _then!(res) : res as R;
  }

  R tags(List<String> value) {
    final res = AlternateNamesTest(
      name: _instance.name,
      age: _instance.age,
      email: _instance.email,
      isActive: _instance.isActive,
      tags: value,
    );
    return _then != null ? _then!(res) : res as R;
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
      id: SafeCasteUtil.readValue<String>(json, 'id') ?? '',
      name: SafeCasteUtil.readValue<String>(json, 'name') ?? '',
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

  R call({
    Object? id = dataforgeUndefined,
    Object? name = dataforgeUndefined,
    Object? title = dataforgeUndefined,
    Object? count = dataforgeUndefined,
    Object? enabled = dataforgeUndefined,
  }) {
    final res = CustomReadValue(
      id: id == dataforgeUndefined ? _instance.id : id as String,
      name: name == dataforgeUndefined ? _instance.name : name as String,
      title: title == dataforgeUndefined ? _instance.title : title as String,
      count: count == dataforgeUndefined ? _instance.count : count as int,
      enabled: enabled == dataforgeUndefined
          ? _instance.enabled
          : enabled as bool,
    );
    return _then != null ? _then!(res) : res as R;
  }

  R id(String value) {
    final res = CustomReadValue(
      id: value,
      name: _instance.name,
      title: _instance.title,
      count: _instance.count,
      enabled: _instance.enabled,
    );
    return _then != null ? _then!(res) : res as R;
  }

  R name(String value) {
    final res = CustomReadValue(
      id: _instance.id,
      name: value,
      title: _instance.title,
      count: _instance.count,
      enabled: _instance.enabled,
    );
    return _then != null ? _then!(res) : res as R;
  }

  R title(String value) {
    final res = CustomReadValue(
      id: _instance.id,
      name: _instance.name,
      title: value,
      count: _instance.count,
      enabled: _instance.enabled,
    );
    return _then != null ? _then!(res) : res as R;
  }

  R count(int value) {
    final res = CustomReadValue(
      id: _instance.id,
      name: _instance.name,
      title: _instance.title,
      count: value,
      enabled: _instance.enabled,
    );
    return _then != null ? _then!(res) : res as R;
  }

  R enabled(bool value) {
    final res = CustomReadValue(
      id: _instance.id,
      name: _instance.name,
      title: _instance.title,
      count: _instance.count,
      enabled: value,
    );
    return _then != null ? _then!(res) : res as R;
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

  R call({Object? data = dataforgeUndefined}) {
    final res = GenericContainer<T>(
      data: data == dataforgeUndefined ? _instance.data : data as T,
    );
    return _then != null ? _then!(res) : res as R;
  }

  R data(T value) {
    final res = GenericContainer<T>(data: value);
    return _then != null ? _then!(res) : res as R;
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
      name: SafeCasteUtil.readValue<String>(json, 'name') ?? '',
      nested: json['nested'],
    );
  }
}

class _NestedDefaultValuesCopyWith<R> {
  final _NestedDefaultValues _instance;
  final R Function(NestedDefaultValues)? _then;
  _NestedDefaultValuesCopyWith._(this._instance, [this._then]);

  R call({
    Object? name = dataforgeUndefined,
    Object? nested = dataforgeUndefined,
  }) {
    final res = NestedDefaultValues(
      name: name == dataforgeUndefined ? _instance.name : name as String,
      nested: nested == dataforgeUndefined
          ? _instance.nested
          : nested as DefaultValues,
    );
    return _then != null ? _then!(res) : res as R;
  }

  R name(String value) {
    final res = NestedDefaultValues(name: value, nested: _instance.nested);
    return _then != null ? _then!(res) : res as R;
  }

  R nested(DefaultValues value) {
    final res = NestedDefaultValues(name: _instance.name, nested: value);
    return _then != null ? _then!(res) : res as R;
  }

  R nested$intValue(int value) {
    return call(nested: _instance.nested.copyWith(intValue: value));
  }

  R nested$stringValue(String value) {
    return call(nested: _instance.nested.copyWith(stringValue: value));
  }

  R nested$boolValue(bool value) {
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
      id: SafeCasteUtil.readValue<String>(json, 'id') ?? '',
      user: json['user'],
    );
  }
}

class _ChainedExampleCopyWith<R> {
  final _ChainedExample _instance;
  final R Function(ChainedExample)? _then;
  _ChainedExampleCopyWith._(this._instance, [this._then]);

  R call({Object? id = dataforgeUndefined, Object? user = dataforgeUndefined}) {
    final res = ChainedExample(
      id: id == dataforgeUndefined ? _instance.id : id as String,
      user: user == dataforgeUndefined ? _instance.user : user as BasicUser,
    );
    return _then != null ? _then!(res) : res as R;
  }

  R id(String value) {
    final res = ChainedExample(id: value, user: _instance.user);
    return _then != null ? _then!(res) : res as R;
  }

  R user(BasicUser value) {
    final res = ChainedExample(id: _instance.id, user: value);
    return _then != null ? _then!(res) : res as R;
  }

  R user$name(String value) {
    return call(user: _instance.user.copyWith(name: value));
  }

  R user$age(int value) {
    return call(user: _instance.user.copyWith(age: value));
  }
}
''')
@Dataforge(deepCopyWith: true)
class ChainedExample {
  final String id;
  final BasicUser user;
  ChainedExample({required this.id, required this.user});
}

class MyDateTimeConverter extends JsonTypeConverter<DateTime, String> {
  const MyDateTimeConverter();
  @override
  DateTime? fromJson(Object? json) => null;
  @override
  String? toJson(DateTime? object) => null;
}
