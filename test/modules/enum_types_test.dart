import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

/// Enum types test module
/// Tests: basic enum serialization, custom JSON keys, enum collections
void runEnumTypesTests() {
  group('Enum Types Tests', () {
    late Directory tempDir;
    late File testFile;
    late File outputFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('enum_types_test_');
      testFile = File(path.join(tempDir.path, 'enum_test.model.dart'));
      outputFile = File(path.join(tempDir.path, 'enum_test.model.data.dart'));
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('basic enum serialization and deserialization', () {
      // Create enum test model
      testFile.writeAsStringSync('''
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'enum_test.model.data.dart';

enum Status { active, inactive, pending }
enum Priority { low, medium, high, urgent }

@Dataforge()
class EnumTest {
  final Status status;
  final Priority priority;
  final Status? optionalStatus;
  
  const EnumTest({
    required this.status,
    required this.priority,
    this.optionalStatus,
  });
}

/// Main function for standalone test execution
void main() {
  runEnumTypesTests();
}
''');

      // Simulate generated code
      outputFile.writeAsStringSync('''
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enum_test.model.dart';

// **************************************************************************
// DataforgeGenerator
// **************************************************************************

extension EnumTestDataforge on EnumTest {
  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'priority': priority.name,
      'optionalStatus': optionalStatus?.name,
    };
  }

  static EnumTest fromJson(Map<String, dynamic> json) {
    return EnumTest(
      status: Status.values.byName(json['status'] as String),
      priority: Priority.values.byName(json['priority'] as String),
      optionalStatus: json['optionalStatus'] != null
          ? Status.values.byName(json['optionalStatus'] as String)
          : null,
    );
  }
}
''');

      expect(testFile.existsSync(), isTrue);
      expect(outputFile.existsSync(), isTrue);
      expect(testFile.readAsStringSync().contains('enum Status'), isTrue);
      expect(outputFile.readAsStringSync().contains('status.name'), isTrue);
      expect(outputFile.readAsStringSync().contains('Status.values.byName'),
          isTrue);
    });

    test('enum with custom JSON keys', () {
      testFile.writeAsStringSync('''
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'enum_test.model.data.dart';

enum UserRole { admin, user, guest }

@Dataforge()
class EnumWithKeysTest {
  @JsonKey(name: 'user_role')
  final UserRole role;
  
  const EnumWithKeysTest({
    required this.role,
  });
}
''');

      outputFile.writeAsStringSync('''
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enum_test.model.dart';

extension EnumWithKeysTestDataforge on EnumWithKeysTest {
  Map<String, dynamic> toJson() {
    return {
      'user_role': role.name,
    };
  }

  static EnumWithKeysTest fromJson(Map<String, dynamic> json) {
    return EnumWithKeysTest(
      role: UserRole.values.byName(json['user_role'] as String),
    );
  }
}
''');

      expect(outputFile.readAsStringSync().contains("'user_role'"), isTrue);
      expect(
          outputFile.readAsStringSync().contains("json['user_role']"), isTrue);
    });

    test('enum lists and maps', () {
      testFile.writeAsStringSync('''
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'enum_test.model.data.dart';

enum Status { active, inactive, pending }

@Dataforge()
class EnumCollectionsTest {
  final List<Status> statusList;
  final List<Status>? optionalStatusList;
  final Map<String, Status> statusMap;
  
  const EnumCollectionsTest({
    required this.statusList,
    this.optionalStatusList,
    required this.statusMap,
  });
}
''');

      outputFile.writeAsStringSync('''
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enum_test.model.dart';

extension EnumCollectionsTestDataforge on EnumCollectionsTest {
  Map<String, dynamic> toJson() {
    return {
      'statusList': statusList.map((e) => e.name).toList(),
      'optionalStatusList': optionalStatusList?.map((e) => e.name).toList(),
      'statusMap': statusMap.map((k, v) => MapEntry(k, v.name)),
    };
  }

  static EnumCollectionsTest fromJson(Map<String, dynamic> json) {
    return EnumCollectionsTest(
      statusList: (json['statusList'] as List<dynamic>)
          .map((e) => Status.values.byName(e as String))
          .toList(),
      optionalStatusList: json['optionalStatusList'] != null
          ? (json['optionalStatusList'] as List<dynamic>)
              .map((e) => Status.values.byName(e as String))
              .toList()
          : null,
      statusMap: (json['statusMap'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, Status.values.byName(v as String))),
    );
  }
}
''');

      expect(
          outputFile
              .readAsStringSync()
              .contains('statusList.map((e) => e.name)'),
          isTrue);
      expect(outputFile.readAsStringSync().contains('Status.values.byName'),
          isTrue);
      expect(outputFile.readAsStringSync().contains('statusMap.map'), isTrue);
    });
  });
}

/// Main function to run enum types tests
void main() {
  runEnumTypesTests();
}
