import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'auto_fromjson_test.model.data.dart';

@Dataforge()
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
