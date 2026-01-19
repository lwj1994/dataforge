import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'ignore_test.model.data.dart';

@Dataforge()
class IgnoreTest with _IgnoreTest {
  @override
  final String name;

  @override
  @JsonKey(ignore: true)
  final String? password; // Made nullable to satisfy ignore validation

  @override
  final int age;

  @override
  @JsonKey(ignore: true)
  final String? secretToken;

  @override
  final bool isActive;

  const IgnoreTest({
    required this.name,
    this.password, // No longer required since it's nullable
    required this.age,
    this.secretToken,
    required this.isActive,
  });

  factory IgnoreTest.fromJson(Map<String, dynamic> json) {
    return _IgnoreTest.fromJson(json);
  }
}
