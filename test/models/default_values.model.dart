import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:collection/collection.dart';

part 'default_values.model.data.dart';

/// Test data class with default value constructor parameters
@Dataforge()
class DefaultValues with _DefaultValues {
  @override
  final int intValue;
  @override
  final String stringValue;
  @override
  final bool boolValue;
  @override
  final double doubleValue;
  @override
  final List<String> listValue;

  const DefaultValues({
    this.intValue = 42,
    this.stringValue = 'default',
    this.boolValue = true,
    this.doubleValue = 3.14,
    this.listValue = const ['default'],
  });

  factory DefaultValues.fromJson(Map<String, dynamic> json) {
    return _DefaultValues.fromJson(json);
  }
}

/// Test default values for nested objects
@Dataforge()
class NestedDefaultValues with _NestedDefaultValues {
  @override
  final String name;
  @override
  final DefaultValues nested;
  @override
  final int? nullableValue;

  const NestedDefaultValues({
    this.name = 'nested_default',
    this.nested = const DefaultValues(),
    this.nullableValue,
  });

  factory NestedDefaultValues.fromJson(Map<String, dynamic> json) {
    return _NestedDefaultValues.fromJson(json);
  }
}
