import 'package:test/test.dart';
import 'models/ignore_test.dart';

void main() {
  group('Ignore Logic Tests', () {
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
      expect(instance == different, isFalse); // should be false because password is different

      // Test that toString includes all fields (including ignored ones)
      final toStringResult = instance.toString();
      expect(toStringResult.contains('password: secret123'), isTrue);
      expect(toStringResult.contains('secretToken: token456'), isTrue);

      print('✓ All ignore logic tests passed!');
    });

    test('fromJson should work without ignored fields', () {
      final json = {
        'name': 'Jane',
        'age': 25,
        'isActive': false,
        // Note: password and secretToken are not in JSON
      };

      final instance = IgnoreTest.fromJson(json);
      expect(instance.name, equals('Jane'));
      expect(instance.age, equals(25));
      expect(instance.isActive, equals(false));
      // ignored fields should have default values from constructor
      // but since fromJson doesn't provide them, they need to be handled
      
      print('✓ fromJson test passed!');
    });
  });
}