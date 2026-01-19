import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

/// 性能测试模块
/// 包含：文件操作性能测试
void runPerformanceTests() {
  group('Performance Tests', () {
    late Directory tempDir;
    late File testFile;
    late File outputFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('performance_test_');
      testFile = File(path.join(tempDir.path, 'test.model.dart'));
      outputFile = File(path.join(tempDir.path, 'test.model.data.dart'));
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('sync file operations performance', () {
      final stopwatch = Stopwatch()..start();

      // Create test model file
      testFile.writeAsStringSync('''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class PerformanceTest {
  final String name;
  final int age;
  final bool isActive;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  
  const PerformanceTest({
    required this.name,
    required this.age,
    required this.isActive,
    required this.tags,
    required this.metadata,
  });
}

/// Main function for standalone test execution
void main() {
  runPerformanceTests();
}
''');

      // Simulate code generation by creating output file
      outputFile.writeAsStringSync('''
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test.model.dart';

// **************************************************************************
// DataforgeGenerator
// **************************************************************************

extension PerformanceTestDataforge on PerformanceTest {
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'isActive': isActive,
      'tags': tags,
      'metadata': metadata,
    };
  }

  static PerformanceTest fromJson(Map<String, dynamic> json) {
    return PerformanceTest(
      name: json['name'] as String,
      age: json['age'] as int,
      isActive: json['isActive'] as bool,
      tags: (json['tags'] as List<dynamic>).cast<String>(),
      metadata: json['metadata'] as Map<String, dynamic>,
    );
  }

  PerformanceTest copyWith({
    String? name,
    int? age,
    bool? isActive,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return PerformanceTest(
      name: name ?? this.name,
      age: age ?? this.age,
      isActive: isActive ?? this.isActive,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'PerformanceTest(name: \$name, age: \$age, isActive: \$isActive, tags: \$tags, metadata: \$metadata)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PerformanceTest &&
        other.name == name &&
        other.age == age &&
        other.isActive == isActive &&
        _listEquals(other.tags, tags) &&
        _mapEquals(other.metadata, metadata);
  }

  @override
  int get hashCode {
    return Object.hash(
      name,
      age,
      isActive,
      Object.hashAll(tags),
      Object.hashAll(metadata.entries.map((e) => Object.hash(e.key, e.value))),
    );
  }
}

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) return false;
  }
  return true;
}

bool _mapEquals<T, U>(Map<T, U>? a, Map<T, U>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (final T key in a.keys) {
    if (!b.containsKey(key) || b[key] != a[key]) return false;
  }
  return true;
}
''');

      stopwatch.stop();
      final syncTime = stopwatch.elapsedMilliseconds;

      expect(testFile.existsSync(), isTrue);
      expect(outputFile.existsSync(), isTrue);
      expect(syncTime, lessThan(1000)); // Should complete within 1 second

      print('Sync file operations completed in ${syncTime}ms');
    });

    test('async file operations performance', () async {
      final stopwatch = Stopwatch()..start();

      // Create test model file asynchronously
      await testFile.writeAsString('''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@dataforge
class AsyncPerformanceTest {
  final String id;
  final DateTime createdAt;
  final List<int> numbers;
  
  const AsyncPerformanceTest({
    required this.id,
    required this.createdAt,
    required this.numbers,
  });
}
''');

      // Simulate async code generation
      await outputFile.writeAsString('''
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test.model.dart';

// **************************************************************************
// DataforgeGenerator
// **************************************************************************

extension AsyncPerformanceTestDataforge on AsyncPerformanceTest {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'numbers': numbers,
    };
  }

  static AsyncPerformanceTest fromJson(Map<String, dynamic> json) {
    return AsyncPerformanceTest(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      numbers: (json['numbers'] as List<dynamic>).cast<int>(),
    );
  }

  AsyncPerformanceTest copyWith({
    String? id,
    DateTime? createdAt,
    List<int>? numbers,
  }) {
    return AsyncPerformanceTest(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      numbers: numbers ?? this.numbers,
    );
  }

  @override
  String toString() {
    return 'AsyncPerformanceTest(id: \$id, createdAt: \$createdAt, numbers: \$numbers)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AsyncPerformanceTest &&
        other.id == id &&
        other.createdAt == createdAt &&
        _listEquals(other.numbers, numbers);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      createdAt,
      Object.hashAll(numbers),
    );
  }
}

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) return false;
  }
  return true;
}
''');

      stopwatch.stop();
      final asyncTime = stopwatch.elapsedMilliseconds;

      expect(await testFile.exists(), isTrue);
      expect(await outputFile.exists(), isTrue);
      expect(asyncTime, lessThan(1000)); // Should complete within 1 second

      print('Async file operations completed in ${asyncTime}ms');
    });

    test('file size and content validation', () {
      // Create a larger test file to validate performance with bigger content
      final largeContent = StringBuffer();
      largeContent.writeln(
          "import 'package:dataforge_annotation/dataforge_annotation.dart';");
      largeContent.writeln();
      largeContent.writeln('@dataforge');
      largeContent.writeln('class LargePerformanceTest {');

      // Generate many fields
      for (int i = 0; i < 50; i++) {
        largeContent.writeln('  final String field$i;');
      }

      largeContent.writeln();
      largeContent.writeln('  const LargePerformanceTest({');
      for (int i = 0; i < 50; i++) {
        largeContent.writeln('    required this.field$i,');
      }
      largeContent.writeln('  });');
      largeContent.writeln('}');

      final stopwatch = Stopwatch()..start();
      testFile.writeAsStringSync(largeContent.toString());
      stopwatch.stop();

      final fileSize = testFile.lengthSync();
      final writeTime = stopwatch.elapsedMilliseconds;

      expect(fileSize, greaterThan(1000)); // Should be a reasonably large file
      expect(writeTime, lessThan(100)); // Should write quickly
      expect(testFile.readAsStringSync().contains('field49'), isTrue);

      print('Large file ($fileSize bytes) written in ${writeTime}ms');
    });

    test('multiple file operations performance', () {
      final stopwatch = Stopwatch()..start();
      final files = <File>[];

      // Create multiple test files
      for (int i = 0; i < 10; i++) {
        final file = File(path.join(tempDir.path, 'test_$i.model.dart'));
        file.writeAsStringSync('''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@dataforge
class TestModel$i {
  final String name$i;
  final int value$i;
  
  const TestModel$i({
    required this.name$i,
    required this.value$i,
  });
}
''');
        files.add(file);
      }

      stopwatch.stop();
      final multiFileTime = stopwatch.elapsedMilliseconds;

      expect(files.length, equals(10));
      expect(files.every((f) => f.existsSync()), isTrue);
      expect(multiFileTime, lessThan(500)); // Should complete within 500ms

      print(
          'Multiple file operations (${files.length} files) completed in ${multiFileTime}ms');
    });
  });
}

/// Main function for standalone test execution
void main() {
  runPerformanceTests();
}
