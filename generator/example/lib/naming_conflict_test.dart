import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'naming_conflict_test.data.dart';

/// Test case to verify dollar separator avoids naming conflicts
@Dataforge(deepCopyWith: true)
class TestUser with _TestUser {
  @override
  final String name;
  @override
  final int age;

  TestUser({required this.name, required this.age});
}

@Dataforge(deepCopyWith: true)
class TestProfile with _TestProfile {
  @override
  final TestUser user;

  // This property would conflict with camelCase naming (userName)
  // But with dollar separator (user\$name), there's no conflict!
  @override
  final String userName;

  TestProfile({required this.user, required this.userName});
}

void main() {
  final profile = TestProfile(
    user: TestUser(name: 'John', age: 30),
    userName: 'john_doe',
  );

  // No conflict! user\$name updates the nested user.name
  final updated1 = profile.copyWith.user$name('Jane');
  print('Updated nested user.name: ${updated1.user.name}'); // Jane
  print('userName property unchanged: ${updated1.userName}'); // john_doe

  // userName() method updates the top-level userName property
  final updated2 = profile.copyWith.userName('jane_doe');
  print('User name unchanged: ${updated2.user.name}'); // John
  print('Updated userName property: ${updated2.userName}'); // jane_doe

  final sep = '\$';
  print('\nNo naming conflicts with $sep separator!');
}
