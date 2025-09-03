import 'package:collection/collection.dart';
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'generic_support_test.model.data.dart';

/// Test class for single generic type parameter support
@Dataforge()
class GenericContainer<T> with _GenericContainer<T> {
  @override
  final T data;
  @override
  final String name;
  @override
  final int? count;

  const GenericContainer({
    required this.data,
    required this.name,
    this.count,
  });

  factory GenericContainer.fromJson(Map<String, dynamic> json) {
    return _GenericContainer.fromJson(json);
  }
}

/// Test class for multiple generic type parameters
@Dataforge()
class GenericPair<T, U> with _GenericPair<T, U> {
  @override
  final T first;
  @override
  final U second;
  @override
  final String label;

  const GenericPair({
    required this.first,
    required this.second,
    required this.label,
  });

  factory GenericPair.fromJson(Map<String, dynamic> json) {
    return _GenericPair.fromJson(json);
  }
}

/// Test class for nested generic types
@Dataforge()
class GenericWrapper<T> with _GenericWrapper<T> {
  @override
  final List<T> items;
  @override
  final Map<String, T> namedItems;
  @override
  final T? optionalItem;

  const GenericWrapper({
    required this.items,
    required this.namedItems,
    this.optionalItem,
  });

  factory GenericWrapper.fromJson(Map<String, dynamic> json) {
    return _GenericWrapper.fromJson(json);
  }
}

/// Test class for bounded generic types
@Dataforge()
class GenericBounded<T> with _GenericBounded<T> {
  @override
  final T value;
  @override
  final List<T> values;

  const GenericBounded({
    required this.value,
    required this.values,
  });

  factory GenericBounded.fromJson(Map<String, dynamic> json) {
    return _GenericBounded.fromJson(json);
  }
}

/// Test enum for generic testing
enum TestStatus {
  active,
  inactive,
  pending,
}

/// Test class combining generics with other features
@Dataforge()
class GenericWithFeatures<T> with _GenericWithFeatures<T> {
  @override
  final T data;

  @override
  @JsonKey(name: 'custom_name')
  final String customField;

  @override
  @JsonKey(ignore: true)
  final String ignoredField;

  @override
  final TestStatus status;
  @override
  final DateTime createdAt;

  const GenericWithFeatures({
    required this.data,
    required this.customField,
    this.ignoredField = 'default',
    required this.status,
    required this.createdAt,
  });

  factory GenericWithFeatures.fromJson(Map<String, dynamic> json) {
    return _GenericWithFeatures.fromJson(json);
  }
}
