import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'cross_file_b.dart';

part 'cross_file_a.data.dart';

@Dataforge(deepCopyWith: true)
class ClassA with _ClassA {
  @override
  final ClassB b;

  ClassA({required this.b});

  factory ClassA.fromJson(Map<String, dynamic> json) => _ClassA.fromJson(json);
}
