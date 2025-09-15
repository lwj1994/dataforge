import 'dart:io';

import 'model.dart';
import 'parser.dart';

/// Import resolver for handling cross-file class discovery
/// Provides functionality to search for classes and enums in imported files
class ImportResolver {
  final ParseResult result;
  final String? projectRoot;
  final bool debugMode;

  ImportResolver({
    required this.result,
    this.projectRoot,
    this.debugMode = false,
  });

  /// Search for ClassInfo in imported files
  /// Returns ClassInfo if found a class with @Dataforge annotation, null otherwise
  ClassInfo? findClassInfoInImports(String typeName) {
    if (debugMode) {
      print('[DEBUG] Searching for class $typeName in imported files');
    }

    for (final import in result.imports) {
      // Skip dart: core library imports
      if (import.uri.startsWith('dart:')) {
        continue;
      }

      final classInfo = _parseImportedFileForClass(import.uri, typeName);
      if (classInfo != null) {
        if (debugMode) {
          print('[DEBUG] Found class $typeName in ${import.uri}');
        }
        return classInfo;
      }
    }

    if (debugMode) {
      print('[DEBUG] Class $typeName not found in any imported files');
    }
    return null;
  }

  /// Parse an imported file and search for a specific class with @Dataforge annotation
  /// Returns ClassInfo if found, null otherwise
  ClassInfo? _parseImportedFileForClass(String importUri, String className) {
    try {
      String? importPath = _resolveImportPath(importUri);

      if (importPath == null || !File(importPath).existsSync()) {
        if (debugMode) {
          print(
              '[DEBUG] Import file does not exist or cannot be resolved: $importUri -> $importPath');
        }
        return null;
      }

      // Parse the imported file
      final parser = Parser(importPath);
      final parseResult = parser.parseDartFile();

      if (parseResult == null) {
        if (debugMode) {
          print('[DEBUG] Failed to parse imported file: $importPath');
        }
        return null;
      }

      // Search for the target class in the parsed result
      for (final clazz in parseResult.classes) {
        if (clazz.name == className) {
          if (debugMode) {
            print(
                '[DEBUG] Found class $className with @Dataforge annotation in $importPath');
          }
          return clazz;
        }
      }

      if (debugMode) {
        print(
            '[DEBUG] Class $className not found or not annotated with @Dataforge in $importPath');
      }
      return null;
    } catch (e) {
      if (debugMode) {
        print('[DEBUG] Error parsing imported file $importUri: $e');
      }
      return null;
    }
  }

  /// Resolve import URI to actual file path
  /// Supports relative imports and package imports within the same project
  String? _resolveImportPath(String importUri) {
    try {
      // Handle relative imports (./file.dart, ../file.dart)
      if (importUri.startsWith('./') || importUri.startsWith('../')) {
        final currentDir =
            File(result.outputPath.replaceAll('.data.dart', '.dart')).parent;
        return File.fromUri(currentDir.uri.resolve(importUri)).path;
      }

      // Handle package imports within the same project
      if (importUri.startsWith('package:') && projectRoot != null) {
        // Extract package name and path
        final packageMatch =
            RegExp(r'^package:([^/]+)/(.+)$').firstMatch(importUri);
        if (packageMatch != null) {
          final packageName = packageMatch.group(1)!;
          final packagePath = packageMatch.group(2)!;

          // Try to find the package in the project root
          final possiblePaths = [
            '$projectRoot/lib/$packagePath',
            '$projectRoot/$packageName/lib/$packagePath',
          ];

          for (final path in possiblePaths) {
            if (File(path).existsSync()) {
              return path;
            }
          }
        }
      }

      // Handle direct .dart file imports
      if (importUri.endsWith('.dart') && !importUri.contains('/')) {
        final currentDir =
            File(result.outputPath.replaceAll('.data.dart', '.dart')).parent;
        final directPath = File.fromUri(currentDir.uri.resolve(importUri)).path;
        if (File(directPath).existsSync()) {
          return directPath;
        }
      }

      return null;
    } catch (e) {
      if (debugMode) {
        print('[DEBUG] Error resolving import path $importUri: $e');
      }
      return null;
    }
  }

  /// Check if a type is an enum by searching in imported files and project directories
  /// Returns true if the type is found as an enum definition
  bool isEnumType(String type) {
    final enumCheckStartTime = DateTime.now();

    // Remove nullable marker and generic parameters
    final cleanType = _removeGenericParameters(type.replaceAll('?', ''));
    if (debugMode) {
      print(
          '[PERF] $enumCheckStartTime: Starting enum type check for: $cleanType');
    }

    // First, check in imported files
    if (_findEnumInImports(cleanType)) {
      if (debugMode) {
        print('[DEBUG] Enum $cleanType found in imported files');
      }
      return true;
    }

    // Then check in project directories (fallback to current behavior)
    return _findEnumInProjectDirectories(cleanType, enumCheckStartTime);
  }

  /// Search for enum definition in imported files
  /// Returns true if enum is found in any imported file
  bool _findEnumInImports(String enumName) {
    for (final import in result.imports) {
      // Skip dart: core library imports
      if (import.uri.startsWith('dart:')) {
        continue;
      }

      if (_findEnumInFile(import.uri, enumName)) {
        return true;
      }
    }
    return false;
  }

  /// Search for enum definition in a specific imported file
  /// Returns true if enum is found in the file
  bool _findEnumInFile(String importUri, String enumName) {
    try {
      String? importPath = _resolveImportPath(importUri);

      if (importPath == null || !File(importPath).existsSync()) {
        if (debugMode) {
          print(
              '[DEBUG] Import file does not exist or cannot be resolved: $importUri -> $importPath');
        }
        return false;
      }

      final content = File(importPath).readAsStringSync();

      // Look for enum definition
      final enumPattern =
          RegExp(r'enum\s+' + RegExp.escape(enumName) + r'\s*\{');
      if (enumPattern.hasMatch(content)) {
        if (debugMode) {
          print('[DEBUG] Enum $enumName found in $importPath');
        }
        return true;
      }
    } catch (e) {
      if (debugMode) {
        print('[DEBUG] Error searching for enum in $importUri: $e');
      }
    }
    return false;
  }

  /// Fallback method to search for enum in project directories
  /// This maintains the original behavior for backward compatibility
  bool _findEnumInProjectDirectories(
      String cleanType, DateTime enumCheckStartTime) {
    // Use project root if available, otherwise fall back to current directory
    final searchDir =
        projectRoot != null ? Directory(projectRoot!) : Directory.current;
    if (!searchDir.existsSync()) {
      if (debugMode) {
        print(
            '[PERF] ${DateTime.now()}: Search directory does not exist: ${searchDir.path}');
      }
      return false;
    }

    // Check all Dart files in the search directory for enum definitions
    final scanStartTime = DateTime.now();
    final dartFiles = searchDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList();
    final scanEndTime = DateTime.now();
    final scanTime = scanEndTime.difference(scanStartTime).inMilliseconds;
    if (debugMode) {
      print(
          '[PERF] $scanEndTime: Directory scan completed, found ${dartFiles.length} Dart files in ${scanTime}ms');
    }

    final searchStartTime = DateTime.now();
    int filesChecked = 0;
    for (final file in dartFiles) {
      try {
        final content = file.readAsStringSync();
        filesChecked++;

        // Look for enum definition
        final enumPattern =
            RegExp(r'enum\s+' + RegExp.escape(cleanType) + r'\s*\{');
        if (enumPattern.hasMatch(content)) {
          final searchEndTime = DateTime.now();
          final searchTime =
              searchEndTime.difference(searchStartTime).inMilliseconds;
          final totalTime =
              searchEndTime.difference(enumCheckStartTime).inMilliseconds;
          if (debugMode) {
            print(
                '[PERF] $searchEndTime: Enum $cleanType found in ${file.path} after checking $filesChecked files (search:${searchTime}ms, total:${totalTime}ms)');
          }
          return true;
        }
      } catch (e) {
        // Ignore file read errors
        continue;
      }
    }

    final searchEndTime = DateTime.now();
    final searchTime = searchEndTime.difference(searchStartTime).inMilliseconds;
    final totalTime =
        searchEndTime.difference(enumCheckStartTime).inMilliseconds;
    if (debugMode) {
      print(
          '[PERF] $searchEndTime: Enum $cleanType not found after checking $filesChecked files (search:${searchTime}ms, total:${totalTime}ms)');
    }
    return false;
  }

  /// Remove generic parameters from a type string, handling nested generics correctly
  String _removeGenericParameters(String type) {
    int depth = 0;
    int start = -1;

    for (int i = 0; i < type.length; i++) {
      if (type[i] == '<') {
        if (depth == 0) {
          start = i;
        }
        depth++;
      } else if (type[i] == '>') {
        depth--;
        if (depth == 0 && start != -1) {
          // Remove the generic part
          type = type.substring(0, start) + type.substring(i + 1);
          i = start - 1; // Reset position
          start = -1;
        }
      }
    }

    return type;
  }

  /// Get all available classes from imported files
  /// Returns a map of class name to ClassInfo for all @Dataforge annotated classes
  Map<String, ClassInfo> getAllImportedClasses() {
    final Map<String, ClassInfo> importedClasses = {};

    for (final import in result.imports) {
      // Skip dart: core library imports
      if (import.uri.startsWith('dart:')) {
        continue;
      }

      try {
        String? importPath = _resolveImportPath(import.uri);

        if (importPath == null || !File(importPath).existsSync()) {
          continue;
        }

        // Parse the imported file
        final parser = Parser(importPath);
        final parseResult = parser.parseDartFile();

        if (parseResult == null) {
          continue;
        }

        // Collect all @Dataforge annotated classes
        for (final clazz in parseResult.classes) {
          importedClasses[clazz.name] = clazz;
        }
      } catch (e) {
        if (debugMode) {
          print('[DEBUG] Error processing import ${import.uri}: $e');
        }
      }
    }

    return importedClasses;
  }
}
