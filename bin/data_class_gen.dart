import 'dart:io';
import 'package:args/args.dart';
import 'package:data_class_gen/data_class_gen.dart';

void main(List<String> args) async {
  print(args);
  final parser = ArgParser();

  parser.addOption("path", defaultsTo: "");
  final res = parser.parse(args);
  String path = res.option("path") ?? "";
  List<String> generatedFiles = [];
  if (path.isEmpty) {
    // By default, only process lib and test directories, avoid processing project root directory
    print('No path specified. Processing lib/ and test/ directories...');
    generatedFiles.addAll(generate('lib'));
    generatedFiles.addAll(generate('test'));
  } else {
    generatedFiles.addAll(generate(path));
  }

  // Format only the files that were generated in this run
  if (generatedFiles.isNotEmpty) {
    await _formatGeneratedCode(generatedFiles);
  }
}

/// Automatically format generated code using dart fix and dart format
/// Only processes the files that were generated in this run
Future<void> _formatGeneratedCode(List<String> generatedFiles) async {
  print('\nFormatting generated code...');

  try {
    if (generatedFiles.isEmpty) {
      print('No generated files found to format.');
      return;
    }

    print('Formatting ${generatedFiles.length} generated files...');

    // Run dart fix --apply on each generated file individually
    print('Running dart fix --apply on generated files...');
    bool fixSuccess = true;
    for (final file in generatedFiles) {
      final fixResult = await Process.run('dart', ['fix', '--apply', file]);
      if (fixResult.exitCode != 0) {
        print('⚠ dart fix failed for $file: ${fixResult.stderr}');
        fixSuccess = false;
      }
    }
    if (fixSuccess) {
      print('✓ dart fix completed successfully');
    } else {
      print('⚠ dart fix completed with some warnings');
    }

    // Run dart format on generated files only
    print('Running dart format on generated files...');
    final formatArgs = ['format', ...generatedFiles];
    final formatResult = await Process.run('dart', formatArgs);
    if (formatResult.exitCode == 0) {
      print('✓ dart format completed successfully');
    } else {
      print('⚠ dart format completed with warnings: ${formatResult.stderr}');
    }

    print('\n✅ Code generation and formatting completed!');
  } catch (e) {
    print('⚠ Warning: Failed to format generated code: $e');
    print(
        'You can manually format the generated .data.dart files using dart format.');
  }
}
