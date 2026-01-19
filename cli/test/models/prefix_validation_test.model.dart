import 'package:dataforge_annotation/dataforge_annotation.dart'
    as dataforge_annotation;

part 'prefix_validation_test.model.data.dart';

/// Test model to validate SafeCasteUtil prefix functionality
/// This model uses aliased import to test if generated code correctly adds prefix
@dataforge_annotation.Dataforge()
class PrefixValidationTest with _PrefixValidationTest {
  /// String field to test SafeCasteUtil.safeCast<String>
  @override
  final String name;

  /// Integer field to test SafeCasteUtil.safeCast<int>
  @override
  final int age;

  /// Boolean field to test SafeCasteUtil.safeCast<bool>
  @override
  final bool isActive;

  /// Double field to test SafeCasteUtil.safeCast<double>
  @override
  final double score;

  /// Nullable string field to test nullable handling
  @override
  final String? description;

  /// Field with custom JSON key to test JsonKey prefix
  @override
  @dataforge_annotation.JsonKey(name: 'custom_field')
  final String customField;

  /// Field with ignore annotation to test ignore functionality
  @override
  @dataforge_annotation.JsonKey(ignore: true)
  final String ignoredField;

  const PrefixValidationTest({
    required this.name,
    required this.age,
    required this.isActive,
    required this.score,
    this.description,
    required this.customField,
    this.ignoredField = 'default',
  });
  factory PrefixValidationTest.fromJson(Map<String, dynamic> json) {
    return _PrefixValidationTest.fromJson(json);
  }
}
