import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:dataforge_cli/src/exceptions.dart';
import 'package:dataforge_cli/src/v1_pipeline.dart';

export 'package:dataforge_cli/src/exceptions.dart';

/// Generates or checks Dataforge v1 output for a Dart source or directory.
///
/// Generation never edits source files. Directory invocations include nested
/// Dart packages while excluding tool-owned output directories.
Future<List<String>> generate(
  String path, {
  bool debugMode = false,
  bool check = false,
}) async {
  final startedAt = DateTime.now();
  final absolutePath = p.normalize(p.absolute(path));
  if (debugMode) {
    print('[DEBUG] $startedAt: generate() path=$absolutePath check=$check');
  }

  final FileSystemEntityType entityType;
  try {
    entityType = await FileSystemEntity.type(absolutePath, followLinks: false);
  } on FileSystemException catch (error) {
    throw DataforgeIoException(
      'Could not inspect generation path $absolutePath: $error',
      cause: error,
    );
  }
  if (entityType == FileSystemEntityType.notFound) {
    throw DataforgeInputException('Path does not exist: $absolutePath');
  }
  if (entityType == FileSystemEntityType.link) {
    throw DataforgeInputException(
      'Dataforge does not accept a symbolic link as the generation path: '
      '$absolutePath',
    );
  }

  final isDirectory = entityType == FileSystemEntityType.directory;
  if (!isDirectory && entityType != FileSystemEntityType.file) {
    throw DataforgeInputException(
      'Dataforge only accepts regular Dart source files or directories: $path',
    );
  }
  if (!isDirectory &&
      (!absolutePath.endsWith('.dart') ||
          absolutePath.endsWith('.data.dart'))) {
    throw DataforgeInputException(
      'Dataforge only accepts non-generated Dart source files: $path',
    );
  }

  final projectRoot = _inferProjectRoot(absolutePath, entityType);
  final candidateFiles = isDirectory
      ? _scanDirectory(absolutePath, debugMode: debugMode)
      : <String>[absolutePath];
  final preparation = await const V1CliPipeline().prepare(
    candidateFiles: candidateFiles,
    projectRoot: projectRoot,
    check: check,
    orphanScanRoot: isDirectory ? absolutePath : null,
  );
  await preparation.finish(check: check);

  if (debugMode) {
    final elapsed = DateTime.now().difference(startedAt).inMilliseconds;
    print(
      '[DEBUG] ${DateTime.now()}: generate() completed with '
      '${preparation.outputPaths.length} output(s) in ${elapsed}ms',
    );
  }
  return preparation.outputPaths;
}

/// Recursively scans Dart sources without imposing a package-depth limit.
List<String> _scanDirectory(String path, {required bool debugMode}) {
  final dartFiles = <String>[];
  final startedAt = DateTime.now();

  void scan(String directoryPath) {
    try {
      final parentIsPackageRoot = File(
        p.join(directoryPath, 'pubspec.yaml'),
      ).existsSync();
      final entities = Directory(directoryPath).listSync(followLinks: false);
      for (final entity in entities) {
        if (entity is Directory) {
          final name = p.basename(entity.path);
          if (_shouldSkipDirectory(
            name,
            parentIsPackageRoot: parentIsPackageRoot,
          )) {
            if (debugMode) {
              print('[DEBUG] ${DateTime.now()}: skip ${entity.path}');
            }
            continue;
          }
          scan(entity.path);
          continue;
        }
        if (entity is! File ||
            !entity.path.endsWith('.dart') ||
            entity.path.endsWith('.data.dart')) {
          continue;
        }
        dartFiles.add(p.normalize(entity.absolute.path));
      }
    } on FileSystemException catch (error) {
      throw DataforgeIoException(
        'Could not scan directory $directoryPath: $error',
        cause: error,
      );
    }
  }

  scan(path);
  dartFiles.sort();
  if (debugMode) {
    final elapsed = DateTime.now().difference(startedAt).inMilliseconds;
    print(
      '[DEBUG] ${DateTime.now()}: scanned ${dartFiles.length} Dart source '
      'file(s) in ${elapsed}ms',
    );
  }
  return dartFiles;
}

bool _shouldSkipDirectory(String name, {required bool parentIsPackageRoot}) {
  const toolingDirectories = {
    '.dart_tool',
    '.git',
    '.hg',
    '.svn',
    '.idea',
    '.vscode',
    '.pub-cache',
    'node_modules',
    '.packages',
    '.flutter-plugins',
    '.flutter-plugins-dependencies',
  };
  if (toolingDirectories.contains(name)) return true;
  return parentIsPackageRoot && (name == 'build' || name == 'coverage');
}

String _inferProjectRoot(String absolutePath, FileSystemEntityType entityType) {
  final startDirectory = entityType == FileSystemEntityType.directory
      ? absolutePath
      : p.dirname(absolutePath);

  var current = startDirectory;
  while (true) {
    if (File(p.join(current, 'pubspec.yaml')).existsSync()) return current;
    final parent = p.dirname(current);
    if (parent == current) break;
    current = parent;
  }
  return startDirectory;
}
