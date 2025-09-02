import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:collection/collection.dart';

part 'chained_copywith_test.model.data.dart';

/// Test class with chained copyWith enabled
@Dataforge(chainedCopyWith: true)
class User with _User {
  @override
  final String name;
  @override
  final int age;
  @override
  final String? email;

  const User({
    required this.name,
    required this.age,
    this.email,
  });
  factory User.fromJson(Map<String, dynamic> json) {
    return _User.fromJson(json);
  }
}

/// Test nested class for chained copyWith
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

/// Test class with nested objects
@Dataforge(chainedCopyWith: true)
class Profile with _Profile {
  @override
  final User user;
  @override
  final Address address;
  @override
  final List<String> tags;

  const Profile({
    required this.user,
    required this.address,
    required this.tags,
  });
  factory Profile.fromJson(Map<String, dynamic> json) {
    return _Profile.fromJson(json);
  }
}
