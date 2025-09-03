import 'package:test/test.dart';
import '../example/generic_support_test.dart';

void main() {
  group('Generic Factory Methods Tests', () {
    test('GenericPair fromJson with type casting', () {
      final json = {'first': 123, 'second': 456.78};

      // Test with direct type casting
      final pair = GenericPair<int, double>.fromJson(json);

      expect(pair.first, equals(123));
      expect(pair.second, equals(456.78));
    });

    test('GenericPair fromJson with string types', () {
      final json = {'first': 'hello', 'second': 'world'};

      // Test with string types
      final pair = GenericPair<String, String>.fromJson(json);

      expect(pair.first, equals('hello'));
      expect(pair.second, equals('world'));
    });

    test('GenericWrapper fromJson with int type', () {
      final json = {'value': 42, 'label': 'test label'};

      final wrapper = GenericWrapper<int>.fromJson(json);

      expect(wrapper.value, equals(42));
      expect(wrapper.label, equals('test label'));
    });

    test('GenericWrapper fromJson with string type', () {
      final json = {'value': 'test value', 'label': 'test label'};

      final wrapper = GenericWrapper<String>.fromJson(json);

      expect(wrapper.value, equals('test value'));
      expect(wrapper.label, equals('test label'));
    });

    test('GenericBounded fromJson with int type', () {
      final json = {'number': 42, 'description': 'test number'};

      final bounded = GenericBounded<int>.fromJson(json);

      expect(bounded.number, equals(42));
      expect(bounded.description, equals('test number'));
    });

    test('GenericWithFeatures fromJson with Map type', () {
      final json = {
        'data': {'key': 'value'},
        'tags': ['tag1', 'tag2'],
        'metadata': {'meta': 'data'},
        'createdAt': '2024-01-15T10:30:00.000Z',
        'status': 'pending',
        'timeout': null
      };

      final features = GenericWithFeatures<Map<String, dynamic>>.fromJson(json);

      expect(features.data, equals({'key': 'value'}));
      expect(features.tags, equals(['tag1', 'tag2']));
      expect(features.status, equals(TestStatus.pending));
      expect(features.timeout, isNull);
    });

    test('Regular fromJson still works for backward compatibility', () {
      final json = {'first': 'hello', 'second': 'world'};

      final pair = GenericPair.fromJson(json);

      // fromJson returns dynamic, so we need to cast
      expect(pair, isA<GenericPair>());
      expect((pair).first, equals('hello'));
      expect((pair).second, equals('world'));
    });
  });
}
