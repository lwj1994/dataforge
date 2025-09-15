import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:collection/collection.dart';

part 'nested_copywith_test.model.data.dart';

/// Test model for nested copyWith functionality
@Dataforge(chainedCopyWith: true)
class Address with _Address {
  @override
  final String street;
  @override
  final String city;
  @override
  final String? zipCode;

  const Address({
    required this.street,
    required this.city,
    this.zipCode,
  });
  factory Address.fromJson(Map<String, dynamic> json) {
    return _Address.fromJson(json);
  }
}

/// Test model with nested Address
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

/// Test model with nested Person
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

/// Test model for department with nested company
@Dataforge(chainedCopyWith: true)
class Department with _Department {
  @override
  final String name;
  @override
  final Person manager;
  @override
  final Company parentCompany;
  @override
  final Address? location;

  const Department({
    required this.name,
    required this.manager,
    required this.parentCompany,
    this.location,
  });
  factory Department.fromJson(Map<String, dynamic> json) {
    return _Department.fromJson(json);
  }
}

/// Test model for organization with multiple nested levels
@Dataforge(chainedCopyWith: true)
class Organization with _Organization {
  @override
  final String name;
  @override
  final Address headquarters;
  @override
  final List<Department> departments;
  @override
  final Person founder;
  @override
  final Company? parentCompany;

  const Organization({
    required this.name,
    required this.headquarters,
    required this.departments,
    required this.founder,
    this.parentCompany,
  });
  factory Organization.fromJson(Map<String, dynamic> json) {
    return _Organization.fromJson(json);
  }
}

/// Test model for corporate group with deep nesting
@Dataforge(chainedCopyWith: true)
class CorporateGroup with _CorporateGroup {
  @override
  final String name;
  @override
  final Organization mainOrganization;
  @override
  final List<Organization> subsidiaries;
  @override
  final Person chairman;
  @override
  final Address? registeredAddress;

  const CorporateGroup({
    required this.name,
    required this.mainOrganization,
    required this.subsidiaries,
    required this.chairman,
    this.registeredAddress,
  });
  factory CorporateGroup.fromJson(Map<String, dynamic> json) {
    return _CorporateGroup.fromJson(json);
  }
}
