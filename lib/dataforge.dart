import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as p;

import 'package:dataforge/src/parser.dart';
import 'package:dataforge/src/writer.dart';

Future<List<String>> generate(String path, {bool debugMode = false}) async {
  final startTime = DateTime.now();
  if (debugMode) {
    print('[DEBUG] $startTime: generate() called with path: "$path"');
    print(
        '[DEBUG] ${DateTime.now()}: Current working directory: ${Directory.current.path}');
  }

  // Convert relative path to absolute path to ensure consistent behavior
  // regardless of the working directory from which the command is run
  final absolutePath =
      p.isAbsolute(path) ? path : p.join(Directory.current.path, path);
  if (debugMode) {
    print('[DEBUG] ${DateTime.now()}: Resolved absolute path: "$absolutePath"');
  }

  final generatedFiles = <String>[];
  final entity = FileSystemEntity.typeSync(absolutePath);
  final isDirectory = entity == FileSystemEntityType.directory;
  if (debugMode) {
    print('[DEBUG] ${DateTime.now()}: Path is directory: $isDirectory');
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
        candidateFiles, absolutePath, maxConcurrency, debugMode);

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
    if (_shouldSkipFile(absolutePath,
        basePath:
            absolutePath.contains('/') ? p.dirname(absolutePath) : null)) {
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

    if (debugMode) {
      final parseTime = parseEndTime.difference(parseStartTime).inMilliseconds;
      print(
          '[DEBUG] ${DateTime.now()}: parseDartFile() completed for single file: $absolutePath, result: ${parseRes != null ? 'success' : 'null'}, time: ${parseTime}ms');
    }

    if (parseRes != null) {
      if (debugMode) {
        print(
            '[DEBUG] ${DateTime.now()}: Creating writer for single file: $absolutePath');
      }
      final writeStartTime = DateTime.now();
      final writer = Writer(parseRes,
          projectRoot: p.dirname(absolutePath), debugMode: debugMode);
      if (debugMode) {
        print(
            '[DEBUG] ${DateTime.now()}: Starting writeCode() for single file: $absolutePath');
      }
      final generatedFile = writer.writeCode();
      final writeEndTime = DateTime.now();

      if (debugMode) {
        final writeTime =
            writeEndTime.difference(writeStartTime).inMilliseconds;
        print(
            '[DEBUG] ${DateTime.now()}: writeCode() completed for single file: $absolutePath, generated: ${generatedFile.isNotEmpty ? generatedFile : 'empty'}, time: ${writeTime}ms');
      }

      if (generatedFile.isNotEmpty) {
        generatedFiles.add(generatedFile);
      }
    }
  }
  final endTime = DateTime.now();
  final totalTime = endTime.difference(startTime).inMilliseconds;

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
          if (_shouldSkipFile(filePath, basePath: path)) {
            continue;
          }

          dartFiles.add(filePath);
        }
      }
    } catch (e) {
      if (debugMode) {
        print(
            '[DEBUG] ${DateTime.now()}: Error scanning directory $currentPath: $e');
      }
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

/// Quick pre-filter to check if file contains Dataforge annotations
bool _hasDataforgeAnnotations(String filePath) {
  try {
    final file = File(filePath);
    if (!file.existsSync()) return false;

    // Read file content efficiently
    final content = file.readAsStringSync();

    // Quick string search for annotations - support both @Dataforge and @Dataforge()
    return content.contains('@Dataforge') ||
        content.contains('@dataforge') ||
        content.contains('@DataClass') ||
        content.contains('dataforge_annotation');
  } catch (e) {
    // If we can't read the file, skip it
    return false;
  }
}

/// Determine whether a file should be skipped
bool _shouldSkipFile(String filePath, {String? basePath}) {
  // Skip files in excluded directories (this is a backup check)
  if (filePath.contains('/.dart_tool/') ||
      filePath.contains('/.git/') ||
      filePath.contains('/build/') ||
      filePath.contains('/.idea/') ||
      filePath.contains('/.pub-cache/') ||
      filePath.contains('/node_modules/')) {
    return true;
  }
  return false;
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
    final batchFutures =
        batch.map((filePath) => _processFile(filePath, projectRoot, debugMode));
    final batchResults = await Future.wait(batchFutures);

    results.addAll(batchResults);

    final batchEndTime = DateTime.now();
    final batchTime = batchEndTime.difference(batchStartTime).inMilliseconds;

    if (debugMode) {
      final successCount = batchResults.where((r) => r.isNotEmpty).length;
      print(
          '[DEBUG] ${DateTime.now()}: Batch ${batchIndex + 1} completed in ${batchTime}ms ($successCount/${batch.length} successful)');
    }
  }

  return results;
}

/// Process a single file and return the generated file path
Future<String> _processFile(
    String filePath, String projectRoot, bool debugMode) async {
  try {
    final fileStartTime = DateTime.now();

    if (debugMode) {
      print(
          '[DEBUG] ${DateTime.now()}: Processing file: ${p.basename(filePath)}');
    }

    // Parse the file
    final parseStartTime = DateTime.now();
    final parser = Parser(filePath);
    final parseRes = parser.parseDartFile();
    final parseEndTime = DateTime.now();

    if (parseRes == null) {
      if (debugMode) {
        final parseTime =
            parseEndTime.difference(parseStartTime).inMilliseconds;
        print(
            '[DEBUG] ${DateTime.now()}: Parse failed for ${p.basename(filePath)} in ${parseTime}ms');
      }
      return '';
    }

    // Generate code
    final writeStartTime = DateTime.now();
    final writer =
        Writer(parseRes, projectRoot: projectRoot, debugMode: debugMode);
    final generatedFile = writer.writeCode();
    final writeEndTime = DateTime.now();

    final fileEndTime = DateTime.now();

    if (debugMode) {
      final parseTime = parseEndTime.difference(parseStartTime).inMilliseconds;
      final writeTime = writeEndTime.difference(writeStartTime).inMilliseconds;
      final totalTime = fileEndTime.difference(fileStartTime).inMilliseconds;
      print(
          '[DEBUG] ${DateTime.now()}: File ${p.basename(filePath)} completed in ${totalTime}ms (parse:${parseTime}ms, write:${writeTime}ms)');
    }

    return generatedFile;
  } catch (e) {
    if (debugMode) {
      print(
          '[DEBUG] ${DateTime.now()}: Error processing ${p.basename(filePath)}: $e');
    }
    return '';
  }
}
