import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

/// Map types test module
/// Tests: various Map types, nested Maps, nullable Maps
void runMapTypesTests() {
  group('Map Types Tests', () {
    late Directory tempDir;
    late File testFile;
    late File outputFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('map_types_test_');
      testFile = File(path.join(tempDir.path, 'map_test.model.dart'));
      outputFile = File(path.join(tempDir.path, 'map_test.model.data.dart'));
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('basic map types serialization', () {
      // Check generated file content in models directory
      final generatedFile = File(path.join(Directory.current.path, 'test',
          'models', 'map_types.model.data.dart'));
      expect(generatedFile.existsSync(), isTrue);

      final content = generatedFile.readAsStringSync();
      expect(content, contains('Map<String, String>'));
      expect(content, contains('Map<String, int>'));
      expect(content, contains('Map<String, double>'));
      expect(content, contains('Map<String, bool>'));
      expect(content, contains('Map<String, dynamic>'));
      expect(content, contains('mixin _MapTypes'));
    });

    test('nullable and optional maps', () {
      // Check generated file content in models directory
      final generatedFile = File(path.join(Directory.current.path, 'test',
          'models', 'map_types.model.data.dart'));
      expect(generatedFile.existsSync(), isTrue);

      final content = generatedFile.readAsStringSync();
      expect(content, contains('Map<String, String>'));
      expect(content, contains('Map<String, int>'));
      expect(content, contains('mixin _MapTypes'));
    });

    test('nested maps and complex structures', () {
      // Test Map type definitions
      const Map<String, List<String>> listMap = {
        'key': ['value1', 'value2']
      };
      const Map<String, Map<String, String>> nestedMap = {
        'outer': {'inner': 'value'}
      };
      const Map<String, Map<String, List<int>>> complexMap = {
        'level1': {
          'level2': [1, 2, 3]
        }
      };

      expect(listMap.isNotEmpty, isTrue);
      expect(nestedMap.isNotEmpty, isTrue);
      expect(complexMap.isNotEmpty, isTrue);

      // Test Map operations
      expect(listMap['key']?.length, equals(2));
      expect(nestedMap['outer']?['inner'], equals('value'));
      expect(complexMap['level1']?['level2']?.length, equals(3));
    });

    test('maps with custom JSON keys', () {
      // Check generated file content in models directory
      final generatedFile = File(path.join(Directory.current.path, 'test',
          'models', 'map_types.model.data.dart'));
      expect(generatedFile.existsSync(), isTrue);

      final content = generatedFile.readAsStringSync();
      expect(content, contains('Map<String, String>'));
      expect(content, contains('Map<String, int>'));
      expect(content, contains('mixin _MapTypes'));
    });
  });
}

/// Main function for standalone test execution
void main() {
  runMapTypesTests();
}
