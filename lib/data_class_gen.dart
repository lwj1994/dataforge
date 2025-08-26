import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:data_class_gen/src/parser.dart';
import 'package:data_class_gen/src/writer.dart';

List<String> generate(String path) {
  final generatedFiles = <String>[];
  final entity = FileSystemEntity.typeSync(path);
  final isDirectory = entity == FileSystemEntityType.directory;

  if (isDirectory) {
    final files = Directory(path).listSync(recursive: true);
    for (final element in files) {
      if (element is File && element.path.endsWith('.dart')) {
        final filePath = element.absolute.path;

        // Skip generated .data.dart files
        if (filePath.endsWith('.data.dart')) {
          continue;
        }

        // Skip certain special directories and files
        if (_shouldSkipFile(filePath)) {
          continue;
        }

        // Use default output directory from config, fallback to file directory
        final parser = Parser(filePath);
        final parseRes = parser.parseDartFile();
        if (parseRes != null) {
          final writer = Writer(parseRes);
          final generatedFile = writer.writeCode();
          if (generatedFile.isNotEmpty) {
            generatedFiles.add(generatedFile);
          }
        }
      }
    }
  } else {
    // Skip generated .data.dart files
    if (path.endsWith('.data.dart')) {
      return generatedFiles;
    }

    // Skip certain special directories and files
    if (_shouldSkipFile(path)) {
      return generatedFiles;
    }

    // Use default output directory from config, fallback to file directory
    final parser = Parser(path);
    final parseRes = parser.parseDartFile();
    if (parseRes != null) {
      final writer = Writer(parseRes);
      final generatedFile = writer.writeCode();
      if (generatedFile.isNotEmpty) {
        generatedFiles.add(generatedFile);
      }
    }
  }
  return generatedFiles;
}

/// Determine whether a file should be skipped
bool _shouldSkipFile(String filePath) {
  // Skip .dart_tool, .git, build and other directories
  if (filePath.contains('/.dart_tool/') ||
      filePath.contains('/.git/') ||
      filePath.contains('/build/') ||
      filePath.contains('/.idea/')) {
    return true;
  }

  // Skip direct files in project root directory (except files in lib/ or test/ directories)
  final relativePath = p.relative(filePath);
  final pathSegments = p.split(relativePath);

  // If file is in project root directory (no subdirectories), skip it
  if (pathSegments.length == 1) {
    print('Skipping root directory file: $filePath');
    return true;
  }

  return false;
}
