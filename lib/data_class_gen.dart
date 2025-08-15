import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:data_class_gen/src/parser.dart';
import 'package:data_class_gen/src/writer.dart';

void generate(String path) {
  final entity = FileSystemEntity.typeSync(path);
  final isDirectory = entity == FileSystemEntityType.directory;

  if (isDirectory) {
    Directory(path).listSync(recursive: true).forEach((element) {
      if (element is File && element.path.endsWith('.dart')) {
        final filePath = element.absolute.path;

        // Skip generated .data.dart files
        if (filePath.endsWith('.data.dart')) {
          return;
        }

        // Skip certain special directories and files
        if (_shouldSkipFile(filePath)) {
          return;
        }

        // Get the directory containing the file as output directory
        final outputDir = p.dirname(filePath);
        final parser = Parser(filePath, outputDirectory: outputDir);
        final parseRes = parser.parseDartFile();
        if (parseRes != null) {
          final writer = Writer(parseRes);
          writer.writeCode();
        }
      }
    });
  } else {
    // Skip generated .data.dart files
    if (path.endsWith('.data.dart')) {
      return;
    }

    // Skip certain special directories and files
    if (_shouldSkipFile(path)) {
      return;
    }

    // Get the directory containing the file as output directory
    final outputDir = p.dirname(path);
    final parser = Parser(path, outputDirectory: outputDir);
    final parseRes = parser.parseDartFile();
    if (parseRes != null) {
      final writer = Writer(parseRes);
      writer.writeCode();
    }
  }
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
