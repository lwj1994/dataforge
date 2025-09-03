import 'dart:io';
import 'package:args/args.dart';
import 'package:dataforge/dataforge.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser();

  parser.addOption("path", defaultsTo: "");
  parser.addFlag("format", defaultsTo: false, help: "Format generated code");
  parser.addFlag("debug",
      abbr: "d", defaultsTo: false, help: "Enable debug logging");
  parser.addFlag("help",
      abbr: "h", defaultsTo: false, help: "Show help information");

  final res = parser.parse(args);

  if (res.flag("help")) {
    print('DataForge - Dart data class generator\n');
    print('Usage: dataforge [path] [options]\n');
    print('Arguments:');
    print('  path              Path to generate code (default: lib and test)');
    print('Options:');
    print('  --format          Format generated code');
    print('  -d, --debug       Enable debug logging');
    print('  -h, --help        Show this help information');
    return;
  }

  // Handle positional arguments (path can be passed as first argument)
  String path = res.option("path") ?? "";
  if (path.isEmpty && res.rest.isNotEmpty) {
    path = res.rest.first;
  }
  bool shouldFormat = res.flag("format");
  bool debugMode = res.flag("debug");
  List<String> generatedFiles = [];

  if (debugMode) {
    print('[DEBUG] ${DateTime.now()}: Starting dataforge...');
    print('[DEBUG] Arguments: $args');
  }

  if (debugMode) {
    print('[DEBUG] ${DateTime.now()}: Parsed path: "$path"');
    print('[DEBUG] ${DateTime.now()}: Should format: $shouldFormat');
    print(
        '[DEBUG] ${DateTime.now()}: Current working directory: ${Directory.current.path}');
  }

  // Show loading indicator
  stdout.write('🔨 Generating code');

  if (path.isEmpty) {
    if (debugMode) {
      print(
          '\n[DEBUG] ${DateTime.now()}: Path is empty, generating for lib and test directories');
      print('[DEBUG] ${DateTime.now()}: Starting generate(\'lib\')');
    }
    final libFiles = await generate('lib', debugMode: debugMode);
    if (debugMode) {
      print(
          '[DEBUG] ${DateTime.now()}: generate(\'lib\') completed, found ${libFiles.length} files');
    }
    generatedFiles.addAll(libFiles);

    if (debugMode) {
      print('[DEBUG] ${DateTime.now()}: Starting generate(\'test\')');
    }
    final testFiles = await generate('test', debugMode: debugMode);
    if (debugMode) {
      print(
          '[DEBUG] ${DateTime.now()}: generate(\'test\') completed, found ${testFiles.length} files');
    }
    generatedFiles.addAll(testFiles);
  } else {
    if (debugMode) {
      print('\n[DEBUG] ${DateTime.now()}: Starting generate(\'$path\')');
    }
    final pathFiles = await generate(path, debugMode: debugMode);
    if (debugMode) {
      print(
          '[DEBUG] ${DateTime.now()}: generate(\'$path\') completed, found ${pathFiles.length} files');
    }
    generatedFiles.addAll(pathFiles);
  }

  if (debugMode) {
    print(
        '[DEBUG] ${DateTime.now()}: Total generated files: ${generatedFiles.length}');
    if (generatedFiles.isNotEmpty) {
      print('[DEBUG] Generated files: ${generatedFiles.join(", ")}');
    }
  }

  // Format only the files that were generated in this run
  if (generatedFiles.isNotEmpty) {
    if (shouldFormat) {
      if (debugMode) {
        print('[DEBUG] ${DateTime.now()}: Starting code formatting...');
      }
      await _formatGeneratedCode(generatedFiles, debugMode);
      if (debugMode) {
        print('[DEBUG] ${DateTime.now()}: Code formatting completed');
      }
    } else {
      print('\n✅ Generated ${generatedFiles.length} files successfully!');
    }
  } else {
    print('\n✅ No files to generate.');
  }

  if (debugMode) {
    print('[DEBUG] ${DateTime.now()}: dataforge execution completed');
  }
}

/// Automatically format generated code using dart fix and dart format
/// Only processes the files that were generated in this run
Future<void> _formatGeneratedCode(
    List<String> generatedFiles, bool debugMode) async {
  stdout.write('.');

  try {
    if (generatedFiles.isEmpty) {
      return;
    }

    // Run dart fix --apply on each generated file individually
    for (final file in generatedFiles) {
      final fixResult = await Process.run('dart', ['fix', '--apply', file]);
      if (fixResult.exitCode != 0) {
        print('Warning: Failed to apply fixes to $file');
      }
    }

    stdout.write('.');

    // Run dart format on generated files only
    final formatArgs = ['format', ...generatedFiles];
    await Process.run('dart', formatArgs);

    stdout.write('.');
    print('\n✅ Generated ${generatedFiles.length} files successfully!');
  } catch (e) {
    print('\n⚠ Warning: Failed to format generated code: $e');
  }
}
