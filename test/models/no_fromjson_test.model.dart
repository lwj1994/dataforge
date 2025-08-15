import 'package:data_class_annotation/data_class_annotation.dart';

part 'no_fromjson_test.model.data.dart';

@DataClass(includeFromJson: false)
class NoFromJsonTest with _NoFromJsonTest {
  @override
  final String name;
  @override
  final int age;

  const NoFromJsonTest({
    required this.name,
    required this.age,
  });
}
