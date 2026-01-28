import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:source_gen_test/annotations.dart';

class GenericConverter<T> extends JsonTypeConverter<T, Object?> {
  const GenericConverter();

  @override
  T fromJson(Object? json) {
    if (json is T) {
      return json;
    }
    return json as T;
  }

  @override
  Object? toJson(T? object) {
    return object;
  }
}

@ShouldGenerate(r'''
mixin _GenericContainer<T> {
  abstract final T data;
  @pragma('vm:prefer-inline')
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
    return {'data': const GenericConverter<dynamic>().toJson(data)};
  }

  static GenericContainer<T> fromJson<T>(Map<String, dynamic> json) {
    return GenericContainer(
      data: const GenericConverter<dynamic>().fromJson(json['data']) as T,
    );
  }
}

class _GenericContainerCopyWith<T, R> {
  final _GenericContainer<T> _instance;
  final R Function(GenericContainer<T>)? _then;
  _GenericContainerCopyWith._(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({Object? data = dataforgeUndefined}) {
    final res = GenericContainer<T>(
      data: SafeCasteUtil.copyWithCast<T>(data, 'data', _instance.data),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R data(T value) {
    final res = call(data: value);
    return res;
  }
}
''')
@Dataforge()
class GenericContainer<T> {
  @JsonKey(converter: GenericConverter())
  final T data;
  GenericContainer({required this.data});
}

// Custom conversion functions for testing
String customStringFromJson(dynamic value) {
  if (value is String) {
    return 'custom_$value';
  }
  return value?.toString() ?? '';
}

String customStringToJson(String value) {
  if (value.startsWith('custom_')) {
    return value.substring(7); // Remove 'custom_' prefix
  }
  return value;
}

int customIntFromJson(dynamic value) {
  if (value is num) {
    return (value.toInt() ~/ 2); // Reverse the doubling
  }
  return int.tryParse(value?.toString() ?? '0') ?? 0;
}

int customIntToJson(int value) {
  return value * 2; // Double the value
}

@ShouldGenerate(r'''
mixin _CustomFunctionsExample {
  abstract final String name;
  abstract final int count;
  abstract final String? optionalValue;
  abstract final String regularField;
  @pragma('vm:prefer-inline')
  _CustomFunctionsExampleCopyWith<CustomFunctionsExample> get copyWith =>
      _CustomFunctionsExampleCopyWith<CustomFunctionsExample>._(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CustomFunctionsExample) return false;

    return other.name == name &&
        other.count == count &&
        other.optionalValue == optionalValue &&
        other.regularField == regularField;
  }

  @override
  int get hashCode =>
      Object.hashAll([name, count, optionalValue, regularField]);

  @override
  String toString() =>
      'CustomFunctionsExample(name: $name, count: $count, optionalValue: $optionalValue, regularField: $regularField)';

  Map<String, dynamic> toJson() {
    return {
      'custom_name': (customStringToJson(name)),
      'custom_count': (customIntToJson(count)),
      'optional_value': (optionalValue != null
          ? customStringToJson(optionalValue!)
          : null),
      'regularField': regularField,
    };
  }

  static CustomFunctionsExample fromJson(Map<String, dynamic> json) {
    return CustomFunctionsExample(
      name: (customStringFromJson(json['custom_name'])),
      count: (customIntFromJson(json['custom_count'])),
      optionalValue: (json['optional_value'] != null
          ? customStringFromJson(json['optional_value'])
          : null),
      regularField: SafeCasteUtil.readRequiredValue<String>(
        json,
        'regularField',
      ),
    );
  }
}

class _CustomFunctionsExampleCopyWith<R> {
  final _CustomFunctionsExample _instance;
  final R Function(CustomFunctionsExample)? _then;
  _CustomFunctionsExampleCopyWith._(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({
    Object? name = dataforgeUndefined,
    Object? count = dataforgeUndefined,
    Object? optionalValue = dataforgeUndefined,
    Object? regularField = dataforgeUndefined,
  }) {
    final res = CustomFunctionsExample(
      name: SafeCasteUtil.copyWithCast<String>(name, 'name', _instance.name),
      count: SafeCasteUtil.copyWithCast<int>(count, 'count', _instance.count),
      optionalValue: SafeCasteUtil.copyWithCastNullable<String>(
        optionalValue,
        'optionalValue',
        _instance.optionalValue,
      ),
      regularField: SafeCasteUtil.copyWithCast<String>(
        regularField,
        'regularField',
        _instance.regularField,
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
  R count(int value) {
    final res = call(count: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  R optionalValue(String? value) {
    final res = call(optionalValue: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  R regularField(String value) {
    final res = call(regularField: value);
    return res;
  }
}
''')
@Dataforge()
class CustomFunctionsExample {
  @JsonKey(
      name: 'custom_name',
      fromJson: customStringFromJson,
      toJson: customStringToJson)
  final String name;

  @JsonKey(
      name: 'custom_count',
      fromJson: customIntFromJson,
      toJson: customIntToJson)
  final int count;

  @JsonKey(
      name: 'optional_value',
      fromJson: customStringFromJson,
      toJson: customStringToJson)
  final String? optionalValue;

  // Regular field without custom functions for comparison
  final String regularField;

  CustomFunctionsExample({
    required this.name,
    required this.count,
    this.optionalValue,
    required this.regularField,
  });
}

// Test readValue + fromJson combination
Object? customReadValue(Map<dynamic, dynamic> map, String key) {
  // Custom logic to read value (e.g., from nested path)
  return map[key];
}

String readValueWithFromJson(dynamic value) {
  return 'processed_$value';
}

@ShouldGenerate(r'''
mixin _ReadValueWithFromJsonExample {
  abstract final String name;
  @pragma('vm:prefer-inline')
  _ReadValueWithFromJsonExampleCopyWith<ReadValueWithFromJsonExample>
  get copyWith =>
      _ReadValueWithFromJsonExampleCopyWith<ReadValueWithFromJsonExample>._(
        this,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ReadValueWithFromJsonExample) return false;

    return other.name == name;
  }

  @override
  int get hashCode => Object.hashAll([name]);

  @override
  String toString() => 'ReadValueWithFromJsonExample(name: $name)';

  Map<String, dynamic> toJson() {
    return {'name': name};
  }

  static ReadValueWithFromJsonExample fromJson(Map<String, dynamic> json) {
    return ReadValueWithFromJsonExample(
      name: (readValueWithFromJson(customReadValue(json, 'name'))),
    );
  }
}

class _ReadValueWithFromJsonExampleCopyWith<R> {
  final _ReadValueWithFromJsonExample _instance;
  final R Function(ReadValueWithFromJsonExample)? _then;
  _ReadValueWithFromJsonExampleCopyWith._(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({Object? name = dataforgeUndefined}) {
    final res = ReadValueWithFromJsonExample(
      name: SafeCasteUtil.copyWithCast<String>(name, 'name', _instance.name),
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
@Dataforge()
class ReadValueWithFromJsonExample {
  @JsonKey(readValue: customReadValue, fromJson: readValueWithFromJson)
  final String name;

  ReadValueWithFromJsonExample({required this.name});
}
