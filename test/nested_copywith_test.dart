import 'package:test/test.dart';
import 'models/nested_copywith_test.model.dart';

void main() {
  group('Nested CopyWith Tests', () {
    late Address address;
    late Person person;
    late Company company;

    setUp(() {
      address = const Address(
        street: '123 Main St',
        city: 'New York',
        zipCode: '10001',
      );

      person = Person(
        name: 'John Doe',
        age: 30,
        address: address,
        workAddress: const Address(
          street: '456 Work Ave',
          city: 'New York',
          zipCode: '10002',
        ),
      );

      company = Company(
        name: 'Tech Corp',
        ceo: person,
        employees: [person],
      );
    });

    test('should support single level copyWith', () {
      final newAddress = address.copyWith.street('456 Oak St');

      expect(newAddress.street, equals('456 Oak St'));
      expect(newAddress.city, equals('New York'));
      expect(newAddress.zipCode, equals('10001'));
    });

    test('should support nested copyWith using function', () {
      final newPerson = person.copyWith
          .addressBuilder((addr) => addr.copyWith.street('789 New St'));

      expect(newPerson.name, equals('John Doe'));
      expect(newPerson.age, equals(30));
      expect(newPerson.address.street, equals('789 New St'));
      expect(newPerson.address.city, equals('New York'));
      expect(newPerson.address.zipCode, equals('10001'));
      expect(newPerson.workAddress?.street, equals('456 Work Ave'));
    });

    test('should support nullable nested copyWith', () {
      final newPerson = person.copyWith
          .workAddressBuilder((addr) => addr.copyWith.city('Boston'));

      expect(newPerson.name, equals('John Doe'));
      expect(newPerson.age, equals(30));
      expect(newPerson.address.street, equals('123 Main St'));
      expect(newPerson.workAddress?.street, equals('456 Work Ave'));
      expect(newPerson.workAddress?.city, equals('Boston'));
      expect(newPerson.workAddress?.zipCode, equals('10002'));
    });

    test('should support multi-level nested copyWith', () {
      final newCompany = company.copyWith.ceoBuilder((ceo) => ceo.copyWith
          .addressBuilder(
              (addr) => addr.copyWith.street('999 Executive Blvd')));

      expect(newCompany.name, equals('Tech Corp'));
      expect(newCompany.ceo.name, equals('John Doe'));
      expect(newCompany.ceo.age, equals(30));
      expect(newCompany.ceo.address.street, equals('999 Executive Blvd'));
      expect(newCompany.ceo.address.city, equals('New York'));
      expect(newCompany.ceo.address.zipCode, equals('10001'));
      expect(newCompany.employees.length, equals(1));
      expect(newCompany.employees.first.address.street,
          equals('123 Main St')); // Original unchanged
    });

    test('should support complex multi-level updates', () {
      final newCompany = company.copyWith.ceoBuilder((ceo) => ceo.copyWith
          .name('Jane Smith')
          .copyWith
          .age(35)
          .copyWith
          .addressBuilder((addr) => addr.copyWith
              .street('777 CEO Lane')
              .copyWith
              .city('San Francisco')
              .copyWith
              .zipCode('94105')));

      expect(newCompany.name, equals('Tech Corp'));
      expect(newCompany.ceo.name, equals('Jane Smith'));
      expect(newCompany.ceo.age, equals(35));
      expect(newCompany.ceo.address.street, equals('777 CEO Lane'));
      expect(newCompany.ceo.address.city, equals('San Francisco'));
      expect(newCompany.ceo.address.zipCode, equals('94105'));
    });

    test('should handle null nested objects gracefully', () {
      final personWithoutWork = Person(
        name: 'Bob',
        age: 25,
        address: address,
        workAddress: null,
      );

      // This should return the same instance since workAddress is null
      final result = personWithoutWork.copyWith
          .workAddressBuilder((addr) => addr.copyWith.city('Boston'));
      expect(identical(result, personWithoutWork), isTrue);
    });
  });
}
