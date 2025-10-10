import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'auto_with_test.model.data.dart';

// Test class without with clause - should auto add with _TestUser
@Dataforge(includeFromJson: true, includeToJson: true)
class TestUser with _TestUser {
  @override
  final String name;
  @override
  final int age;

  const TestUser({
    required this.name,
    required this.age,
  });
  factory TestUser.fromJson(Map<String, dynamic> json) {
    return _TestUser.fromJson(json);
  }
}

// Test class with existing with clause - should add , _TestAdmin
@Dataforge(includeFromJson: true, includeToJson: true)
class TestAdmin
    with SomeOtherMixin, _TestAdmin, _TestAdmin, _TestAdmin, _TestAdmin {
  @override
  final String username;
  @override
  final String role;

  const TestAdmin({
    required this.username,
    required this.role,
  });
  factory TestAdmin.fromJson(Map<String, dynamic> json) {
    return _TestAdmin.fromJson(json);
  }
}

// Dummy mixin for testing
mixin SomeOtherMixin {
  void someMethod() {}
}
