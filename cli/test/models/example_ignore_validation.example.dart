// Example demonstrating ignore field validation
// Run: dart run bin/data_class_gen.dart

import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'example_ignore_validation.example.data.dart';

/// ✅ Valid: ignored field is nullable
@Dataforge()
class ValidExample1 with _ValidExample1 {
  @override
  final String name;

  @override
  @JsonKey(ignore: true)
  final String? password; // ✅ nullable - OK

  const ValidExample1({
    required this.name,
    this.password,
  });

  factory ValidExample1.fromJson(Map<String, dynamic> json) {
    return _ValidExample1.fromJson(json);
  }
}

/// ✅ Valid: ignored field has default value
@Dataforge()
class ValidExample2 with _ValidExample2 {
  @override
  final String name;

  @override
  @JsonKey(ignore: true)
  final String secret; // ✅ has default value - OK

  const ValidExample2({
    required this.name,
    this.secret = 'defaultSecret', // default value provided
  });

  factory ValidExample2.fromJson(Map<String, dynamic> json) {
    return _ValidExample2.fromJson(json);
  }
}

/// ❌ Invalid: This would cause an error if uncommented
/// because 'token' is ignored but not nullable and has no default value
/*
@Dataforge()
class InvalidExample with _InvalidExample {
  @override
  final String name;
  
  @override
  @JsonKey(ignore: true)
  final String token; // ❌ ERROR: not nullable and no default value
  
  const InvalidExample({
    required this.name,
    required this.token, // required but ignored - this causes error
  });
}
*/

void main() {
  print('Ignore field validation examples:');

  // Example 1: nullable ignored field
  final example1 = ValidExample1(name: 'John', password: 'secret123');
  final json1 = example1.toJson();
  print('Example 1 JSON: $json1'); // password not included

  // Example 2: ignored field with default value
  final example2 = ValidExample2(name: 'Jane');
  final json2 = example2.toJson();
  print('Example 2 JSON: $json2'); // secret not included
  print('Example 2 secret: ${example2.secret}'); // but accessible in code

  // fromJson works without ignored fields
  final restored1 = ValidExample1.fromJson({'name': 'Bob'});
  print(
      'Restored example 1: ${restored1.name}, password: ${restored1.password}');

  final restored2 = ValidExample2.fromJson({'name': 'Alice'});
  print('Restored example 2: ${restored2.name}, secret: ${restored2.secret}');
}
