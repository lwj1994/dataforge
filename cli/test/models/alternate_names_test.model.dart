import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:collection/collection.dart';

part 'alternate_names_test.model.data.dart';

@Dataforge()
class AlternateNamesTest with _AlternateNamesTest {
  @override
  final String name;

  @override
  @JsonKey(name: "user_age", alternateNames: ["age", "years"])
  final int age;

  @override
  @JsonKey(alternateNames: ["email_address", "mail", "e_mail"])
  final String email;

  @override
  @JsonKey(name: "is_active", alternateNames: ["active", "enabled"])
  final bool isActive;

  @override
  @JsonKey(alternateNames: ["tags_list", "labels"])
  final List<String> tags;

  const AlternateNamesTest({
    required this.name,
    required this.age,
    required this.email,
    required this.isActive,
    this.tags = const [],
  });

  factory AlternateNamesTest.fromJson(Map<String, dynamic> json) =>
      _AlternateNamesTest.fromJson(json);
}
