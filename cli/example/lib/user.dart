import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'user.data.dart';

@Dataforge()
abstract final class User with _$User {
  const User._();

  factory User({required String name, required List<List<int>> scores}) = _User;

  factory User.fromJson(Map<String, Object?> json) = _User.fromJson;
}
