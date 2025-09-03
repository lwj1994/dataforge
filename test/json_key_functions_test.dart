// @author luwenjie on 2025/1/20 10:00:00

import 'package:test/test.dart';
import 'models/json_key_functions_test.model.dart';

void main() {
  group('JsonKey fromJson and toJson functions', () {
    test('should use custom fromJson functions when deserializing', () {
      final json = {
        'custom_name': 'test',
        'custom_list': ['a', 'b', 'c'],
        'custom_count': '42',
        'optional_value': 'optional',
        'regularField': 'regular'
      };

      final result = JsonKeyFunctionsTest.fromJson(json);

      // Custom string fromJson adds 'custom_' prefix
      expect(result.name, equals('custom_test'));

      // Custom list fromJson adds 'item_' prefix to each element
      expect(result.items, equals(['item_a', 'item_b', 'item_c']));

      // Custom int fromJson parses string to int
      expect(result.count, equals(42));

      // Optional value should also use custom function
      expect(result.optionalValue, equals('custom_optional'));

      // Regular field should work normally
      expect(result.regularField, equals('regular'));
    });

    test('should use custom toJson functions when serializing', () {
      final instance = JsonKeyFunctionsTest(
        name: 'custom_test',
        items: ['item_a', 'item_b', 'item_c'],
        count: 21,
        optionalValue: 'custom_optional',
        regularField: 'regular',
      );

      final json = instance.toJson();

      // Custom string toJson removes 'custom_' prefix
      expect(json['custom_name'], equals('test'));

      // Custom list toJson removes 'item_' prefix from each element
      expect(json['custom_list'], equals(['a', 'b', 'c']));

      // Custom int toJson doubles the value
      expect(json['custom_count'], equals(42));

      // Optional value should also use custom function
      expect(json['optional_value'], equals('optional'));

      // Regular field should work normally
      expect(json['regularField'], equals('regular'));
    });

    test('should handle null optional values correctly', () {
      final json = {
        'custom_name': 'test',
        'custom_list': ['a'],
        'custom_count': '10',
        'regularField': 'regular'
        // optional_value is missing
      };

      final result = JsonKeyFunctionsTest.fromJson(json);
      expect(result.optionalValue, isNull);

      final serialized = result.toJson();
      expect(serialized.containsKey('optional_value'), isFalse);
    });

    test('should round-trip correctly with custom functions', () {
      final original = JsonKeyFunctionsTest(
        name: 'custom_roundtrip',
        items: ['item_x', 'item_y'],
        count: 15,
        optionalValue: 'custom_test',
        regularField: 'unchanged',
      );

      // Serialize to JSON
      final json = original.toJson();

      // Deserialize back
      final restored = JsonKeyFunctionsTest.fromJson(json);

      // Should be equal to original
      expect(restored, equals(original));
    });
  });
}
