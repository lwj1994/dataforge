import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'no_prefix_validation_test.model.data.dart';

/// Test model to validate SafeCasteUtil without prefix functionality
/// This model uses normal import to test if generated code doesn't add prefix
@Dataforge()
class NoPrefixValidationTest with _NoPrefixValidationTest {
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

  /// Field with custom JSON key to test JsonKey without prefix
  @override
  @JsonKey(name: 'custom_field')
  final String customField;

  /// Field with ignore annotation to test ignore functionality
  @override
  @JsonKey(ignore: true)
  final String ignoredField;

  const NoPrefixValidationTest({
    required this.name,
    required this.age,
    required this.isActive,
    required this.score,
    this.description,
    required this.customField,
    this.ignoredField = 'default',
  });
  factory NoPrefixValidationTest.fromJson(Map<String, dynamic> json) {
    return _NoPrefixValidationTest.fromJson(json);
  }
}
