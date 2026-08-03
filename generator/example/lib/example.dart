import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'example.data.dart';

enum Role { admin, member }

@Dataforge()
abstract final class User with _$User {
  const User._();

  factory User({
    required String name,
    @DataforgeDefault(<String>[]) List<String> tags,
    required Role role,
  }) = _User;

  factory User.fromJson(Map<String, Object?> json) = _User.fromJson;
}

@Dataforge()
abstract final class Team with _$Team {
  const Team._();

  factory Team({
    required String id,
    @DataforgeDefault(<User>[]) List<User> members,
    @DataforgeDefault(<String, Set<int?>>{}) Map<String, Set<int?>> scores,
  }) = _Team;

  factory Team.fromJson(Map<String, Object?> json) = _Team.fromJson;
}
