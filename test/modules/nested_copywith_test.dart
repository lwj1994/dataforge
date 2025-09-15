import 'package:test/test.dart';
import '../models/nested_copywith_test.model.dart';

void main() {
  group('Nested CopyWith Tests', () {
    late Address address;
    late Person person;
    late Company company;
    late Department department;
    late Organization organization;
    late CorporateGroup corporateGroup;

    setUp(() {
      // Create test data with nested structures
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

      department = Department(
        name: 'Engineering',
        manager: person,
        parentCompany: company,
        location: address,
      );

      organization = Organization(
        name: 'Global Tech',
        headquarters: address,
        departments: [department],
        founder: person,
        parentCompany: company,
      );

      corporateGroup = CorporateGroup(
        name: 'Tech Holdings',
        mainOrganization: organization,
        subsidiaries: [organization],
        chairman: person,
        registeredAddress: address,
      );
    });

    test('should support basic copyWith functionality', () {
      // Test Address copyWith
      final newAddress = address.copyWith(street: '789 New St');
      expect(newAddress.street, equals('789 New St'));
      expect(newAddress.city, equals('New York'));
      expect(newAddress.zipCode, equals('10001'));
    });

    test('should support nested copyWith - Person with Address', () {
      // Test Person copyWith with nested Address
      final newPerson = person.copyWith(
        name: 'Jane Doe',
        address: address.copyWith(street: '999 Updated St'),
      );

      expect(newPerson.name, equals('Jane Doe'));
      expect(newPerson.age, equals(30));
      expect(newPerson.address.street, equals('999 Updated St'));
      expect(newPerson.address.city, equals('New York'));
    });

    test(
        'should support chained copyWith - Company with nested Person and Address',
        () {
      // Test Company copyWith with nested Person and Address
      final newCompany = company.copyWith(
        name: 'Updated Tech Corp',
        ceo: person.copyWith(
          name: 'New CEO',
          address: address.copyWith(
            street: '777 CEO Street',
            city: 'San Francisco',
          ),
        ),
      );

      expect(newCompany.name, equals('Updated Tech Corp'));
      expect(newCompany.ceo.name, equals('New CEO'));
      expect(newCompany.ceo.address.street, equals('777 CEO Street'));
      expect(newCompany.ceo.address.city, equals('San Francisco'));
      expect(newCompany.ceo.address.zipCode, equals('10001')); // unchanged
    });

    test(
        'should support deep nested copyWith - Department with multiple levels',
        () {
      // Test Department copyWith with nested Company, Person, and Address
      final newDepartment = department.copyWith(
        name: 'Advanced Engineering',
        manager: person.copyWith(
          name: 'Senior Manager',
          age: 35,
        ),
        parentCompany: company.copyWith(
          name: 'Parent Corp Updated',
          ceo: person.copyWith(
            name: 'Updated CEO',
            address: address.copyWith(
              street: '888 Executive Blvd',
            ),
          ),
        ),
        location: address.copyWith(
          street: '555 Department St',
          zipCode: '10003',
        ),
      );

      expect(newDepartment.name, equals('Advanced Engineering'));
      expect(newDepartment.manager.name, equals('Senior Manager'));
      expect(newDepartment.manager.age, equals(35));
      expect(newDepartment.parentCompany.name, equals('Parent Corp Updated'));
      expect(newDepartment.parentCompany.ceo.name, equals('Updated CEO'));
      expect(newDepartment.parentCompany.ceo.address.street,
          equals('888 Executive Blvd'));
      expect(newDepartment.location?.street, equals('555 Department St'));
      expect(newDepartment.location?.zipCode, equals('10003'));
    });

    test(
        'should support very deep nested copyWith - Organization with multiple levels',
        () {
      // Test Organization copyWith with very deep nesting
      final newOrganization = organization.copyWith(
        name: 'Global Tech Updated',
        headquarters: address.copyWith(
          street: '1000 HQ Plaza',
          city: 'Los Angeles',
        ),
        departments: [
          department.copyWith(
            name: 'R&D Department',
            manager: person.copyWith(
              name: 'R&D Manager',
              address: address.copyWith(
                street: '2000 Research Way',
              ),
            ),
            parentCompany: company.copyWith(
              name: 'Research Corp',
            ),
          ),
        ],
        founder: person.copyWith(
          name: 'Company Founder',
          age: 45,
        ),
      );

      expect(newOrganization.name, equals('Global Tech Updated'));
      expect(newOrganization.headquarters.street, equals('1000 HQ Plaza'));
      expect(newOrganization.headquarters.city, equals('Los Angeles'));
      expect(newOrganization.departments.first.name, equals('R&D Department'));
      expect(newOrganization.departments.first.manager.name,
          equals('R&D Manager'));
      expect(newOrganization.departments.first.manager.address.street,
          equals('2000 Research Way'));
      expect(newOrganization.departments.first.parentCompany.name,
          equals('Research Corp'));
      expect(newOrganization.founder.name, equals('Company Founder'));
      expect(newOrganization.founder.age, equals(45));
    });

    test('should support extremely deep nested copyWith - CorporateGroup', () {
      // Test CorporateGroup copyWith with extremely deep nesting
      final newCorporateGroup = corporateGroup.copyWith(
        name: 'Updated Holdings',
        chairman: person.copyWith(
          name: 'Board Chairman',
          age: 55,
          address: address.copyWith(
            street: '3000 Chairman Ave',
            city: 'Chicago',
            zipCode: '60601',
          ),
        ),
        mainOrganization: organization.copyWith(
          name: 'Main Org Updated',
          headquarters: address.copyWith(
            street: '4000 Corporate Blvd',
          ),
          departments: [
            department.copyWith(
              name: 'Strategic Department',
              manager: person.copyWith(
                name: 'Strategic Manager',
                address: address.copyWith(
                  street: '5000 Strategy St',
                ),
              ),
              parentCompany: company.copyWith(
                name: 'Strategic Corp',
                ceo: person.copyWith(
                  name: 'Strategic CEO',
                  age: 40,
                ),
              ),
            ),
          ],
        ),
        registeredAddress: address.copyWith(
          street: '6000 Legal Ave',
          city: 'Washington DC',
          zipCode: '20001',
        ),
      );

      expect(newCorporateGroup.name, equals('Updated Holdings'));
      expect(newCorporateGroup.chairman.name, equals('Board Chairman'));
      expect(newCorporateGroup.chairman.age, equals(55));
      expect(newCorporateGroup.chairman.address.street,
          equals('3000 Chairman Ave'));
      expect(newCorporateGroup.chairman.address.city, equals('Chicago'));
      expect(newCorporateGroup.chairman.address.zipCode, equals('60601'));

      expect(
          newCorporateGroup.mainOrganization.name, equals('Main Org Updated'));
      expect(newCorporateGroup.mainOrganization.headquarters.street,
          equals('4000 Corporate Blvd'));

      final strategicDept =
          newCorporateGroup.mainOrganization.departments.first;
      expect(strategicDept.name, equals('Strategic Department'));
      expect(strategicDept.manager.name, equals('Strategic Manager'));
      expect(strategicDept.manager.address.street, equals('5000 Strategy St'));
      expect(strategicDept.parentCompany.name, equals('Strategic Corp'));
      expect(strategicDept.parentCompany.ceo.name, equals('Strategic CEO'));
      expect(strategicDept.parentCompany.ceo.age, equals(40));

      expect(newCorporateGroup.registeredAddress?.street,
          equals('6000 Legal Ave'));
      expect(
          newCorporateGroup.registeredAddress?.city, equals('Washington DC'));
      expect(newCorporateGroup.registeredAddress?.zipCode, equals('20001'));
    });

    test('should handle nullable fields in nested copyWith', () {
      // Test nullable fields in nested structures
      final personWithoutWork = Person(
        name: 'No Work Person',
        age: 25,
        address: address,
        workAddress: null,
      );

      final updatedPerson = personWithoutWork.copyWith(
        workAddress: address.copyWith(
          street: '777 New Work St',
        ),
      );

      expect(updatedPerson.workAddress, isNotNull);
      expect(updatedPerson.workAddress?.street, equals('777 New Work St'));
      expect(updatedPerson.workAddress?.city, equals('New York'));

      // Test that original person still has null workAddress
      expect(personWithoutWork.workAddress, isNull);

      // Test that updated person has non-null workAddress
      expect(updatedPerson.workAddress, isNotNull);
    });

    test('should preserve immutability in nested copyWith', () {
      // Test that original objects are not modified
      final originalStreet = person.address.street;
      final originalName = person.name;

      final newPerson = person.copyWith(
        name: 'Modified Name',
        address: person.address.copyWith(
          street: 'Modified Street',
        ),
      );

      // Original should be unchanged
      expect(person.name, equals(originalName));
      expect(person.address.street, equals(originalStreet));

      // New object should have changes
      expect(newPerson.name, equals('Modified Name'));
      expect(newPerson.address.street, equals('Modified Street'));

      // Objects should be different instances
      expect(identical(person, newPerson), isFalse);
      expect(identical(person.address, newPerson.address), isFalse);
    });
  });
}
