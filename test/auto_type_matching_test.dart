import 'package:test/test.dart';
import 'dart:io';
import 'package:dataforge/dataforge.dart';

void main() {
  group('Auto Type Matching Tests', () {
    late Directory tempDir;
    late File testFile;
    late File outputFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('auto_type_matching_test');
      testFile = File('${tempDir.path}/test_model.dart');
      outputFile = File('${tempDir.path}/test_model.data.dart');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('should auto-match DateTime converter', () async {
      // Create test model with DateTime field (no explicit converter)
      testFile.writeAsStringSync('''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@dataforge
class AutoDateTimeTest {
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  const AutoDateTimeTest({
    required this.createdAt,
    this.updatedAt,
  });
}
''');

      // Generate code
      generate(tempDir.path);

      // Check if output file was created
      expect(outputFile.existsSync(), isTrue);

      // Read generated content
      final content = outputFile.readAsStringSync();

      // Should contain DateTimeConverter usage
      expect(content, contains('DateTimeConverter'));
      expect(content, contains('const DateTimeConverter().fromJson'));
      expect(content, contains('const DateTimeConverter().toJson'));
    });

    test('should auto-match Duration converter', () async {
      // Create test model with Duration field (no explicit converter)
      testFile.writeAsStringSync('''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@dataforge
class AutoDurationTest {
  final Duration timeout;
  final Duration? delay;
  
  const AutoDurationTest({
    required this.timeout,
    this.delay,
  });
}
''');

      // Generate code
      generate(tempDir.path);

      // Check if output file was created
      expect(outputFile.existsSync(), isTrue);

      // Read generated content
      final content = outputFile.readAsStringSync();

      // Should contain DurationConverter usage
      expect(content, contains('DurationConverter'));
      expect(content, contains('const DurationConverter().fromJson'));
      expect(content, contains('const DurationConverter().toJson'));
    });

    test('should auto-match enum converter', () async {
      // Create test model with enum field (no explicit converter)
      testFile.writeAsStringSync('''
import 'package:dataforge_annotation/dataforge_annotation.dart';

enum Priority { low, medium, high }

@dataforge
class AutoEnumTest {
  final Priority priority;
  final Priority? secondaryPriority;
  
  const AutoEnumTest({
    required this.priority,
    this.secondaryPriority,
  });
}
''');

      // Generate code
      generate(tempDir.path);

      // Check if output file was created
      expect(outputFile.existsSync(), isTrue);

      // Read generated content
      final content = outputFile.readAsStringSync();

      // Should contain EnumConverter usage
      expect(content, contains('EnumConverter(Priority.values)'));
      expect(
          content, contains('const EnumConverter(Priority.values).fromJson'));
      expect(content, contains('const EnumConverter(Priority.values).toJson'));
    });

    test('should not auto-match for basic types', () async {
      // Create test model with basic types (should not use converters)
      testFile.writeAsStringSync('''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@dataforge
class BasicTypesTest {
  final String name;
  final int count;
  final double price;
  final bool enabled;
  
  const BasicTypesTest({
    required this.name,
    required this.count,
    required this.price,
    required this.enabled,
  });
}
''');

      // Generate code
      generate(tempDir.path);

      // Check if output file was created
      expect(outputFile.existsSync(), isTrue);

      // Read generated content
      final content = outputFile.readAsStringSync();

      // Should NOT contain any converter usage for basic types
      expect(content, isNot(contains('Converter().fromJson')));
      expect(content, isNot(contains('Converter().toJson')));
    });

    test('should prefer explicit converter over auto-matching', () async {
      // Create test model with explicit converter that overrides auto-matching
      testFile.writeAsStringSync('''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@dataforge
class ExplicitConverterTest {
  @JsonKey(converter: DateTimeMillisecondsConverter())
  final DateTime createdAt;
  
  const ExplicitConverterTest({
    required this.createdAt,
  });
}
''');

      // Generate code
      generate(tempDir.path);

      // Check if output file was created
      expect(outputFile.existsSync(), isTrue);

      // Read generated content
      final content = outputFile.readAsStringSync();

      // Should use explicit DateTimeMillisecondsConverter, not auto-matched DateTimeConverter
      expect(content, contains('DateTimeMillisecondsConverter'));
      expect(content, isNot(contains('DateTimeConverter')));
    });
  });
}
