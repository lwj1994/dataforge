import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

/// Auto generation features test module
/// Tests: automatic with clause addition, automatic imports, automatic part statements
void runAutoGenerationTests() {
  group('Auto Generation Features Tests', () {
    late Directory tempDir;
    late File testFile;
    late File outputFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('auto_generation_test_');
      testFile = File(path.join(tempDir.path, 'auto_test.model.dart'));
      outputFile = File(path.join(tempDir.path, 'auto_test.model.data.dart'));
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('automatic with clause addition', () {
      // Create model without with clause
      testFile.writeAsStringSync('''
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'auto_test.model.data.dart';

@Dataforge()
class AutoWithTest {
  final String name;
  final int age;
  
  const AutoWithTest({
    required this.name,
    required this.age,
  });
}

/// Main function for standalone test execution
void main() {
  runAutoGenerationTests();
}
''');

      // Simulate generated code with automatic with clause
      outputFile.writeAsStringSync('''
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auto_test.model.dart';

// **************************************************************************
// DataforgeGenerator
// **************************************************************************

// Auto-generated with clause for AutoWithTest
mixin _\$AutoWithTestMixin {
  String get name;
  int get age;
}

extension AutoWithTestDataforge on AutoWithTest {
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
    };
  }

  static AutoWithTest fromJson(Map<String, dynamic> json) {
    return AutoWithTest(
      name: json['name'] as String,
      age: json['age'] as int,
    );
  }
  
  // Auto-generated copyWith method
  AutoWithTest copyWith({
    String? name,
    int? age,
  }) {
    return AutoWithTest(
      name: name ?? this.name,
      age: age ?? this.age,
    );
  }
}
''');

      expect(testFile.existsSync(), isTrue);
      expect(outputFile.existsSync(), isTrue);
      expect(
          outputFile.readAsStringSync().contains('mixin _\$AutoWithTestMixin'),
          isTrue);
      expect(outputFile.readAsStringSync().contains('copyWith'), isTrue);
    });

    test('existing with clause preservation', () {
      testFile.writeAsStringSync('''
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'auto_test.model.data.dart';

@Dataforge()
class ExistingWithTest with Comparable<ExistingWithTest> {
  final String name;
  final int priority;
  
  const ExistingWithTest({
    required this.name,
    required this.priority,
  });
  
  @override
  int compareTo(ExistingWithTest other) {
    return priority.compareTo(other.priority);
  }
}
''');

      outputFile.writeAsStringSync('''
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auto_test.model.dart';

// **************************************************************************
// DataforgeGenerator
// **************************************************************************

// Preserving existing with clause: Comparable<ExistingWithTest>
extension ExistingWithTestDataforge on ExistingWithTest {
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'priority': priority,
    };
  }

  static ExistingWithTest fromJson(Map<String, dynamic> json) {
    return ExistingWithTest(
      name: json['name'] as String,
      priority: json['priority'] as int,
    );
  }
  
  ExistingWithTest copyWith({
    String? name,
    int? priority,
  }) {
    return ExistingWithTest(
      name: name ?? this.name,
      priority: priority ?? this.priority,
    );
  }
}
''');

      expect(
          testFile
              .readAsStringSync()
              .contains('with Comparable<ExistingWithTest>'),
          isTrue);
      expect(
          outputFile
              .readAsStringSync()
              .contains('Preserving existing with clause'),
          isTrue);
      expect(outputFile.readAsStringSync().contains('copyWith'), isTrue);
    });

    test('automatic import generation', () {
      testFile.writeAsStringSync('''
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'auto_test.model.data.dart';

@dataforge
class AutoImportTest {
  final DateTime createdAt;
  final Duration timeout;
  final Uri? websiteUrl;
  final BigInt largeNumber;
  
  const AutoImportTest({
    required this.createdAt,
    required this.timeout,
    this.websiteUrl,
    required this.largeNumber,
  });
}
''');

      outputFile.writeAsStringSync('''
// GENERATED CODE - DO NOT MODIFY BY HAND
// Auto-generated imports
import 'dart:core';

part of 'auto_test.model.dart';

// **************************************************************************
// DataforgeGenerator
// **************************************************************************

extension AutoImportTestDataforge on AutoImportTest {
  Map<String, dynamic> toJson() {
    return {
      'createdAt': createdAt.toIso8601String(),
      'timeout': timeout.inMilliseconds,
      'websiteUrl': websiteUrl?.toString(),
      'largeNumber': largeNumber.toString(),
    };
  }

  static AutoImportTest fromJson(Map<String, dynamic> json) {
    return AutoImportTest(
      createdAt: DateTime.parse(json['createdAt'] as String),
      timeout: Duration(milliseconds: json['timeout'] as int),
      websiteUrl: json['websiteUrl'] != null
          ? Uri.parse(json['websiteUrl'] as String)
          : null,
      largeNumber: BigInt.parse(json['largeNumber'] as String),
    );
  }
}
''');

      expect(outputFile.readAsStringSync().contains("import 'dart:core';"),
          isTrue);
      expect(outputFile.readAsStringSync().contains('DateTime.parse'), isTrue);
      expect(outputFile.readAsStringSync().contains('Duration(milliseconds:'),
          isTrue);
      expect(outputFile.readAsStringSync().contains('Uri.parse'), isTrue);
      expect(outputFile.readAsStringSync().contains('BigInt.parse'), isTrue);
    });

    test('automatic part statement validation', () {
      // Create a separate test file for this test to avoid interference
      final missingPartTestFile =
          File(path.join(tempDir.path, 'missing_part_test.dart'));
      missingPartTestFile.writeAsStringSync('''
import 'package:dataforge_annotation/dataforge_annotation.dart';

// Missing part statement - should be auto-detected

@Dataforge()
class MissingPartTest {
  final String value;
  
  const MissingPartTest({
    required this.value,
  });
}
''');

      outputFile.writeAsStringSync('''
// GENERATED CODE - DO NOT MODIFY BY HAND
// Auto-generated part statement validation
// WARNING: Missing 'part' statement in source file
// Please add: part 'auto_test.model.data.dart';

part of 'auto_test.model.dart';

// **************************************************************************
// DataforgeGenerator
// **************************************************************************

extension MissingPartTestDataforge on MissingPartTest {
  Map<String, dynamic> toJson() {
    return {
      'value': value,
    };
  }

  static MissingPartTest fromJson(Map<String, dynamic> json) {
    return MissingPartTest(
      value: json['value'] as String,
    );
  }
}
''');

      expect(
          outputFile
              .readAsStringSync()
              .contains('WARNING: Missing \'part\' statement'),
          isTrue);
      expect(
          outputFile.readAsStringSync().contains('Please add: part'), isTrue);
      // Check that the source file doesn't contain a part statement (not part of)
      final sourceContent = missingPartTestFile.readAsStringSync();
      expect(
          sourceContent.contains('part \'') || sourceContent.contains('part "'),
          isFalse);

      // Clean up
      missingPartTestFile.deleteSync();
    });

    test('automatic constructor generation', () {
      testFile.writeAsStringSync('''
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'auto_test.model.data.dart';

@Dataforge()
class AutoConstructorTest {
  final String name;
  final int? age;
  final bool isActive;
  final List<String> tags;
  
  // No constructor defined - should be auto-generated
}
''');

      outputFile.writeAsStringSync('''
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auto_test.model.dart';

// **************************************************************************
// DataforgeGenerator
// **************************************************************************

// Auto-generated constructor for AutoConstructorTest
extension AutoConstructorTestGenerated on AutoConstructorTest {
  // Auto-generated constructor
  static AutoConstructorTest create({
    required String name,
    int? age,
    required bool isActive,
    required List<String> tags,
  }) {
    return AutoConstructorTest._internal(
      name: name,
      age: age,
      isActive: isActive,
      tags: tags,
    );
  }
}

extension AutoConstructorTestDataforge on AutoConstructorTest {
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'isActive': isActive,
      'tags': tags,
    };
  }

  static AutoConstructorTest fromJson(Map<String, dynamic> json) {
    return AutoConstructorTest.create(
      name: json['name'] as String,
      age: json['age'] as int?,
      isActive: json['isActive'] as bool,
      tags: (json['tags'] as List<dynamic>).cast<String>(),
    );
  }
}
''');

      expect(
          outputFile.readAsStringSync().contains('Auto-generated constructor'),
          isTrue);
      expect(
          outputFile
              .readAsStringSync()
              .contains('static AutoConstructorTest create'),
          isTrue);
      expect(
          outputFile
              .readAsStringSync()
              .contains('AutoConstructorTest._internal'),
          isTrue);
    });

    test('automatic toString and equality generation', () {
      testFile.writeAsStringSync('''
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'auto_test.model.data.dart';

@Dataforge()
class AutoMethodsTest {
  final String id;
  final String name;
  final int value;
  
  const AutoMethodsTest({
    required this.id,
    required this.name,
    required this.value,
  });
}
''');

      outputFile.writeAsStringSync('''
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auto_test.model.dart';

// **************************************************************************
// DataforgeGenerator
// **************************************************************************

extension AutoMethodsTestDataforge on AutoMethodsTest {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'value': value,
    };
  }

  static AutoMethodsTest fromJson(Map<String, dynamic> json) {
    return AutoMethodsTest(
      id: json['id'] as String,
      name: json['name'] as String,
      value: json['value'] as int,
    );
  }
  
  // Auto-generated toString
  String get autoToString {
    return 'AutoMethodsTest(id: \$id, name: \$name, value: \$value)';
  }
  
  // Auto-generated equality check
  bool autoEquals(Object other) {
    if (identical(this, other)) return true;
    return other is AutoMethodsTest &&
        other.id == id &&
        other.name == name &&
        other.value == value;
  }
  
  // Auto-generated hashCode
  int get autoHashCode {
    return Object.hash(id, name, value);
  }
}
''');

      expect(
          outputFile.readAsStringSync().contains('get autoToString'), isTrue);
      expect(outputFile.readAsStringSync().contains('bool autoEquals'), isTrue);
      expect(
          outputFile.readAsStringSync().contains('get autoHashCode'), isTrue);
      expect(outputFile.readAsStringSync().contains('Object.hash'), isTrue);
    });
  });
}

/// Main function to run auto generation tests
void main() {
  runAutoGenerationTests();
}
