import 'dart:io';
import 'dart:async';
import 'package:dataforge_base/src/logger.dart';
import 'package:path/path.dart' as p;

import 'package:dataforge_cli/src/parser.dart';
import 'package:dataforge_cli/src/cli_writer.dart';

Future<List<String>> generate(String path, {bool debugMode = false}) async {
  final startTime = DateTime.now();
  if (debugMode) {
    print('[DEBUG] $startTime: generate() called with path: "$path"');
    print(
        '[DEBUG] ${DateTime.now()}: Current working directory: ${Directory.current.path}');
  }

  // Convert relative path to absolute path to ensure consistent behavior
  // regardless of the working directory from which the command is run
  final absolutePath = p.normalize(p.absolute(path));
  if (debugMode) {
    print('[DEBUG] ${DateTime.now()}: Resolved absolute path: "$absolutePath"');
  }

  final generatedFiles = <String>[];
  final entity = FileSystemEntity.typeSync(absolutePath);
  if (entity == FileSystemEntityType.notFound) {
    throw FileSystemException('Path does not exist', absolutePath);
  }

  final isDirectory = entity == FileSystemEntityType.directory;
  final projectRoot = _inferProjectRoot(absolutePath, entity);
  if (debugMode) {
    print('[DEBUG] ${DateTime.now()}: Path is directory: $isDirectory');
    print('[DEBUG] ${DateTime.now()}: Inferred project root: $projectRoot');
  }

  if (isDirectory) {
    if (debugMode) {
      print(
          '[DEBUG] ${DateTime.now()}: Starting directory scan for: $absolutePath');
    }

    // Optimized file scanning with depth limit and better filtering
    final files =
        _scanDirectory(absolutePath, maxDepth: 10, debugMode: debugMode);
    if (debugMode) {
      print(
          '[DEBUG] ${DateTime.now()}: Found ${files.length} dart files after filtering');
    }

    // Pre-filter files to find those with Dataforge annotations
    final parallelStartTime = DateTime.now();
    if (debugMode) {
      print('[PERF] $parallelStartTime: Starting parallel file processing');
    }

    final candidateFiles = <String>[];
    int preFilteredCount = 0;

    for (final filePath in files) {
      if (_hasDataforgeAnnotations(filePath)) {
        candidateFiles.add(filePath);
      } else {
        preFilteredCount++;
        if (debugMode) {
          print(
              '[DEBUG] ${DateTime.now()}: Skipping file without @Dataforge annotations: $filePath');
        }
      }
    }

    if (debugMode) {
      print(
          '[DEBUG] ${DateTime.now()}: Pre-filtering completed. Total files: ${files.length}, Candidates: ${candidateFiles.length}, Skipped: $preFilteredCount');
    }

    if (candidateFiles.isEmpty) {
      if (debugMode) {
        print('No files with @Dataforge annotations found. in $absolutePath');
      }
      return generatedFiles;
    }

    // Process files in parallel with controlled concurrency
    final maxConcurrency = Platform.numberOfProcessors;
    final processedResults = await _processFilesInParallel(
      candidateFiles,
      projectRoot,
      maxConcurrency,
      debugMode,
    );

    // Collect results
    int processedCount = 0;
    for (final result in processedResults) {
      if (result.isNotEmpty) {
        generatedFiles.add(result);
        processedCount++;
      }
    }

    final parallelEndTime = DateTime.now();
    final parallelTime =
        parallelEndTime.difference(parallelStartTime).inMilliseconds;
    if (debugMode) {
      print(
          '[PERF] $parallelEndTime: Parallel processing completed in ${parallelTime}ms (concurrency: $maxConcurrency)');
    }
    if (debugMode) {
      print(
          '[DEBUG] ${DateTime.now()}: Directory scan completed. Total files: ${files.length}, Pre-filtered: $preFilteredCount, Processed: $processedCount, Generated: ${generatedFiles.length}');
    }
  } else {
    if (debugMode) {
      print('[DEBUG] ${DateTime.now()}: Processing single file: $absolutePath');
    }

    // Skip generated .data.dart files
    if (absolutePath.endsWith('.data.dart')) {
      if (debugMode) {
        print(
            '[DEBUG] ${DateTime.now()}: Skipping .data.dart file: $absolutePath');
      }
      return generatedFiles;
    }

    // Skip certain special directories and files
    if (_shouldSkipFile(absolutePath)) {
      if (debugMode) {
        print(
            '[DEBUG] ${DateTime.now()}: Skipping file due to filter: $absolutePath');
      }
      return generatedFiles;
    }

    // Pre-filter: Quick content scan for annotations
    if (!_hasDataforgeAnnotations(absolutePath)) {
      if (debugMode) {
        print(
            '[DEBUG] ${DateTime.now()}: Skipping file without @Dataforge annotations: $absolutePath');
      }
      return generatedFiles;
    }

    if (debugMode) {
      print(
          '[DEBUG] ${DateTime.now()}: Creating parser for single file: $absolutePath');
    }

    final parseStartTime = DateTime.now();
    final parser = Parser(absolutePath);
    if (debugMode) {
      print(
          '[DEBUG] ${DateTime.now()}: Starting parseDartFile() for single file: $absolutePath');
    }
    final parseRes = parser.parseDartFile();
    final parseEndTime = DateTime.now();

    final parseTime = parseEndTime.difference(parseStartTime).inMilliseconds;
    if (parseRes == null) {
      DataforgeLogger.warning('Failed to parse Dataforge file: $absolutePath');
      return generatedFiles;
    }

    if (debugMode) {
      print(
          '[DEBUG] ${DateTime.now()}: parseDartFile() completed for single file: $absolutePath, result: success, time: ${parseTime}ms');
    }

    final writeStartTime = DateTime.now();
    final writer = CliWriter(
      parseRes,
      projectRoot: projectRoot,
      debugMode: debugMode,
    );
    final generatedFile = await writer.writeCodeAsync();
    final writeEndTime = DateTime.now();

    final writeTime = writeEndTime.difference(writeStartTime).inMilliseconds;
    final totalTime = writeTime + parseTime;
    print(
        '✅ Generated ${p.relative(generatedFile, from: projectRoot)} in ${totalTime}ms (parse: ${parseTime}ms, write: ${writeTime}ms)');

    if (generatedFile.isNotEmpty) {
      generatedFiles.add(generatedFile);
    }
  }
  final endTime = DateTime.now();
  final totalTime = endTime.difference(startTime).inMilliseconds;

  // Clear the type cache so it doesn't outlive this invocation
  CliWriter.clearCache();

  if (debugMode) {
    print(
        '[DEBUG] $endTime: generate() completed for path: "$absolutePath", total generated files: ${generatedFiles.length}, total time: ${totalTime}ms');
  } else if (generatedFiles.isNotEmpty) {
    print('✅ Generated ${generatedFiles.length} files in ${totalTime}ms');
  }

  return generatedFiles;
}

/// Optimized directory scanning with depth limit and better filtering
List<String> _scanDirectory(String path,
    {int maxDepth = 10, bool debugMode = false}) {
  final dartFiles = <String>[];
  final startTime = DateTime.now();

  void scanRecursive(String currentPath, int currentDepth) {
    if (currentDepth > maxDepth) return;

    try {
      final dir = Directory(currentPath);
      if (!dir.existsSync()) return;

      final entities = dir.listSync();
      for (final entity in entities) {
        if (entity is Directory) {
          final dirName = p.basename(entity.path);
          // Skip common directories that don't contain source code
          if (_shouldSkipDirectory(dirName)) {
            if (debugMode) {
              print(
                  '[DEBUG] ${DateTime.now()}: Skipping directory: ${entity.path}');
            }
            continue;
          }
          scanRecursive(entity.path, currentDepth + 1);
        } else if (entity is File && entity.path.endsWith('.dart')) {
          final filePath = entity.absolute.path;

          // Skip generated .data.dart files
          if (filePath.endsWith('.data.dart')) {
            continue;
          }

          // Skip certain special files
          if (_shouldSkipFile(filePath)) {
            continue;
          }

          dartFiles.add(filePath);
        }
      }
    } catch (e) {
      DataforgeLogger.warning('Could not scan directory $currentPath: $e');
    }
  }

  scanRecursive(path, 0);

  if (debugMode) {
    final scanTime = DateTime.now().difference(startTime).inMilliseconds;
    print(
        '[DEBUG] ${DateTime.now()}: Directory scan completed in ${scanTime}ms, found ${dartFiles.length} dart files');
  }

  return dartFiles;
}

/// Check if directory should be skipped
bool _shouldSkipDirectory(String dirName) {
  const skipDirs = {
    '.dart_tool',
    '.git',
    '.idea',
    '.vscode',
    'build',
    '.pub-cache',
    'node_modules',
    '.packages',
    'coverage',
    'doc',
    'docs',
    '.flutter-plugins',
    '.flutter-plugins-dependencies',
    'ios',
    'android',
    'web',
    'windows',
    'macos',
    'linux',
  };
  return skipDirs.contains(dirName);
}

final _dataforgeAnnotationPattern = RegExp(
  r'@\w+\.(?:Dataforge|dataforge|DataClass|dataClass)\b|@(?:Dataforge|dataforge|DataClass|dataClass)\b',
);

/// Quick pre-filter to check if file contains Dataforge annotations
bool _hasDataforgeAnnotations(String filePath) {
  try {
    final content = File(filePath).readAsStringSync();
    return _dataforgeAnnotationPattern.hasMatch(content);
  } catch (e) {
    DataforgeLogger.warning('Could not read file $filePath: $e');
    return false;
  }
}

String _inferProjectRoot(String absolutePath, FileSystemEntityType entity) {
  final startDir = entity == FileSystemEntityType.directory
      ? absolutePath
      : p.dirname(absolutePath);

  String current = startDir;
  while (true) {
    if (File(p.join(current, 'pubspec.yaml')).existsSync()) {
      return current;
    }

    final parent = p.dirname(current);
    if (parent == current) {
      break;
    }
    current = parent;
  }

  current = startDir;
  while (true) {
    final parent = p.dirname(current);
    if (parent == current) {
      break;
    }

    final baseName = p.basename(current);
    if (baseName == 'lib' || baseName == 'test') {
      return parent;
    }
    current = parent;
  }

  return startDir;
}

/// Determine whether a file should be skipped based on its path segments.
///
/// Note: 'build' is only skipped as a top-level directory (via [_shouldSkipDirectory])
/// to avoid false positives on user directories like `lib/build_config/`.
bool _shouldSkipFile(String filePath) {
  const skipDirs = {
    '.dart_tool',
    '.git',
    '.idea',
    '.pub-cache',
    'node_modules',
  };
  final segments = p.split(p.normalize(filePath));
  return segments.any(skipDirs.contains);
}

/// Process files in parallel with controlled concurrency
/// Returns a list of generated file paths
Future<List<String>> _processFilesInParallel(
  List<String> filePaths,
  String projectRoot,
  int maxConcurrency,
  bool debugMode,
) async {
  final results = <String>[];

  // Split files into batches for controlled concurrency
  final batches = <List<String>>[];
  for (int i = 0; i < filePaths.length; i += maxConcurrency) {
    final end = (i + maxConcurrency < filePaths.length)
        ? i + maxConcurrency
        : filePaths.length;
    batches.add(filePaths.sublist(i, end));
  }

  if (debugMode) {
    print(
        '[DEBUG] ${DateTime.now()}: Processing ${filePaths.length} files in ${batches.length} batches (max concurrency: $maxConcurrency)');
  }

  // Process each batch in parallel
  for (int batchIndex = 0; batchIndex < batches.length; batchIndex++) {
    final batch = batches[batchIndex];
    final batchStartTime = DateTime.now();

    if (debugMode) {
      print(
          '[DEBUG] ${DateTime.now()}: Processing batch ${batchIndex + 1}/${batches.length} with ${batch.length} files');
    }

    // Process files in current batch concurrently
    final batchResults = await Future.wait(
      batch.map((filePath) => _processFile(filePath, projectRoot, debugMode)),
    );

    int batchSuccessCount = 0;
    for (final result in batchResults) {
      if (result.isNotEmpty) {
        results.add(result);
        batchSuccessCount++;
      }
    }

    final batchEndTime = DateTime.now();
    final batchTime = batchEndTime.difference(batchStartTime).inMilliseconds;

    if (debugMode) {
      print(
          '[DEBUG] ${DateTime.now()}: Batch ${batchIndex + 1} completed in ${batchTime}ms ($batchSuccessCount/${batch.length} successful)');
    }
  }

  return results;
}

/// Process a single file and return the generated file path.
/// Returns empty string on failure so batch processing can continue.
Future<String> _processFile(
    String filePath, String projectRoot, bool debugMode) async {
  try {
    final fileStartTime = DateTime.now();

    if (debugMode) {
      print(
          '[DEBUG] ${DateTime.now()}: Processing file: ${p.basename(filePath)}');
    }

    final parseStartTime = DateTime.now();
    final parser = Parser(filePath);
    final parseRes = parser.parseDartFile();
    final parseEndTime = DateTime.now();

    final parseTime = parseEndTime.difference(parseStartTime).inMilliseconds;
    if (parseRes == null) {
      DataforgeLogger.warning(
          'Failed to parse Dataforge file: ${p.basename(filePath)}');
      return '';
    }

    final writeStartTime = DateTime.now();
    final writer =
        CliWriter(parseRes, projectRoot: projectRoot, debugMode: debugMode);
    final generatedFile = await writer.writeCodeAsync();
    final writeEndTime = DateTime.now();

    final fileEndTime = DateTime.now();

    final writeTime = writeEndTime.difference(writeStartTime).inMilliseconds;
    final totalTime = fileEndTime.difference(fileStartTime).inMilliseconds;
    print(
        '✅ Generated ${p.relative(generatedFile, from: projectRoot)} in ${totalTime}ms (parse: ${parseTime}ms, write: ${writeTime}ms)');

    return generatedFile;
  } catch (e) {
    DataforgeLogger.error(
        'Error processing ${p.basename(filePath)}: $e');
    return '';
  }
}
