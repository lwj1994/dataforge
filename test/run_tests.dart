#!/usr/bin/env dart

import 'dart:io';
import 'package:dataforge/dataforge.dart';

/// Test runner script
///
/// Executes complete test workflow:
/// 1. Clean old generated files
/// 2. Run code generation
/// 3. Format code
/// 4. Run tests
void main(List<String> args) async {
  print('🚀 Starting Data Class Generator Test Suite...');

  try {
    // 1. Clean old generated files
    print('\n📁 Cleaning old generated files...');
    await _cleanGeneratedFiles();

    // 2. Run code generation
    print('\n⚡ Running code generation...');
    generate('test/models');

    // 3. Format code
    print('\n🎨 Formatting generated code...');
    await _formatCode();

    // 4. Run tests
    print('\n🧪 Running tests...');
    await _runTests();

    print('\n✅ All tests completed successfully!');
  } catch (e) {
    print('\n❌ Test failed: $e');
    exit(1);
  }
}

/// Clean old generated files
Future<void> _cleanGeneratedFiles() async {
  final modelsDir = Directory('test/models');
  if (!modelsDir.existsSync()) return;

  final generatedFiles = modelsDir
      .listSync()
      .where((file) => file.path.endsWith('.data.dart'))
      .cast<File>();

  for (final file in generatedFiles) {
    file.deleteSync();
    print('  Deleted: ${file.path}');
  }
}

/// Format code
Future<void> _formatCode() async {
  // Run dart fix
  print('  Running dart fix...');
  final fixResult = await Process.run('dart', ['fix', '--apply']);
  if (fixResult.exitCode != 0) {
    throw Exception('dart fix failed: ${fixResult.stderr}');
  }

  // Run dart format
  print('  Running dart format...');
  final formatResult = await Process.run('dart', ['format', 'test/models']);
  if (formatResult.exitCode != 0) {
    throw Exception('dart format failed: ${formatResult.stderr}');
  }

  print('  ✓ Code formatted successfully');
}

/// Run tests
Future<void> _runTests() async {
  final testResult = await Process.run(
      'dart', ['test', 'test/data_class_generator_test.dart']);

  print(testResult.stdout);
  if (testResult.stderr.isNotEmpty) {
    print('Test stderr: ${testResult.stderr}');
  }

  if (testResult.exitCode != 0) {
    throw Exception('Tests failed with exit code: ${testResult.exitCode}');
  }

  print('  ✓ All tests passed');
}
