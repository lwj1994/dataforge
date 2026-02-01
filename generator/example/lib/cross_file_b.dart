import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'cross_file_b.data.dart';

@Dataforge(deepCopyWith: true)
class ClassB with _ClassB {
  @override
  final String name;

  ClassB({required this.name});

  factory ClassB.fromJson(Map<String, dynamic> json) => _ClassB.fromJson(json);
}
