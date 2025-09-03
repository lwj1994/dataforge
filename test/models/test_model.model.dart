import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'test_model.model.data.dart';

@Dataforge()
class TestModel with _TestModel {
  @override
  final String name;
  @override
  final Params? param;

  const TestModel({
    required this.name,
    this.param,
  });
  factory TestModel.fromJson(Map<String, dynamic> json) {
    return _TestModel.fromJson(json);
  }
}

@Dataforge()
class Params with _Params {
  @override
  final String value;

  const Params({required this.value});
  factory Params.fromJson(Map<String, dynamic> json) {
    return _Params.fromJson(json);
  }
}
