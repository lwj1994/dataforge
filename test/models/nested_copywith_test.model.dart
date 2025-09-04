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
