import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'defalt_converter.data.dart';

@Dataforge()
class Test with _Test {
  @override
  final DateTime createdAt;
  @override
  final DateTime? createdAtNull;

  Test({required this.createdAt, this.createdAtNull});
  factory Test.fromJson(Map<String, dynamic> json) {
    return _Test.fromJson(json);
  }
}
