import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:collection/collection.dart';

part 'nested_copywith_example.data.dart';

/// Address model with street, city and zipCode
@Dataforge(chainedCopyWith: true)
class Address with _Address {
  @override
  final String street;
  @override
  final String city;
  @override
  final String zipCode;

  const Address({
    required this.street,
    required this.city,
    required this.zipCode,
  });
  factory Address.fromJson(Map<String, dynamic> json) {
    return _Address.fromJson(json);
  }
}

/// Person model with name, age and address
@Dataforge(chainedCopyWith: true)
class Person with _Person {
  @override
  final String name;
  @override
  final int age;
  @override
  final Address address;
  @override
  final Address? workAddress;

  const Person({
    required this.name,
    required this.age,
    required this.address,
    this.workAddress,
  });
  factory Person.fromJson(Map<String, dynamic> json) {
    return _Person.fromJson(json);
  }
}

/// Company model with name and CEO
@Dataforge(chainedCopyWith: true)
class Company with _Company {
  @override
  final String name;
  @override
  final Person ceo;
  @override
  final List<Person> employees;

  const Company({
    required this.name,
    required this.ceo,
    required this.employees,
  });
  factory Company.fromJson(Map<String, dynamic> json) {
    return _Company.fromJson(json);
  }
}

void main() {
  // Create initial data
  final address = Address(
    street: '123 Main St',
    city: 'New York',
    zipCode: '10001',
  );

  final workAddress = Address(
    street: '456 Work Ave',
    city: 'New York',
    zipCode: '10002',
  );

  final person = Person(
    name: 'John Doe',
    age: 30,
    address: address,
    workAddress: workAddress,
  );

  final company = Company(
    name: 'Tech Corp',
    ceo: person,
    employees: [person],
  );

  print('=== Original Data ===');
  print('Company: ${company.name}');
  print('CEO: ${company.ceo.name}, Age: ${company.ceo.age}');
  print(
      'CEO Address: ${company.ceo.address.street}, ${company.ceo.address.city}');
  print('');

  // Example 1: Single level copyWith
  print('=== Example 1: Single Level CopyWith ===');
  final updatedCompany1 = company.copyWith.name('New Tech Corp');
  print('Updated company name: ${updatedCompany1.name}');
  print('');

  // Example 2: Nested copyWith - Update CEO's name
  print('=== Example 2: Nested CopyWith - CEO Name ===');
  final updatedCompany2 =
      company.copyWith.ceoBuilder((ceo) => ceo.copyWith.name('Jane Smith'));
  print('Updated CEO name: ${updatedCompany2.ceo.name}');
  print('CEO address unchanged: ${updatedCompany2.ceo.address.street}');
  print('');

  // Example 3: Multi-level nested copyWith - Update CEO's address
  print('=== Example 3: Multi-Level Nested CopyWith ===');
  final updatedCompany3 = company.copyWith.ceoBuilder((ceo) => ceo.copyWith
      .addressBuilder((addr) => addr.copyWith.street('999 Executive Blvd')));
  print('Updated CEO address: ${updatedCompany3.ceo.address.street}');
  print('CEO name unchanged: ${updatedCompany3.ceo.name}');
  print('Address city unchanged: ${updatedCompany3.ceo.address.city}');
  print('');

  // Example 4: Complex multi-level updates
  print('=== Example 4: Complex Multi-Level Updates ===');
  final updatedCompany4 = company.copyWith.ceoBuilder((ceo) => ceo.copyWith
      .name('Alice Johnson')
      .copyWith
      .age(35)
      .copyWith
      .addressBuilder((addr) => addr.copyWith
          .street('777 CEO Lane')
          .copyWith
          .city('San Francisco')
          .copyWith
          .zipCode('94105')));
  print(
      'Updated CEO: ${updatedCompany4.ceo.name}, Age: ${updatedCompany4.ceo.age}');
  print(
      'Updated CEO Address: ${updatedCompany4.ceo.address.street}, ${updatedCompany4.ceo.address.city}, ${updatedCompany4.ceo.address.zipCode}');
  print('Work address unchanged: ${updatedCompany4.ceo.workAddress?.street}');
  print('');

  // Example 5: Nullable nested copyWith
  print('=== Example 5: Nullable Nested CopyWith ===');
  final updatedCompany5 = company.copyWith.ceoBuilder((ceo) => ceo.copyWith
      .workAddressBuilder((workAddr) => workAddr.copyWith.city('Boston')));
  print('Updated work address city: ${updatedCompany5.ceo.workAddress?.city}');
  print(
      'Work address street unchanged: ${updatedCompany5.ceo.workAddress?.street}');
  print('Home address unchanged: ${updatedCompany5.ceo.address.city}');
}
