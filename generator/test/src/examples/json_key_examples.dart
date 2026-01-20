import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:source_gen_test/annotations.dart';

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
      id: SafeCasteUtil.readRequiredValue<String>(json, 'product_id'),
      name: SafeCasteUtil.readRequiredValue<String>(json, 'name'),
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
      id: (id == dataforgeUndefined ? _instance.id : id as String),
      secret: (secret == dataforgeUndefined
          ? _instance.secret
          : secret as String),
      name: (name == dataforgeUndefined ? _instance.name : name as String),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  R id(String value) {
    final res = Product(
      id: value,
      secret: _instance.secret,
      name: _instance.name,
    );
    return (_then != null ? _then!(res) : res as R);
  }

  R secret(String value) {
    final res = Product(id: _instance.id, secret: value, name: _instance.name);
    return (_then != null ? _then!(res) : res as R);
  }

  R name(String value) {
    final res = Product(
      id: _instance.id,
      secret: _instance.secret,
      name: value,
    );
    return (_then != null ? _then!(res) : res as R);
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

    if (name != other.name) {
      return false;
    }
    if (age != other.age) {
      return false;
    }
    if (email != other.email) {
      return false;
    }
    if (isActive != other.isActive) {
      return false;
    }
    if (!const DeepCollectionEquality().equals(tags, other.tags)) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([
    name,
    age,
    email,
    isActive,
    const DeepCollectionEquality().hash(tags),
  ]);

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
      name: SafeCasteUtil.readRequiredValue<String>(json, 'name'),
      age:
          (SafeCasteUtil.safeCast<int>(
            (json['user_age'] ?? json['age'] ?? json['years']),
          ) ??
          0),
      email:
          (SafeCasteUtil.safeCast<String>(
            (json['email'] ??
                json['email_address'] ??
                json['mail'] ??
                json['e_mail']),
          ) ??
          ''),
      isActive:
          (SafeCasteUtil.safeCast<bool>(
            (json['is_active'] ?? json['active'] ?? json['enabled']),
          ) ??
          false),
      tags:
          (((SafeCasteUtil.safeCast<List<String>>(
            (json['tags'] ?? json['tags_list'] ?? json['labels']),
          )?.map((e) => (SafeCasteUtil.safeCast<String>(e) ?? '')).toList())) ??
          (const [])),
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
      name: (name == dataforgeUndefined ? _instance.name : name as String),
      age: (age == dataforgeUndefined ? _instance.age : age as int),
      email: (email == dataforgeUndefined ? _instance.email : email as String),
      isActive: (isActive == dataforgeUndefined
          ? _instance.isActive
          : isActive as bool),
      tags: (tags == dataforgeUndefined
          ? _instance.tags
          : (tags as List).cast<String>()),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  R name(String value) {
    final res = AlternateNamesTest(
      name: value,
      age: _instance.age,
      email: _instance.email,
      isActive: _instance.isActive,
      tags: _instance.tags,
    );
    return (_then != null ? _then!(res) : res as R);
  }

  R age(int value) {
    final res = AlternateNamesTest(
      name: _instance.name,
      age: value,
      email: _instance.email,
      isActive: _instance.isActive,
      tags: _instance.tags,
    );
    return (_then != null ? _then!(res) : res as R);
  }

  R email(String value) {
    final res = AlternateNamesTest(
      name: _instance.name,
      age: _instance.age,
      email: value,
      isActive: _instance.isActive,
      tags: _instance.tags,
    );
    return (_then != null ? _then!(res) : res as R);
  }

  R isActive(bool value) {
    final res = AlternateNamesTest(
      name: _instance.name,
      age: _instance.age,
      email: _instance.email,
      isActive: value,
      tags: _instance.tags,
    );
    return (_then != null ? _then!(res) : res as R);
  }

  R tags(List<String> value) {
    final res = AlternateNamesTest(
      name: _instance.name,
      age: _instance.age,
      email: _instance.email,
      isActive: _instance.isActive,
      tags: value,
    );
    return (_then != null ? _then!(res) : res as R);
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
      id: SafeCasteUtil.readRequiredValue<String>(json, 'id'),
      name: SafeCasteUtil.readRequiredValue<String>(json, 'name'),
      title:
          (SafeCasteUtil.safeCast<String>(
            CustomReadValue._readValue(json, 'title'),
          ) ??
          ''),
      count:
          (SafeCasteUtil.safeCast<int>(
            CustomReadValue._readValue(json, 'count'),
          ) ??
          0),
      enabled:
          (SafeCasteUtil.safeCast<bool>(
            CustomReadValue._readValue(json, 'enabled'),
          ) ??
          false),
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
      id: (id == dataforgeUndefined ? _instance.id : id as String),
      name: (name == dataforgeUndefined ? _instance.name : name as String),
      title: (title == dataforgeUndefined ? _instance.title : title as String),
      count: (count == dataforgeUndefined ? _instance.count : count as int),
      enabled: (enabled == dataforgeUndefined
          ? _instance.enabled
          : enabled as bool),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  R id(String value) {
    final res = CustomReadValue(
      id: value,
      name: _instance.name,
      title: _instance.title,
      count: _instance.count,
      enabled: _instance.enabled,
    );
    return (_then != null ? _then!(res) : res as R);
  }

  R name(String value) {
    final res = CustomReadValue(
      id: _instance.id,
      name: value,
      title: _instance.title,
      count: _instance.count,
      enabled: _instance.enabled,
    );
    return (_then != null ? _then!(res) : res as R);
  }

  R title(String value) {
    final res = CustomReadValue(
      id: _instance.id,
      name: _instance.name,
      title: value,
      count: _instance.count,
      enabled: _instance.enabled,
    );
    return (_then != null ? _then!(res) : res as R);
  }

  R count(int value) {
    final res = CustomReadValue(
      id: _instance.id,
      name: _instance.name,
      title: _instance.title,
      count: value,
      enabled: _instance.enabled,
    );
    return (_then != null ? _then!(res) : res as R);
  }

  R enabled(bool value) {
    final res = CustomReadValue(
      id: _instance.id,
      name: _instance.name,
      title: _instance.title,
      count: _instance.count,
      enabled: value,
    );
    return (_then != null ? _then!(res) : res as R);
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
mixin _IncludeIfNullExample {
  abstract final String name;
  abstract final String? description;
  abstract final int? count;
  _IncludeIfNullExampleCopyWith<IncludeIfNullExample> get copyWith =>
      _IncludeIfNullExampleCopyWith<IncludeIfNullExample>._(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! IncludeIfNullExample) return false;

    return other.name == name &&
        other.description == description &&
        other.count == count;
  }

  @override
  int get hashCode => Object.hashAll([name, description, count]);

  @override
  String toString() =>
      'IncludeIfNullExample(name: $name, description: $description, count: $count)';

  Map<String, dynamic> toJson() {
    return {'name': name, 'description': description, 'count': count};
  }

  static IncludeIfNullExample fromJson(Map<String, dynamic> json) {
    return IncludeIfNullExample(
      name: SafeCasteUtil.readRequiredValue<String>(json, 'name'),
      description: SafeCasteUtil.readValue<String>(json, 'description'),
      count: SafeCasteUtil.readValue<int>(json, 'count'),
    );
  }
}

class _IncludeIfNullExampleCopyWith<R> {
  final _IncludeIfNullExample _instance;
  final R Function(IncludeIfNullExample)? _then;
  _IncludeIfNullExampleCopyWith._(this._instance, [this._then]);

  R call({
    Object? name = dataforgeUndefined,
    Object? description = dataforgeUndefined,
    Object? count = dataforgeUndefined,
  }) {
    final res = IncludeIfNullExample(
      name: (name == dataforgeUndefined ? _instance.name : name as String),
      description: (description == dataforgeUndefined
          ? _instance.description
          : description as String?),
      count: (count == dataforgeUndefined ? _instance.count : count as int?),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  R name(String value) {
    final res = IncludeIfNullExample(
      name: value,
      description: _instance.description,
      count: _instance.count,
    );
    return (_then != null ? _then!(res) : res as R);
  }

  R description(String? value) {
    final res = IncludeIfNullExample(
      name: _instance.name,
      description: value,
      count: _instance.count,
    );
    return (_then != null ? _then!(res) : res as R);
  }

  R count(int? value) {
    final res = IncludeIfNullExample(
      name: _instance.name,
      description: _instance.description,
      count: value,
    );
    return (_then != null ? _then!(res) : res as R);
  }
}
''')
@Dataforge()
class IncludeIfNullExample {
  final String name;

  @JsonKey(includeIfNull: true)
  final String? description;

  @JsonKey(includeIfNull: false)
  final int? count;

  IncludeIfNullExample({
    required this.name,
    this.description,
    this.count,
  });
}
