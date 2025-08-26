import 'package:test/test.dart';
import 'models/ignore_test.model.dart';
import 'models/valid_ignore_test.model.dart';

void main() {
  group('Ignore Field Validation Tests', () {
    test('nullable ignored fields should work correctly', () {
      final instance = IgnoreTest(
        name: 'John',
        password: 'secret123', // nullable ignored field
        age: 30,
        secretToken: 'token456', // nullable ignored field
        isActive: true,
      );

      // Test that ignored fields are accessible but not in JSON
      expect(instance.password, equals('secret123'));
      expect(instance.secretToken, equals('token456'));

      final json = instance.toJson();
      expect(json.containsKey('password'), isFalse);
      expect(json.containsKey('secretToken'), isFalse);
      expect(json.containsKey('name'), isTrue);
      expect(json.containsKey('age'), isTrue);
      expect(json.containsKey('isActive'), isTrue);

      print('✓ Nullable ignored fields test passed!');
    });

    test('ignored fields with default values should work correctly', () {
      final instance = ValidIgnoreTest(
        name: 'Jane',
        nullablePassword: 'nullable123',
        passwordWithDefault: 'custom456', // overriding default
        age: 25,
      );

      // Test that ignored fields are accessible but not in JSON
      expect(instance.nullablePassword, equals('nullable123'));
      expect(instance.passwordWithDefault, equals('custom456'));

      final json = instance.toJson();
      expect(json.containsKey('nullablePassword'), isFalse);
      expect(json.containsKey('passwordWithDefault'), isFalse);
      expect(json.containsKey('name'), isTrue);
      expect(json.containsKey('age'), isTrue);

      print('✓ Ignored fields with default values test passed!');
    });

    test('ignored fields should use default values when not provided', () {
      final instance = ValidIgnoreTest(
        name: 'Bob',
        age: 35,
        // Not providing ignored fields - should use defaults
      );

      expect(instance.nullablePassword, isNull); // nullable default
      expect(instance.passwordWithDefault,
          equals('defaultPassword')); // explicit default

      print('✓ Default values for ignored fields test passed!');
    });

    test('fromJson should work without ignored fields in JSON', () {
      final json = {
        'name': 'Alice',
        'age': 28,
        'isActive': true,
        // Note: ignored fields are not in JSON
      };

      final instance = IgnoreTest.fromJson(json);
      expect(instance.name, equals('Alice'));
      expect(instance.age, equals(28));
      expect(instance.isActive, equals(true));
      expect(instance.password, isNull); // ignored field gets null default
      expect(instance.secretToken, isNull); // ignored field gets null default

      print('✓ fromJson without ignored fields test passed!');
    });
  });
}
