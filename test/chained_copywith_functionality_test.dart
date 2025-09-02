import 'package:test/test.dart';
import 'models/chained_copywith_test.model.dart';
import 'models/traditional_copywith_test.model.dart' as traditional;

void main() {
  group('Chained CopyWith Functionality Tests', () {
    test('chained copyWith should work correctly', () {
      // Create initial user
      final user = User(
        name: 'John',
        age: 25,
        email: 'john@example.com',
      );

      // Test chained copyWith for single field
      final updatedName = user.copyWith.name('Jane');
      expect(updatedName.name, equals('Jane'));
      expect(updatedName.age, equals(25));
      expect(updatedName.email, equals('john@example.com'));

      // Test chained copyWith for different field
      final updatedAge = user.copyWith.age(30);
      expect(updatedAge.name, equals('John'));
      expect(updatedAge.age, equals(30));
      expect(updatedAge.email, equals('john@example.com'));

      // Test chained copyWith for nullable field
      final updatedEmail = user.copyWith.email('jane@example.com');
      expect(updatedEmail.name, equals('John'));
      expect(updatedEmail.age, equals(25));
      expect(updatedEmail.email, equals('jane@example.com'));

      // Test setting nullable field to null
      final noEmail = user.copyWith.email(null);
      expect(noEmail.name, equals('John'));
      expect(noEmail.age, equals(25));
      expect(noEmail.email, isNull);
    });

    test('traditional copyWith call method should work', () {
      final user = User(
        name: 'John',
        age: 25,
        email: 'john@example.com',
      );

      // Test traditional copyWith through call method
      final updated = user.copyWith(
        name: 'Jane',
        age: 30,
      );

      expect(updated.name, equals('Jane'));
      expect(updated.age, equals(30));
      expect(updated.email, equals('john@example.com'));
    });

    test('traditional copyWith should work as before', () {
      final user = traditional.User(
        name: 'John',
        age: 25,
        email: 'john@example.com',
      );

      // Test traditional copyWith
      final updated = user.copyWith(
        name: 'Jane',
        age: 30,
      );

      expect(updated.name, equals('Jane'));
      expect(updated.age, equals(30));
      expect(updated.email, equals('john@example.com'));
    });

    test('nested objects with chained copyWith', () {
      final address = Address(
        street: '123 Main St',
        city: 'New York',
        zipCode: '10001',
      );

      final user = User(
        name: 'John',
        age: 25,
        email: 'john@example.com',
      );

      final profile = Profile(
        user: user,
        address: address,
        tags: ['developer', 'flutter'],
      );

      // Test updating nested user through chained copyWith
      final updatedProfile = profile.copyWith.user(
        user.copyWith.name('Jane'),
      );

      expect(updatedProfile.user.name, equals('Jane'));
      expect(updatedProfile.user.age, equals(25));
      expect(updatedProfile.address.street, equals('123 Main St'));
      expect(updatedProfile.tags, equals(['developer', 'flutter']));

      // Test updating address
      final newAddress = address.copyWith.city('Los Angeles');
      final profileWithNewAddress = profile.copyWith.address(newAddress);

      expect(profileWithNewAddress.address.city, equals('Los Angeles'));
      expect(profileWithNewAddress.address.street, equals('123 Main St'));
      expect(profileWithNewAddress.user.name, equals('John'));
    });
  });
}
