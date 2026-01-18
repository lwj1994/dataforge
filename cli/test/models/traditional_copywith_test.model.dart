import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'traditional_copywith_test.model.data.dart';

/// Test class with traditional copyWith (default behavior)
@Dataforge(chainedCopyWith: false)
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
