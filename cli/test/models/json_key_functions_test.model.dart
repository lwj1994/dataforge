// @author luwenjie on 2025/1/20 10:00:00

import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:collection/collection.dart';

part 'json_key_functions_test.model.data.dart';

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

List<String> customListFromJson(dynamic value) {
  if (value is List) {
    return value.map((e) => 'item_${e.toString()}').toList();
  }
  return [];
}

List<String> customListToJson(List<String> value) {
  return value.map((e) => e.startsWith('item_') ? e.substring(5) : e).toList();
}

int customIntFromJson(dynamic value) {
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  if (value is num) {
    // Reverse the doubling operation from toJson
    return (value.toInt() / 2).round();
  }
  return 0;
}

int customIntToJson(int value) {
  return value * 2; // Double the value for testing
}

@Dataforge()
class JsonKeyFunctionsTest with _JsonKeyFunctionsTest {
  @override
  @JsonKey(
      name: 'custom_name',
      fromJson: customStringFromJson,
      toJson: customStringToJson)
  final String name;

  @override
  @JsonKey(
      name: 'custom_list',
      fromJson: customListFromJson,
      toJson: customListToJson)
  final List<String> items;

  @override
  @JsonKey(
      name: 'custom_count',
      fromJson: customIntFromJson,
      toJson: customIntToJson)
  final int count;

  @override
  @JsonKey(
      name: 'optional_value',
      fromJson: customStringFromJson,
      toJson: customStringToJson)
  final String? optionalValue;

  // Regular field without custom functions for comparison
  @override
  final String regularField;

  const JsonKeyFunctionsTest({
    required this.name,
    required this.items,
    required this.count,
    this.optionalValue,
    required this.regularField,
  });
  factory JsonKeyFunctionsTest.fromJson(Map<String, dynamic> json) {
    return _JsonKeyFunctionsTest.fromJson(json);
  }
}
