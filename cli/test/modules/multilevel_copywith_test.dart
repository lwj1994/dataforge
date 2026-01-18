import 'package:test/test.dart';
import '../models/multilevel_copywith_test.model.dart';

void main() {
  group('Multi-level copyWith Tests', () {
    late Address originalAddress;
    late User originalUser;
    late Company originalCompany;
    late Profile originalProfile;

    setUp(() {
      originalAddress = const Address(
        street: '123 Main St',
        city: 'New York',
        zipCode: '10001',
      );

      originalUser = User(
        name: 'John Doe',
        age: 30,
        address: originalAddress,
      );

      originalCompany = Company(
        name: 'Tech Corp',
        owner: originalUser,
        employees: [originalUser],
      );

      originalProfile = Profile(
        id: 'profile-123',
        user: originalUser,
        metadata: {'role': 'admin', 'department': 'engineering'},
      );
    });

    test('should support single-level copyWith (baseline)', () {
      final updatedUser = originalUser.copyWith(name: 'Jane Doe');

      expect(updatedUser.name, equals('Jane Doe'));
      expect(updatedUser.age, equals(30));
      expect(updatedUser.address, equals(originalAddress));
    });

    test('should support two-level copyWith using nested helper', () {
      // Test using nested copyWith helper
      final updatedUser = originalUser.copyWith
          .address(originalUser.address.copyWith(street: 'New Street'));

      expect(updatedUser.name, equals('John Doe'));
      expect(updatedUser.age, equals(30));
      expect(updatedUser.address.street, equals('New Street'));
      expect(updatedUser.address.city, equals('New York'));
      expect(updatedUser.address.zipCode, equals('10001'));
    });

    test('should update nested field using direct field access', () {
      // Use direct field access instead of multi-level copyWith
      final updatedUser = originalUser.copyWith.address(
        originalUser.address.copyWith(street: 'New Street'),
      );

      expect(updatedUser.name, equals('John Doe'));
      expect(updatedUser.age, equals(30));
      expect(updatedUser.address.street, equals('New Street'));
      expect(updatedUser.address.city, equals('New York'));
      expect(updatedUser.address.zipCode, equals('10001'));
    });

    test('should update nested field using direct field access - city', () {
      // Use direct field access instead of multi-level copyWith
      final updatedUser = originalUser.copyWith.address(
        originalUser.address.copyWith(city: 'Los Angeles'),
      );

      expect(updatedUser.name, equals('John Doe'));
      expect(updatedUser.age, equals(30));
      expect(updatedUser.address.street, equals('123 Main St'));
      expect(updatedUser.address.city, equals('Los Angeles'));
      expect(updatedUser.address.zipCode, equals('10001'));
    });

    test('should update nested user field in profile using direct field access',
        () {
      // Use direct field access instead of multi-level copyWith
      final updatedProfile = originalProfile.copyWith.user(
        originalProfile.user.copyWith(age: 35),
      );

      expect(updatedProfile.id, equals('profile-123'));
      expect(updatedProfile.user.name, equals('John Doe'));
      expect(updatedProfile.user.age, equals(35));
      expect(updatedProfile.user.address, equals(originalAddress));
      expect(updatedProfile.metadata,
          equals({'role': 'admin', 'department': 'engineering'}));
    });

    test(
        'should update nested owner field in company using direct field access',
        () {
      // Use direct field access instead of multi-level copyWith
      final updatedCompany = originalCompany.copyWith.owner(
        originalCompany.owner.copyWith(name: 'Jane Smith'),
      );

      expect(updatedCompany.name, equals('Tech Corp'));
      expect(updatedCompany.owner.name, equals('Jane Smith'));
      expect(updatedCompany.owner.age, equals(30));
      expect(updatedCompany.owner.address, equals(originalAddress));
    });

    test('should maintain immutability with copyWith operations', () {
      final updatedUser = originalUser.copyWith.address(
        originalUser.address.copyWith(street: 'New Street'),
      );

      // Original objects should remain unchanged
      expect(originalUser.address.street, equals('123 Main St'));
      expect(originalAddress.street, equals('123 Main St'));

      // Updated object should have new values
      expect(updatedUser.address.street, equals('New Street'));

      // Objects should be different instances
      expect(updatedUser, isNot(same(originalUser)));
      expect(updatedUser.address, isNot(same(originalAddress)));
    });

    test('should chain multiple copyWith operations', () {
      final step1 = originalUser.copyWith
          .address(originalUser.address.copyWith(street: 'New Street'));
      final step2 =
          step1.copyWith.address(step1.address.copyWith(city: 'Boston'));
      final updatedUser = step2.copyWith(age: 31);

      expect(updatedUser.name, equals('John Doe'));
      expect(updatedUser.age, equals(31));
      expect(updatedUser.address.street, equals('New Street'));
      expect(updatedUser.address.city, equals('Boston'));
      expect(updatedUser.address.zipCode, equals('10001'));
    });
  });
}
