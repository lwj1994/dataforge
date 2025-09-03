import 'package:test/test.dart';
import '../models/ignore_test.model.dart';
import '../models/valid_ignore_test.model.dart';

/// 忽略字段测试模块
/// 包含：忽略逻辑、忽略验证测试
void runIgnoreTests() {
  group('Ignore Field Tests', () {
    group('Ignore Logic', () {
      test('ignore fields should be present in class but not in JSON', () {
        final instance = IgnoreTest(
          name: 'John',
          password: 'secret123',
          age: 30,
          secretToken: 'token456',
          isActive: true,
        );

        // Test that all fields are accessible (including ignored ones)
        expect(instance.name, equals('John'));
        expect(instance.password, equals('secret123'));
        expect(instance.age, equals(30));
        expect(instance.secretToken, equals('token456'));
        expect(instance.isActive, equals(true));

        // Test that ignored fields are NOT in JSON
        final json = instance.toJson();
        expect(json.containsKey('name'), isTrue);
        expect(json.containsKey('age'), isTrue);
        expect(json.containsKey('isActive'), isTrue);
        expect(json.containsKey('password'), isFalse); // ignored field
        expect(json.containsKey('secretToken'), isFalse); // ignored field

        // Test that copyWith includes all fields (including ignored ones)
        final copied = instance.copyWith(
          password: 'newPassword',
          secretToken: 'newToken',
        );
        expect(copied.password, equals('newPassword'));
        expect(copied.secretToken, equals('newToken'));
        expect(copied.name, equals('John')); // unchanged

        // Test that equals includes all fields (including ignored ones)
        final same = IgnoreTest(
          name: 'John',
          password: 'secret123',
          age: 30,
          secretToken: 'token456',
          isActive: true,
        );
        expect(instance == same, isTrue);

        final different = IgnoreTest(
          name: 'John',
          password: 'differentPassword', // different ignored field
          age: 30,
          secretToken: 'token456',
          isActive: true,
        );
        expect(instance == different, isFalse);
      });

      test('fromJson should work with missing ignored fields', () {
        final json = {
          'name': 'Jane',
          'age': 25,
          'isActive': false,
          // password and secretToken are ignored, so not in JSON
        };

        final instance = IgnoreTest.fromJson(json);
        expect(instance.name, equals('Jane'));
        expect(instance.age, equals(25));
        expect(instance.isActive, equals(false));
        // Ignored fields should have default values or be null
        expect(instance.password, isNull);
        expect(instance.secretToken, isNull);
      });

      test('toString should include all fields including ignored ones', () {
        final instance = IgnoreTest(
          name: 'John',
          password: 'secret123',
          age: 30,
          secretToken: 'token456',
          isActive: true,
        );

        final stringRepresentation = instance.toString();
        expect(stringRepresentation, contains('John'));
        expect(stringRepresentation, contains('secret123'));
        expect(stringRepresentation, contains('30'));
        expect(stringRepresentation, contains('token456'));
        expect(stringRepresentation, contains('true'));
      });
    });

    group('Ignore Validation', () {
      test('nullable ignored fields should work correctly', () {
        final instance = IgnoreTest(
          name: 'John',
          password: 'secret123',
          age: 30,
          secretToken: 'token456',
          isActive: true,
        );

        expect(instance.password, equals('secret123'));
        expect(instance.secretToken, equals('token456'));

        final json = instance.toJson();
        expect(json.containsKey('password'), isFalse);
        expect(json.containsKey('secretToken'), isFalse);
        expect(json.containsKey('name'), isTrue);
        expect(json.containsKey('age'), isTrue);
        expect(json.containsKey('isActive'), isTrue);
      });

      test('ignored fields with default values should work correctly', () {
        final instance = ValidIgnoreTest(
          name: 'Jane',
          nullablePassword: 'nullable123',
          passwordWithDefault: 'custom456',
          age: 25,
        );

        expect(instance.nullablePassword, equals('nullable123'));
        expect(instance.passwordWithDefault, equals('custom456'));

        final json = instance.toJson();
        expect(json.containsKey('nullablePassword'), isFalse);
        expect(json.containsKey('passwordWithDefault'), isFalse);
        expect(json.containsKey('name'), isTrue);
        expect(json.containsKey('age'), isTrue);
      });

      test(
          'ignored fields should not affect JSON serialization/deserialization cycle',
          () {
        final original = ValidIgnoreTest(
          name: 'Test User',
          nullablePassword: 'secret',
          passwordWithDefault: 'custom',
          age: 30,
        );

        final json = original.toJson();
        final restored = ValidIgnoreTest.fromJson(json);

        // Non-ignored fields should be preserved
        expect(restored.name, equals(original.name));
        expect(restored.age, equals(original.age));

        // Ignored fields should have default values after deserialization
        expect(restored.nullablePassword, isNull);
        expect(restored.passwordWithDefault, equals('defaultPassword'));
      });
    });
  });
}

/// Main function for standalone test execution
void main() {
  runIgnoreTests();
}
