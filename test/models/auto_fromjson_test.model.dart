import 'package:data_class_annotation/data_class_annotation.dart';

part 'auto_fromjson_test.model.data.dart';

@DataClass()
class AutoFromJsonTest with _AutoFromJsonTest {
  @override
  final String name;
  @override
  final int age;
  @override
  final bool isActive;

  const AutoFromJsonTest({
    required this.name,
    required this.age,
    this.isActive = true,
  });
  factory AutoFromJsonTest.fromJson(Map<String, dynamic> json) {
    return _AutoFromJsonTest.fromJson(json);
  }
}
