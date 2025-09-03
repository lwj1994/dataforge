import 'package:test/test.dart';
import 'models/default_values.model.dart';

void main() {
  group('Simple Default Values Test', () {
    test('should create DefaultValues with defaults from empty map', () {
      final result = DefaultValues.fromJson({});

      expect(result.intValue, equals(42));
      expect(result.stringValue, equals('default'));
      expect(result.boolValue, equals(true));
      expect(result.doubleValue, equals(3.14));
      expect(result.listValue, equals(['default']));
    });

    test('should create DefaultValues with provided values', () {
      final result = DefaultValues.fromJson({
        'intValue': 100,
        'stringValue': 'test',
        'boolValue': false,
        'doubleValue': 2.5,
        'listValue': ['a', 'b']
      });

      expect(result.intValue, equals(100));
      expect(result.stringValue, equals('test'));
      expect(result.boolValue, equals(false));
      expect(result.doubleValue, equals(2.5));
      expect(result.listValue, equals(['a', 'b']));
    });
  });
}
