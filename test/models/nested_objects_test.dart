import 'package:test/test.dart';
import 'nested_objects.model.dart';

void main() {
  group('Nested Objects Deep CopyWith Tests', () {
    late NestedObjects testObject;

    setUp(() {
      testObject = NestedObjects(
        homeAddress: Address(
          street: 'Home Street',
          city: 'Home City',
          state: 'Home State',
          zipCode: '12345',
          country: 'Home Country',
          isPrimary: true,
        ),
        employer: Company(
          name: 'Test Company',
          headquarters: Address(
            street: 'HQ Street',
            city: 'HQ City',
            state: 'HQ State',
            zipCode: '67890',
            country: 'HQ Country',
            isPrimary: false,
          ),
          primaryContact: Contact(
            email: 'contact@company.com',
            phone: '123-456-7890',
            contactType: 'business',
          ),
        ),
        name: '',
        previousAddresses: [],
        primaryContact: Contact(email: '', contactType: ''),
      );
    });

    test(
        'should generate deep nested copyWith methods for employer.headquarters fields',
        () {
      // Test employer$Headquarters$Street
      final updatedStreet =
          testObject.copyWith.employer$Headquarters$Street('New HQ Street');
      expect(
          updatedStreet.employer!.headquarters.street, equals('New HQ Street'));
      expect(updatedStreet.employer!.headquarters.city,
          equals('HQ City')); // Other fields unchanged

      // Test employer$Headquarters$City
      final updatedCity =
          testObject.copyWith.employer$Headquarters$City('New HQ City');
      expect(updatedCity.employer!.headquarters.city, equals('New HQ City'));
      expect(updatedCity.employer!.headquarters.street,
          equals('HQ Street')); // Other fields unchanged

      // Test employer$Headquarters$State
      final updatedState =
          testObject.copyWith.employer$Headquarters$State('New HQ State');
      expect(updatedState.employer!.headquarters.state, equals('New HQ State'));

      // Test employer$Headquarters$ZipCode
      final updatedZip =
          testObject.copyWith.employer$Headquarters$ZipCode('99999');
      expect(updatedZip.employer!.headquarters.zipCode, equals('99999'));

      // Test employer$Headquarters$Country
      final updatedCountry =
          testObject.copyWith.employer$Headquarters$Country('New Country');
      expect(
          updatedCountry.employer!.headquarters.country, equals('New Country'));

      // Test employer$Headquarters$IsPrimary
      final updatedPrimary =
          testObject.copyWith.employer$Headquarters$IsPrimary(true);
      expect(updatedPrimary.employer!.headquarters.isPrimary, equals(true));
    });

    test(
        'should generate deep nested copyWith methods for employer.primaryContact fields',
        () {
      // Test employer$PrimaryContact$Email
      final updatedEmail =
          testObject.copyWith.employer$PrimaryContact$Email('new@company.com');
      expect(updatedEmail.employer!.primaryContact.email,
          equals('new@company.com'));
      expect(updatedEmail.employer!.primaryContact.phone,
          equals('123-456-7890')); // Other fields unchanged

      // Test employer$PrimaryContact$Phone
      final updatedPhone =
          testObject.copyWith.employer$PrimaryContact$Phone('999-888-7777');
      expect(
          updatedPhone.employer!.primaryContact.phone, equals('999-888-7777'));

      // Test employer$PrimaryContact$ContactType
      final updatedType =
          testObject.copyWith.employer$PrimaryContact$ContactType('personal');
      expect(
          updatedType.employer!.primaryContact.contactType, equals('personal'));
    });

    test('should preserve other fields when using deep nested copyWith', () {
      final updated =
          testObject.copyWith.employer$Headquarters$Street('Updated Street');

      // Verify that non-nested fields are preserved
      expect(updated.homeAddress.street, equals('Home Street'));
      expect(updated.homeAddress.city, equals('Home City'));

      // Verify that other nested fields in employer are preserved
      expect(updated.employer!.name, equals('Test Company'));
      expect(updated.employer!.primaryContact.email,
          equals('contact@company.com'));

      // Verify that other fields in headquarters are preserved
      expect(updated.employer!.headquarters.city, equals('HQ City'));
      expect(updated.employer!.headquarters.state, equals('HQ State'));
    });

    test('should work with chained deep nested updates', () {
      final updated = testObject.copyWith
          .employer$Headquarters$Street('New Street')
          .copyWith
          .employer$Headquarters$City('New City')
          .copyWith
          .employer$PrimaryContact$Email('new@email.com');

      expect(updated.employer!.headquarters.street, equals('New Street'));
      expect(updated.employer!.headquarters.city, equals('New City'));
      expect(updated.employer!.primaryContact.email, equals('new@email.com'));

      // Verify other fields are preserved
      expect(updated.employer!.headquarters.state, equals('HQ State'));
      expect(updated.employer!.primaryContact.phone, equals('123-456-7890'));
    });
  });
}
