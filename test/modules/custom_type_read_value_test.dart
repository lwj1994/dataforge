import 'package:test/test.dart';
import '../models/custom_type_read_value_test.model.dart';

void main() {
  group('CustomTypeReadValueTest', () {
    test('should handle tradeInfo with SOLD_OUT status (returns null)', () {
      final json = {
        'tradeInfo': {
          'status': 'SOLD_OUT',
          'price': 100.0,
        },
        'userInfo': {
          'name': 'John',
          'age': 25,
        },
      };

      final result = CustomTypeReadValueTest.fromJson(json);

      expect(result.tradeInfo, isNull); // Should be null due to SOLD_OUT status
      expect(result.userInfo.name, equals('John'));
      expect(result.userInfo.age, equals(25));
    });

    test('should handle tradeInfo with normal status', () {
      final json = {
        'tradeInfo': {
          'status': 'AVAILABLE',
          'price': 150.0,
        },
        'userInfo': {
          'name': 'Jane',
          'age': 30,
        },
      };

      final result = CustomTypeReadValueTest.fromJson(json);

      expect(result.tradeInfo, isNotNull);
      expect(result.tradeInfo!.status, equals('AVAILABLE'));
      expect(result.tradeInfo!.price, equals(150.0));
      expect(result.userInfo.name, equals('Jane'));
      expect(result.userInfo.age, equals(30));
    });

    test('should handle userInfo from alternate key', () {
      final json = {
        'user': {
          // Using alternate key 'user' instead of 'userInfo'
          'name': 'Bob',
          'age': 35,
        },
      };

      final result = CustomTypeReadValueTest.fromJson(json);

      expect(result.tradeInfo, isNull);
      expect(result.userInfo.name, equals('Bob'));
      expect(result.userInfo.age, equals(35));
    });

    test('should handle missing userInfo (uses empty map)', () {
      final json = <String, dynamic>{};

      final result = CustomTypeReadValueTest.fromJson(json);

      expect(result.tradeInfo, isNull);
      // userInfo should be created from empty map with default values
      expect(result.userInfo.name, equals(''));
      expect(result.userInfo.age, equals(0));
    });
  });
}
