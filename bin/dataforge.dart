import 'dart:io';
import 'package:args/args.dart';
import 'package:dataforge/dataforge.dart';

void main(List<String> args) async {
  final parser = ArgParser();

  parser.addOption("path", defaultsTo: "");
  final res = parser.parse(args);
  String path = res.option("path") ?? "";
  List<String> generatedFiles = [];

  // Show loading indicator
  stdout.write('🔨 Generating code');

  if (path.isEmpty) {
    generatedFiles.addAll(generate('lib'));
    generatedFiles.addAll(generate('test'));
  } else {
    generatedFiles.addAll(generate(path));
  }

  // Format only the files that were generated in this run
  if (generatedFiles.isNotEmpty) {
    await _formatGeneratedCode(generatedFiles);
  } else {
    print('\n✅ No files to generate.');
  }
}

/// Automatically format generated code using dart fix and dart format
/// Only processes the files that were generated in this run
Future<void> _formatGeneratedCode(List<String> generatedFiles) async {
  stdout.write('.');

  try {
    if (generatedFiles.isEmpty) {
      return;
    }

    // Run dart fix --apply on each generated file individually
    bool fixSuccess = true;
    for (final file in generatedFiles) {
      final fixResult = await Process.run('dart', ['fix', '--apply', file]);
      if (fixResult.exitCode != 0) {
        fixSuccess = false;
      }
    }

    stdout.write('.');

    // Run dart format on generated files only
    final formatArgs = ['format', ...generatedFiles];
    final formatResult = await Process.run('dart', formatArgs);

    stdout.write('.');
    print('\n✅ Generated ${generatedFiles.length} files successfully!');
  } catch (e) {
    print('\n⚠ Warning: Failed to format generated code: $e');
  }
}
