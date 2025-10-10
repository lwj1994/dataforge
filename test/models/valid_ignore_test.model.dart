import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'valid_ignore_test.model.data.dart';

// This class should work fine - ignored fields are either nullable or have default values
@Dataforge()
class ValidIgnoreTest with _ValidIgnoreTest {
  @override
  final String name;

  @override
  @JsonKey(ignore: true)
  final String? nullablePassword; // Nullable - OK

  @override
  @JsonKey(ignore: true)
  final String passwordWithDefault; // Has default value - OK

  @override
  final int age;

  const ValidIgnoreTest({
    required this.name,
    this.nullablePassword,
    this.passwordWithDefault = 'defaultPassword', // Default value provided
    required this.age,
  });

  factory ValidIgnoreTest.fromJson(Map<String, dynamic> json) {
    return _ValidIgnoreTest.fromJson(json);
  }
}
