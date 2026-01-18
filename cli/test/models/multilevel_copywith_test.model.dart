import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:collection/collection.dart';

part 'multilevel_copywith_test.model.data.dart';

/// Test model for multi-level copyWith functionality
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

/// Test model with nested Address
@Dataforge(chainedCopyWith: true)
class User with _User {
  @override
  final String name;
  @override
  final int age;
  @override
  final Address address;

  const User({
    required this.name,
    required this.age,
    required this.address,
  });
  factory User.fromJson(Map<String, dynamic> json) {
    return _User.fromJson(json);
  }
}

/// Test model with deeply nested structure
@Dataforge(chainedCopyWith: true)
class Company with _Company {
  @override
  final String name;
  @override
  final User owner;
  @override
  final List<User> employees;

  const Company({
    required this.name,
    required this.owner,
    required this.employees,
  });
  factory Company.fromJson(Map<String, dynamic> json) {
    return _Company.fromJson(json);
  }
}

/// Test model for complex nested structure
@Dataforge(chainedCopyWith: true)
class Profile with _Profile {
  @override
  final String id;
  @override
  final User user;
  @override
  final Map<String, String> metadata;

  const Profile({
    required this.id,
    required this.user,
    required this.metadata,
  });
  factory Profile.fromJson(Map<String, dynamic> json) {
    return _Profile.fromJson(json);
  }
}
