// Test file to verify backward compatibility between DataClass and Dataforge annotations

import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'backward_compatibility_test.model.data.dart';

// Test using the new Dataforge annotation
@Dataforge(includeFromJson: true, includeToJson: true)
class UserDataforge with _UserDataforge {
  @override
  final String name;
  @override
  final int age;
  @override
  final String? email;

  const UserDataforge({
    required this.name,
    required this.age,
    this.email,
  });
  factory UserDataforge.fromJson(Map<String, dynamic> json) {
    return _UserDataforge.fromJson(json);
  }
}

// Test using the deprecated DataClass annotation (should still work)
@DataClass(includeFromJson: true, includeToJson: true)
class UserDataClass with _UserDataClass {
  @override
  final String name;
  @override
  final int age;
  @override
  final String? email;

  const UserDataClass({
    required this.name,
    required this.age,
    this.email,
  });
  factory UserDataClass.fromJson(Map<String, dynamic> json) {
    return _UserDataClass.fromJson(json);
  }
}

// Test using the deprecated dataClass constant
@dataClass
class UserDataClassConstant with _UserDataClassConstant {
  @override
  final String name;
  @override
  final int age;

  const UserDataClassConstant({
    required this.name,
    required this.age,
  });
  factory UserDataClassConstant.fromJson(Map<String, dynamic> json) {
    return _UserDataClassConstant.fromJson(json);
  }
}

// Test using the new dataforge constant
@dataforge
class UserDataforgeConstant with _UserDataforgeConstant {
  @override
  final String name;
  @override
  final int age;

  const UserDataforgeConstant({
    required this.name,
    required this.age,
  });
  factory UserDataforgeConstant.fromJson(Map<String, dynamic> json) {
    return _UserDataforgeConstant.fromJson(json);
  }
}
