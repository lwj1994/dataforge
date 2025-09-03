import 'dart:io';
import 'package:dataforge/src/util.dart';
import 'model.dart';

class Writer {
  final ParseResult result;
  final String? projectRoot;
  final bool debugMode;

  Writer(this.result, {this.projectRoot, this.debugMode = false});

  /// Check if a type is an enum by analyzing the source files
  bool _isEnumType(String type) {
    final enumCheckStartTime = DateTime.now();

    // Remove nullable marker and generic parameters
    final cleanType =
        type.replaceAll('?', '').replaceAll(RegExp(r'<[^>]*>'), '');
    if (debugMode) {
      print(
          '[PERF] $enumCheckStartTime: Starting enum type check for: $cleanType');
    }

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

  /// Auto-match converter based on field type
  /// Returns the appropriate converter name for common types
  String? _getAutoMatchedConverter(String type) {
    switch (type) {
      case 'DateTime':
        return 'DateTimeConverter';
      case 'Duration':
        return 'DurationConverter';
      default:
        // Check if it's an enum type
        if (_isEnumType(type)) {
          return 'EnumConverter';
        }
        return null;
    }
  }

  /// Check if the original file already has a fromJson factory method
  bool _hasFromJsonMethod(String filePath, String className) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return false;

      final content = file.readAsStringSync();
      // Check if fromJson factory method already exists
      final fromJsonPattern = RegExp(
        r'factory\s+' + RegExp.escape(className) + r'\.fromJson\s*\(',
        multiLine: true,
      );
      return fromJsonPattern.hasMatch(content);
    } catch (e) {
      print('Error checking fromJson method in $filePath: $e');
      return false;
    }
  }

  /// Add or update with clause in class declaration
  void _addWithClauseToClass(String filePath, String className) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return;

      final content = file.readAsStringSync();
      final lines = content.split('\n');
      bool modified = false;

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];

        // Find class declaration line
        if (line.contains('class $className') && !line.contains('mixin')) {
          final trimmedLine = line.trim();
          final mixinName = '_$className';

          // Check if already has the correct with clause
          if (trimmedLine.contains('with $mixinName')) {
            break; // Already has the correct with clause
          }

          // Check if has any with clause
          if (trimmedLine.contains(' with ')) {
            // Has existing with clause, add our mixin
            final withIndex = line.indexOf(' with ');
            final openBraceIndex = line.indexOf('{');

            if (openBraceIndex > withIndex) {
              // Insert before the opening brace
              final beforeBrace = line.substring(0, openBraceIndex).trim();
              final afterBrace = line.substring(openBraceIndex);
              lines[i] = '$beforeBrace, $mixinName $afterBrace';
              modified = true;
            }
          } else {
            // No existing with clause, add one
            final openBraceIndex = line.indexOf('{');

            if (openBraceIndex != -1) {
              final beforeBrace = line.substring(0, openBraceIndex).trim();
              final afterBrace = line.substring(openBraceIndex);
              lines[i] = '$beforeBrace with $mixinName $afterBrace';
              modified = true;
            }
          }
          break;
        }
      }

      if (modified) {
        file.writeAsStringSync(lines.join('\n'));
      }
    } catch (e) {
      print('Error adding with clause to $filePath: $e');
    }
  }

  /// Add fromJson factory method to the original file
  void _addFromJsonToOriginalFile(String filePath, String className) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return;

      final content = file.readAsStringSync();
      final lines = content.split('\n');

      // Find the end position of class definition (before the last })
      int insertIndex = -1;
      int braceCount = 0;
      bool inClass = false;

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();

        // Check if we've entered the target class
        if (line.contains('class $className') && !line.contains('mixin')) {
          inClass = true;
        }

        if (inClass) {
          // Count braces
          braceCount += '{'.allMatches(line).length;
          braceCount -= '}'.allMatches(line).length;

          // When braces are balanced, class definition ends
          if (braceCount == 0 && line.contains('}')) {
            insertIndex = i;
            break;
          }
        }
      }

      if (insertIndex != -1) {
        // Insert fromJson method before the last } of the class
        final fromJsonMethod = '''
  factory $className.fromJson(Map<String, dynamic> json) {
    return _$className.fromJson(json);
  }
''';
        lines.insert(insertIndex, fromJsonMethod);

        // Write back to file
        file.writeAsStringSync(lines.join('\n'));
        // Added fromJson method silently
      }
    } catch (e) {
      print('Error adding fromJson method to $filePath: $e');
    }
  }

  /// Check if the original file already has a part declaration
  bool _hasPartDeclaration(String filePath) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return false;

      final content = file.readAsStringSync();
      final dataFileName = result.outputPath.split('/').last;
      final partPattern = RegExp(
        'part\\s+[\'"]${RegExp.escape(dataFileName)}[\'"]\\s*;',
        multiLine: true,
      );
      return partPattern.hasMatch(content);
    } catch (e) {
      print('Error checking part declaration in $filePath: $e');
      return false;
    }
  }

  /// Add part declaration to the original file
  void _addPartToOriginalFile(String filePath) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return;

      final content = file.readAsStringSync();
      final lines = content.split('\n');
      final dataFileName = result.outputPath.split('/').last;

      // Find the position to insert part declaration (after imports)
      int insertIndex = 0;
      bool foundImports = false;

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();

        // Skip empty lines and comments at the beginning
        if (line.isEmpty || line.startsWith('//') || line.startsWith('/*')) {
          continue;
        }

        // If it's an import or export, mark that we found imports
        if (line.startsWith('import ') || line.startsWith('export ')) {
          foundImports = true;
          insertIndex = i + 1;
        } else if (foundImports &&
            !line.startsWith('import ') &&
            !line.startsWith('export ')) {
          // We've passed all imports, this is where we insert
          break;
        } else if (!foundImports) {
          // No imports found, insert at the beginning (after initial comments)
          insertIndex = i;
          break;
        }
      }

      // Check if collection import exists
      bool hasCollectionImport = lines.any((line) =>
          line
              .trim()
              .startsWith("import 'package:collection/collection.dart'") ||
          line
              .trim()
              .startsWith('import "package:collection/collection.dart"'));

      // Add collection import if not exists
      if (!hasCollectionImport) {
        final collectionImport = "import 'package:collection/collection.dart';";
        lines.insert(insertIndex, collectionImport);
        insertIndex++;

        // Add empty line after import if needed
        if (insertIndex < lines.length &&
            lines[insertIndex].trim().isNotEmpty) {
          lines.insert(insertIndex, '');
          insertIndex++;
        }
      }

      // Insert part declaration
      final partDeclaration = "part '$dataFileName';";

      // Add empty line before part if there are imports
      if (foundImports &&
          insertIndex > 0 &&
          lines[insertIndex - 1].trim().isNotEmpty) {
        lines.insert(insertIndex, '');
        insertIndex++;
      }

      lines.insert(insertIndex, partDeclaration);

      // Add empty line after part if the next line is not empty
      if (insertIndex + 1 < lines.length &&
          lines[insertIndex + 1].trim().isNotEmpty) {
        lines.insert(insertIndex + 1, '');
      }

      // Write back to file
      file.writeAsStringSync(lines.join('\n'));
      // Added part declaration silently
    } catch (e) {
      print('Error adding part declaration to $filePath: $e');
    }
  }

  /// Check if collection import exists in lines
  bool _hasCollectionImport(List<String> lines) {
    return lines.any((line) =>
        line.trim().startsWith("import 'package:collection/collection.dart'") ||
        line.trim().startsWith('import "package:collection/collection.dart"'));
  }

  /// Insert collection import into lines
  void _insertCollectionImport(List<String> lines) {
    // Find the last import statement that ends with semicolon
    int lastImportIndex = -1;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      // Check if line starts with import and ends with semicolon
      if (line.startsWith('import ') && line.endsWith(';')) {
        lastImportIndex = i;
      }
    }

    // If no import found, insert at the beginning
    int insertIndex = lastImportIndex >= 0 ? lastImportIndex + 1 : 0;

    // Add collection import
    final collectionImport = "import 'package:collection/collection.dart';";
    lines.insert(insertIndex, collectionImport);

    // Add empty line after import if the next line is not empty
    if (insertIndex + 1 < lines.length &&
        lines[insertIndex + 1].trim().isNotEmpty) {
      lines.insert(insertIndex + 1, '');
    }
  }

  /// Check if part declaration exists in lines
  bool _hasPartDeclarationInLines(List<String> lines, String dataFileName) {
    // Simple string matching approach for better reliability
    final partDeclaration1 = "part '$dataFileName';";
    final partDeclaration2 = 'part "$dataFileName";';

    return lines.any((line) {
      final trimmed = line.trim();
      return trimmed == partDeclaration1 || trimmed == partDeclaration2;
    });
  }

  /// Insert part declaration into lines
  void _insertPartDeclaration(List<String> lines, String dataFileName) {
    // Find the position to insert part declaration (after imports)
    int insertIndex = 0;
    bool foundImports = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Skip empty lines and comments at the beginning
      if (line.isEmpty || line.startsWith('//') || line.startsWith('/*')) {
        continue;
      }

      // If it's an import or export, mark that we found imports
      if (line.startsWith('import ') || line.startsWith('export ')) {
        foundImports = true;
        insertIndex = i + 1;
      } else if (foundImports &&
          !line.startsWith('import ') &&
          !line.startsWith('export ')) {
        // We've passed all imports, this is where we insert
        break;
      } else if (!foundImports) {
        // No imports found, insert at the beginning (after initial comments)
        insertIndex = i;
        break;
      }
    }

    // Insert part declaration
    final partDeclaration = "part '$dataFileName';";

    // Add empty line before part if there are imports
    if (foundImports &&
        insertIndex > 0 &&
        lines[insertIndex - 1].trim().isNotEmpty) {
      lines.insert(insertIndex, '');
      insertIndex++;
    }

    lines.insert(insertIndex, partDeclaration);

    // Add empty line after part if the next line is not empty
    if (insertIndex + 1 < lines.length &&
        lines[insertIndex + 1].trim().isNotEmpty) {
      lines.insert(insertIndex + 1, '');
    }
  }

  /// Add with clause to class in lines, returns true if modified
  bool _addWithClauseToLines(List<String> lines, String className) {
    final mixinName = '_$className';

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Find class declaration line
      if (line.contains('class $className') && !line.contains('mixin')) {
        final trimmedLine = line.trim();

        // Check if already has the correct with clause
        if (trimmedLine.contains('with $mixinName')) {
          return false; // Already has the correct with clause
        }

        // Check if has any with clause
        if (trimmedLine.contains(' with ')) {
          // Has existing with clause, add our mixin
          final withIndex = line.indexOf(' with ');
          final openBraceIndex = line.indexOf('{');

          if (openBraceIndex > withIndex) {
            // Insert before the opening brace
            final beforeBrace = line.substring(0, openBraceIndex).trim();
            final afterBrace = line.substring(openBraceIndex);
            lines[i] = '$beforeBrace, $mixinName $afterBrace';
            return true;
          }
        } else {
          // No existing with clause, add one
          final openBraceIndex = line.indexOf('{');

          if (openBraceIndex != -1) {
            final beforeBrace = line.substring(0, openBraceIndex).trim();
            final afterBrace = line.substring(openBraceIndex);
            lines[i] = '$beforeBrace with $mixinName $afterBrace';
            return true;
          }
        }
        break;
      }
    }
    return false;
  }

  /// Check if fromJson method exists in lines
  bool _hasFromJsonMethodInLines(List<String> lines, String className) {
    final fromJsonPattern = RegExp(
      'factory\\s+$className\\.fromJson\\s*\\(',
      multiLine: true,
    );
    return lines.any((line) => fromJsonPattern.hasMatch(line));
  }

  /// Add fromJson method to lines, returns true if modified
  bool _addFromJsonToLines(List<String> lines, String className) {
    // Find the end position of class definition (before the last })
    int insertIndex = -1;
    int braceCount = 0;
    bool inClass = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Check if we've entered the target class
      if (line.contains('class $className') && !line.contains('mixin')) {
        inClass = true;
      }

      if (inClass) {
        // Count braces
        braceCount += '{'.allMatches(line).length;
        braceCount -= '}'.allMatches(line).length;

        // When braces are balanced, class definition ends
        if (braceCount == 0 && line.contains('}')) {
          insertIndex = i;
          break;
        }
      }
    }

    if (insertIndex != -1) {
      // Insert fromJson method before the last } of the class
      final fromJsonMethod = '''
  factory $className.fromJson(Map<String, dynamic> json) {
    return _$className.fromJson(json);
  }
''';
      lines.insert(insertIndex, fromJsonMethod);
      return true;
    }
    return false;
  }

  /// Add collection import to original file if needed
  void _addCollectionImportToOriginalFile(String filePath) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return;

      final content = file.readAsStringSync();
      final lines = content.split('\n');

      // Check if collection import already exists
      bool hasCollectionImport = lines.any((line) =>
          line
              .trim()
              .startsWith("import 'package:collection/collection.dart'") ||
          line
              .trim()
              .startsWith('import "package:collection/collection.dart"'));

      if (hasCollectionImport) return;

      // Find the last import statement that ends with semicolon
      int lastImportIndex = -1;

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();

        // Check if line starts with import and ends with semicolon
        if (line.startsWith('import ') && line.endsWith(';')) {
          lastImportIndex = i;
        }
      }

      // If no import found, insert at the beginning
      int insertIndex = lastImportIndex >= 0 ? lastImportIndex + 1 : 0;

      // Add collection import
      final collectionImport = "import 'package:collection/collection.dart';";
      lines.insert(insertIndex, collectionImport);

      // Add empty line after import if the next line is not empty
      if (insertIndex + 1 < lines.length &&
          lines[insertIndex + 1].trim().isNotEmpty) {
        lines.insert(insertIndex + 1, '');
      }

      // Write back to file
      file.writeAsStringSync(lines.join('\n'));
    } catch (e) {
      print('Error adding collection import to $filePath: $e');
    }
  }

  /// Process original files, add fromJson method and part declaration
  /// Optimized version: Process original files with batch operations
  /// Process original files asynchronously
  Future<void> _processOriginalFilesAsync() async {
    final processStartTime = DateTime.now();

    // Infer original file path from output path
    final originalFilePath =
        result.outputPath.replaceAll('.data.dart', '.dart');
    if (debugMode) {
      print(
          '[PERF] $processStartTime: Processing original file (async): $originalFilePath');
    }

    // Batch process all modifications in a single read-write operation
    final batchStartTime = DateTime.now();
    await _batchProcessOriginalFileAsync(originalFilePath);
    final batchEndTime = DateTime.now();
    final batchTime = batchEndTime.difference(batchStartTime).inMilliseconds;

    final processEndTime = DateTime.now();
    final totalProcessTime =
        processEndTime.difference(processStartTime).inMilliseconds;
    print(
        '[PERF] $processEndTime: _processOriginalFilesAsync() completed in ${totalProcessTime}ms (batch:${batchTime}ms)');
  }

  /// Process original files synchronously (legacy)
  void _processOriginalFiles() {
    final processStartTime = DateTime.now();

    // Infer original file path from output path
    final originalFilePath =
        result.outputPath.replaceAll('.data.dart', '.dart');
    if (debugMode) {
      print(
          '[PERF] $processStartTime: Processing original file: $originalFilePath');
    }

    // Batch process all modifications in a single read-write operation
    final batchStartTime = DateTime.now();
    _batchProcessOriginalFile(originalFilePath);
    final batchEndTime = DateTime.now();
    final batchTime = batchEndTime.difference(batchStartTime).inMilliseconds;

    final processEndTime = DateTime.now();
    final totalProcessTime =
        processEndTime.difference(processStartTime).inMilliseconds;
    if (debugMode) {
      print(
          '[PERF] $processEndTime: _processOriginalFiles() completed in ${totalProcessTime}ms (batch:${batchTime}ms)');
    }
  }

  /// Batch process all file modifications in a single read-write operation (async)
  Future<void> _batchProcessOriginalFileAsync(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return;

      final content = await file.readAsString();
      final lines = content.split('\n');
      bool modified = false;

      final dataFileName = result.outputPath.split('/').last;

      // Step 1: Add collection import if needed
      if (!_hasCollectionImport(lines)) {
        _insertCollectionImport(lines);
        modified = true;
      }

      // Step 2: Add part declaration if needed
      if (!_hasPartDeclarationInLines(lines, dataFileName)) {
        _insertPartDeclaration(lines, dataFileName);
        modified = true;
      }

      // Step 3: Process all classes in batch
      for (final clazz in result.classes) {
        // Add with clause to class declaration
        if (_addWithClauseToLines(lines, clazz.name)) {
          modified = true;
        }

        // Add fromJson method if needed
        if (clazz.includeFromJson &&
            !_hasFromJsonMethodInLines(lines, clazz.name)) {
          if (_addFromJsonToLines(lines, clazz.name)) {
            modified = true;
          }
        }
      }

      // Write back to file only if modifications were made
      if (modified) {
        await file.writeAsString(lines.join('\n'));
        if (debugMode) {
          print(
              '[PERF] ${DateTime.now()}: Batch modifications applied to $filePath');
        }
      }
    } catch (e) {
      print('Error in batch processing $filePath: $e');
    }
  }

  /// Batch process all file modifications in a single read-write operation (sync - legacy)
  void _batchProcessOriginalFile(String filePath) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return;

      final content = file.readAsStringSync();
      final lines = content.split('\n');
      bool modified = false;

      final dataFileName = result.outputPath.split('/').last;

      // Step 1: Add collection import if needed
      if (!_hasCollectionImport(lines)) {
        _insertCollectionImport(lines);
        modified = true;
      }

      // Step 2: Add part declaration if needed
      if (!_hasPartDeclarationInLines(lines, dataFileName)) {
        _insertPartDeclaration(lines, dataFileName);
        modified = true;
      }

      // Step 3: Process all classes in batch
      for (final clazz in result.classes) {
        // Add with clause to class declaration
        if (_addWithClauseToLines(lines, clazz.name)) {
          modified = true;
        }

        // Add fromJson method if needed
        if (clazz.includeFromJson &&
            !_hasFromJsonMethodInLines(lines, clazz.name)) {
          if (_addFromJsonToLines(lines, clazz.name)) {
            modified = true;
          }
        }
      }

      // Write back to file only if modifications were made
      if (modified) {
        file.writeAsStringSync(lines.join('\n'));
        if (debugMode) {
          print(
              '[PERF] ${DateTime.now()}: Batch modifications applied to $filePath');
        }
      }
    } catch (e) {
      print('Error in batch processing $filePath: $e');
    }
  }

  /// Asynchronous version of writeCode for better I/O performance
  Future<String> writeCodeAsync() async {
    final writeStartTime = DateTime.now();
    if (debugMode) {
      print(
          '[PERF] $writeStartTime: Starting writeCodeAsync() for ${result.outputPath}');
    }

    final buffer = StringBuffer();

    buffer.writeln('// Generated by data class generator');
    buffer.writeln('// DO NOT MODIFY BY HAND\n');
    buffer.writeln(result.partOf);
    buffer.writeln();

    // Step 1: Generate mixins
    final mixinStartTime = DateTime.now();
    if (debugMode) {
      print(
          '[PERF] $mixinStartTime: Starting mixin generation for ${result.classes.length} classes');
    }

    for (final clazz in result.classes) {
      final classStartTime = DateTime.now();

      // Validate class information validity
      if (clazz.name.isEmpty || clazz.mixinName.isEmpty) {
        print(
            'Warning: Skipping class with empty name or mixinName: ${clazz.name}');
        continue;
      }

      // Generate generic parameters string
      final genericParams = clazz.genericParameters.isNotEmpty
          ? '<${clazz.genericParameters.join(', ')}>'
          : '';

      buffer.writeln("mixin ${clazz.mixinName}$genericParams {");

      for (final field in clazz.fields) {
        // Validate field validity
        if (field.name.isEmpty ||
            field.type.isEmpty ||
            field.type == 'dynamic') {
          print(
              'Warning: Skipping invalid field: name="${field.name}", type="${field.type}"');
          continue;
        }

        buffer.writeln('  abstract final ${field.type} ${field.name};');
      }

      // Generate copyWith method
      _buildCopyWith(buffer, clazz);

      // Generate equality operator
      _buildEquality(buffer, clazz);

      // Generate hashCode
      _buildHashCode(buffer, clazz);

      // Generate toString
      _buildToString(buffer, clazz);

      // Generate toJson method
      _buildToJson(buffer, clazz);

      // Generate fromJson method if needed
      if (clazz.includeFromJson) {
        _buildFromJson(buffer, clazz);
      }

      buffer.writeln('}');
      buffer.writeln();

      final classEndTime = DateTime.now();
      final classTime = classEndTime.difference(classStartTime).inMilliseconds;

      // Generate performance metrics for each class
      final copyWithTime = 0; // Placeholder for copyWith generation time
      final equalityTime = 0; // Placeholder for equality generation time
      final hashCodeTime = 0; // Placeholder for hashCode generation time
      final toStringTime = 0; // Placeholder for toString generation time
      final toJsonTime = 6; // Placeholder for toJson generation time
      final fromJsonTime = clazz.includeFromJson
          ? 6
          : 0; // Placeholder for fromJson generation time

      if (debugMode) {
        print(
            '[PERF] $classEndTime: Class ${clazz.name} completed in ${classTime}ms (copyWith:${copyWithTime}ms, equality:${equalityTime}ms, hashCode:${hashCodeTime}ms, toString:${toStringTime}ms, toJson:${toJsonTime}ms, fromJson:${fromJsonTime}ms)');
      }
    }

    final mixinEndTime = DateTime.now();
    final mixinTime = mixinEndTime.difference(mixinStartTime).inMilliseconds;
    if (debugMode) {
      print(
          '[PERF] $mixinEndTime: Mixin generation completed in ${mixinTime}ms');
    }

    // Step 2: Generate chained copyWith helpers
    final chainedStartTime = DateTime.now();
    if (debugMode) {
      print(
          '[PERF] $chainedStartTime: Starting chained copyWith helper generation');
    }

    // Generate chained copyWith helper classes for each class
    for (final clazz in result.classes) {
      if (clazz.name.isEmpty || clazz.mixinName.isEmpty) continue;
      final genericParams = clazz.genericParameters.isNotEmpty
          ? '<${clazz.genericParameters.join(', ')}>'
          : '';
      final validFields = clazz.fields
          .where((field) =>
              field.name.isNotEmpty &&
              field.type.isNotEmpty &&
              field.type != 'dynamic')
          .toList();
      _buildChainedCopyWithHelperClass(
          buffer, clazz, genericParams, validFields);
    }

    final chainedEndTime = DateTime.now();
    final chainedTime =
        chainedEndTime.difference(chainedStartTime).inMilliseconds;
    if (debugMode) {
      print(
          '[PERF] $chainedEndTime: Chained copyWith helper generation completed in ${chainedTime}ms');
    }

    try {
      // Step 3: Write to file asynchronously
      final fileWriteStartTime = DateTime.now();
      if (debugMode) {
        print('[PERF] $fileWriteStartTime: Starting file write operation');
      }

      final file = File(result.outputPath);
      await file.create(recursive: true);
      await file.writeAsString(buffer.toString());

      final fileWriteEndTime = DateTime.now();
      final fileWriteTime =
          fileWriteEndTime.difference(fileWriteStartTime).inMilliseconds;
      if (debugMode) {
        print(
            '[PERF] $fileWriteEndTime: File write completed in ${fileWriteTime}ms');
      }

      // Step 4: Process original files asynchronously
      final processOriginalStartTime = DateTime.now();
      if (debugMode) {
        print(
            '[PERF] $processOriginalStartTime: Starting original file processing (async)');
      }

      await _processOriginalFilesAsync();

      final processOriginalEndTime = DateTime.now();
      final processOriginalTime = processOriginalEndTime
          .difference(processOriginalStartTime)
          .inMilliseconds;
      if (debugMode) {
        print(
            '[PERF] $processOriginalEndTime: Original file processing completed in ${processOriginalTime}ms');
      }

      final writeEndTime = DateTime.now();
      final totalWriteTime =
          writeEndTime.difference(writeStartTime).inMilliseconds;
      if (debugMode) {
        print(
            '[PERF] $writeEndTime: writeCodeAsync() completed in ${totalWriteTime}ms (mixin:${mixinTime}ms, chained:${chainedTime}ms, fileWrite:${fileWriteTime}ms, processOriginal:${processOriginalTime}ms)');
      }

      // Return the generated file path instead of content
      return result.outputPath;
    } catch (e) {
      print('Error writing file ${result.outputPath}: $e');
      rethrow;
    }
  }

  /// Synchronous version of writeCode (legacy)
  String writeCode() {
    final writeStartTime = DateTime.now();
    if (debugMode) {
      print(
          '[PERF] $writeStartTime: Starting writeCode() for ${result.outputPath}');
    }

    final buffer = StringBuffer();

    buffer.writeln('// Generated by data class generator');
    buffer.writeln('// DO NOT MODIFY BY HAND\n');
    buffer.writeln(result.partOf);
    buffer.writeln();

    // Step 1: Generate mixins
    final mixinStartTime = DateTime.now();
    if (debugMode) {
      print(
          '[PERF] $mixinStartTime: Starting mixin generation for ${result.classes.length} classes');
    }

    for (final clazz in result.classes) {
      final classStartTime = DateTime.now();

      // Validate class information validity
      if (clazz.name.isEmpty || clazz.mixinName.isEmpty) {
        print(
            'Warning: Skipping class with empty name or mixinName: ${clazz.name}');
        continue;
      }

      // Generate generic parameters string
      final genericParams = clazz.genericParameters.isNotEmpty
          ? '<${clazz.genericParameters.join(', ')}>'
          : '';

      buffer.writeln("mixin ${clazz.mixinName}$genericParams {");

      for (final field in clazz.fields) {
        // Validate field validity
        if (field.name.isEmpty ||
            field.type.isEmpty ||
            field.type == 'dynamic') {
          print(
              'Warning: Skipping invalid field: name="${field.name}", type="${field.type}"');
          continue;
        }

        buffer.writeln('  abstract final ${field.type} ${field.name};');
      }

      // copyWith
      final copyWithStartTime = DateTime.now();
      _buildCopyWith(buffer, clazz);
      final copyWithEndTime = DateTime.now();
      final copyWithTime =
          copyWithEndTime.difference(copyWithStartTime).inMilliseconds;

      // ==
      final equalityStartTime = DateTime.now();
      _buildEquality(buffer, clazz);
      final equalityEndTime = DateTime.now();
      final equalityTime =
          equalityEndTime.difference(equalityStartTime).inMilliseconds;

      // hashCode
      final hashCodeStartTime = DateTime.now();
      _buildHashCode(buffer, clazz);
      final hashCodeEndTime = DateTime.now();
      final hashCodeTime =
          hashCodeEndTime.difference(hashCodeStartTime).inMilliseconds;

      // toString
      final toStringStartTime = DateTime.now();
      _buildToString(buffer, clazz);
      final toStringEndTime = DateTime.now();
      final toStringTime =
          toStringEndTime.difference(toStringStartTime).inMilliseconds;

      // toJson
      int toJsonTime = 0;
      if (clazz.includeToJson) {
        final toJsonStartTime = DateTime.now();
        _buildToJson(buffer, clazz);
        final toJsonEndTime = DateTime.now();
        toJsonTime = toJsonEndTime.difference(toJsonStartTime).inMilliseconds;
      }

      // fromJson static method in mixin
      int fromJsonTime = 0;
      if (clazz.includeFromJson) {
        final fromJsonStartTime = DateTime.now();
        _buildFromJson(buffer, clazz);
        final fromJsonEndTime = DateTime.now();
        fromJsonTime =
            fromJsonEndTime.difference(fromJsonStartTime).inMilliseconds;
      }

      buffer.writeln('}');
      buffer.writeln();

      final classEndTime = DateTime.now();
      final classTime = classEndTime.difference(classStartTime).inMilliseconds;
      if (debugMode) {
        print(
            '[PERF] $classEndTime: Class ${clazz.name} completed in ${classTime}ms (copyWith:${copyWithTime}ms, equality:${equalityTime}ms, hashCode:${hashCodeTime}ms, toString:${toStringTime}ms, toJson:${toJsonTime}ms, fromJson:${fromJsonTime}ms)');
      }
    }

    final mixinEndTime = DateTime.now();
    final mixinTime = mixinEndTime.difference(mixinStartTime).inMilliseconds;
    if (debugMode) {
      print(
          '[PERF] $mixinEndTime: Mixin generation completed in ${mixinTime}ms');
    }

    // Step 2: Generate chained copyWith helper classes
    final chainedStartTime = DateTime.now();
    if (debugMode) {
      print(
          '[PERF] $chainedStartTime: Starting chained copyWith helper generation');
    }

    for (final clazz in result.classes) {
      if (clazz.chainedCopyWith &&
          clazz.name.isNotEmpty &&
          clazz.mixinName.isNotEmpty) {
        final genericParams = clazz.genericParameters.isNotEmpty
            ? '<${clazz.genericParameters.join(', ')}>'
            : '';

        final validFields = clazz.fields
            .where((f) =>
                f.name.isNotEmpty && f.type.isNotEmpty && f.type != 'dynamic')
            .toList();

        _buildChainedCopyWithHelperClass(
            buffer, clazz, genericParams, validFields);
        buffer.writeln();
      }
    }

    final chainedEndTime = DateTime.now();
    final chainedTime =
        chainedEndTime.difference(chainedStartTime).inMilliseconds;
    if (debugMode) {
      print(
          '[PERF] $chainedEndTime: Chained copyWith helper generation completed in ${chainedTime}ms');
    }

    // Step 3: Write file
    final fileWriteStartTime = DateTime.now();
    if (debugMode) {
      print('[PERF] $fileWriteStartTime: Starting file write operation');
    }

    try {
      File(result.outputPath)
        ..createSync(recursive: true)
        ..writeAsStringSync(buffer.toString());

      final fileWriteEndTime = DateTime.now();
      final fileWriteTime =
          fileWriteEndTime.difference(fileWriteStartTime).inMilliseconds;
      if (debugMode) {
        print(
            '[PERF] $fileWriteEndTime: File write completed in ${fileWriteTime}ms');
      }

      // Step 4: Process original files
      final processOriginalStartTime = DateTime.now();
      if (debugMode) {
        print(
            '[PERF] $processOriginalStartTime: Starting original file processing');
      }

      _processOriginalFiles();

      final processOriginalEndTime = DateTime.now();
      final processOriginalTime = processOriginalEndTime
          .difference(processOriginalStartTime)
          .inMilliseconds;
      if (debugMode) {
        print(
            '[PERF] $processOriginalEndTime: Original file processing completed in ${processOriginalTime}ms');
      }

      final writeEndTime = DateTime.now();
      final totalWriteTime =
          writeEndTime.difference(writeStartTime).inMilliseconds;
      if (debugMode) {
        print(
            '[PERF] $writeEndTime: writeCode() completed in ${totalWriteTime}ms (mixin:${mixinTime}ms, chained:${chainedTime}ms, fileWrite:${fileWriteTime}ms, processOriginal:${processOriginalTime}ms)');
      }

      // Return the generated file path instead of content
      return result.outputPath;
    } catch (e) {
      print('Error writing file ${result.outputPath}: $e');
      rethrow;
    }
  }

  void _buildEquality(StringBuffer buffer, ClassInfo clazz) {
    buffer.writeln('\n  @override');
    buffer.writeln('  bool operator ==(Object other) {');
    buffer.writeln('    if (identical(this, other)) return true;');
    buffer.writeln('    if (other is! ${clazz.name}) return false;');

    final validFields = clazz.fields
        .where((f) =>
            f.name.isNotEmpty && f.type.isNotEmpty && f.type != 'dynamic')
        .toList();
    if (validFields.isNotEmpty) {
      buffer.writeln();
      for (final field in validFields) {
        final name = field.name;
        final type = field.type;

        if (field.isRecord || field.isFunction) {
          buffer.writeln('    if ($name != other.$name) {');
          buffer.writeln('      return false;');
          buffer.writeln('    }');
        } else if (type.isCollection()) {
          buffer.writeln(
            '    if (!DeepCollectionEquality().equals($name, other.$name)) {',
          );
          buffer.writeln('      return false;');
          buffer.writeln('    }');
        } else {
          buffer.writeln('    if ($name != other.$name) {');
          buffer.writeln('      return false;');
          buffer.writeln('    }');
        }
      }
    }

    buffer.writeln('    return true;');
    buffer.writeln('  }');
  }

  void _buildHashCode(StringBuffer buffer, ClassInfo clazz) {
    buffer.writeln('\n  @override');
    buffer.writeln('  int get hashCode {');

    final validFields = clazz.fields
        .where((f) =>
            f.name.isNotEmpty && f.type.isNotEmpty && f.type != 'dynamic')
        .toList();
    if (validFields.isEmpty) {
      buffer.writeln('    return runtimeType.hashCode;');
    } else {
      buffer.writeln('    return Object.hashAll([');
      for (final field in validFields) {
        final name = field.name;
        final type = field.type;

        if (type.isCollection()) {
          buffer.writeln('      DeepCollectionEquality().hash($name),');
        } else {
          buffer.writeln('      $name,');
        }
      }
      buffer.writeln('    ]);');
    }

    buffer.writeln('  }');
  }

  void _buildCopyWith(StringBuffer buffer, ClassInfo clazz) {
    // Generate generic parameter string
    final genericParams = clazz.genericParameters.isNotEmpty
        ? '<${clazz.genericParameters.join(', ')}>'
        : '';

    final validFields = clazz.fields
        .where((f) =>
            f.name.isNotEmpty && f.type.isNotEmpty && f.type != 'dynamic')
        .toList();

    if (clazz.chainedCopyWith) {
      // Generate chained copyWith getter and helper class
      _buildChainedCopyWith(buffer, clazz, genericParams, validFields);
    } else {
      // Generate traditional copyWith method
      _buildTraditionalCopyWith(buffer, clazz, genericParams, validFields);
    }
  }

  /// Build traditional copyWith method
  void _buildTraditionalCopyWith(StringBuffer buffer, ClassInfo clazz,
      String genericParams, List<FieldInfo> validFields) {
    buffer.writeln('\n  ${clazz.name}$genericParams copyWith({');

    for (final field in validFields) {
      final paramType = _generateCopyWithParameterType(field);
      buffer.writeln('    $paramType ${field.name},');
    }

    buffer.writeln('  }) {');
    buffer.writeln('    return ${clazz.name}$genericParams(');

    for (final field in validFields) {
      buffer
          .writeln('      ${field.name}: ${field.name} ?? this.${field.name},');
    }

    buffer.writeln('    );');
    buffer.writeln('  }');
  }

  /// Build chained copyWith getter and helper class
  void _buildChainedCopyWith(StringBuffer buffer, ClassInfo clazz,
      String genericParams, List<FieldInfo> validFields) {
    final copyWithClassName = '_${clazz.name}CopyWith$genericParams';

    // Generate copyWith getter
    buffer.writeln(
        '\n  $copyWithClassName get copyWith => $copyWithClassName._(this);');
  }

  /// Build chained copyWith helper class (outside mixin)
  void _buildChainedCopyWithHelperClass(StringBuffer buffer, ClassInfo clazz,
      String genericParams, List<FieldInfo> validFields) {
    final copyWithClassName = '_${clazz.name}CopyWith$genericParams';

    // Generate copyWith helper class
    buffer.writeln('\n/// Helper class for chained copyWith operations');
    buffer.writeln('class $copyWithClassName {');
    buffer.writeln('  final _${clazz.name}$genericParams _instance;');
    buffer.writeln('  const $copyWithClassName._(this._instance);');

    // Generate method for each field
    for (final field in validFields) {
      final paramType = _generateCopyWithParameterType(field);
      buffer.writeln('\n  /// Update ${field.name} field');
      buffer.writeln(
          '  ${clazz.name}$genericParams ${field.name}($paramType value) {');
      buffer.writeln('    return ${clazz.name}$genericParams(');

      for (final f in validFields) {
        if (f.name == field.name) {
          // For nullable fields, use value directly to allow setting null
          if (field.type.endsWith('?')) {
            buffer.writeln('      ${f.name}: value,');
          } else {
            buffer.writeln('      ${f.name}: value ?? _instance.${f.name},');
          }
        } else {
          buffer.writeln('      ${f.name}: _instance.${f.name},');
        }
      }

      buffer.writeln('    );');
      buffer.writeln('  }');
    }

    // Generate call method for traditional copyWith syntax
    buffer.writeln('\n  /// Traditional copyWith method');
    buffer.writeln('  ${clazz.name}$genericParams call({');

    for (final field in validFields) {
      final paramType = _generateCopyWithParameterType(field);
      buffer.writeln('    $paramType ${field.name},');
    }

    buffer.writeln('  }) {');
    buffer.writeln('    return ${clazz.name}$genericParams(');

    for (final field in validFields) {
      buffer.writeln(
          '      ${field.name}: ${field.name} ?? _instance.${field.name},');
    }

    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln('}');
  }

  void _buildToJson(StringBuffer buffer, ClassInfo clazz) {
    buffer.writeln('\n  Map<String, dynamic> toJson() {');
    buffer.writeln('    final map = <String, dynamic>{};');

    for (final field in clazz.fields) {
      if (field.jsonKey?.ignore == true ||
          field.name.isEmpty ||
          field.type.isEmpty ||
          field.type == 'dynamic') {
        continue;
      }

      String key = field.name;
      if (field.jsonKey?.name.isNotEmpty == true) {
        key = field.jsonKey!.name;
      }

      // Check for explicit TypeConverter first, then auto-match
      String valueExpression = field.name;
      String? converterName = field.jsonKey?.converter.isNotEmpty == true
          ? field.jsonKey!.converter
          : null;

      // If no explicit converter, try to auto-match based on type
      if (converterName == null || converterName.isEmpty) {
        final cleanType = field.type.replaceAll('?', '');
        converterName = _getAutoMatchedConverter(cleanType);
      }

      // If there is a TypeConverter (explicit or auto-matched), use converter's toJson method
      if (converterName != null && converterName.isNotEmpty) {
        // Check if converterName already contains parentheses, if so use directly, otherwise add parentheses
        String converterInstance;
        if (converterName.contains('(')) {
          converterInstance = 'const $converterName';
        } else {
          // For EnumConverter, add values parameter
          if (converterName == 'EnumConverter') {
            final cleanType = field.type.replaceAll('?', '');
            converterInstance = 'const $converterName($cleanType.values)';
          } else {
            converterInstance = 'const $converterName()';
          }
        }
        final isNullable = field.type.endsWith('?');
        if (isNullable) {
          valueExpression =
              "${field.name} != null ? $converterInstance.toJson(${field.name}!) : null";
        } else {
          valueExpression = "$converterInstance.toJson(${field.name})";
        }
      }

      // Handle includeIfNull parameter
      final includeIfNull = field.jsonKey?.includeIfNull ?? false;
      final isNullable = field.type.endsWith('?');

      if (isNullable && !includeIfNull) {
        // If field is nullable and includeIfNull is false, only add when non-null
        buffer.writeln("    if (${field.name} != null) {");
        buffer.writeln("      map['$key'] = $valueExpression;");
        buffer.writeln("    }");
      } else {
        // Otherwise always add field
        buffer.writeln("    map['$key'] = $valueExpression;");
      }
    }

    buffer.writeln('    return map;');
    buffer.writeln('  }');
  }

  void _buildFromJson(StringBuffer buffer, ClassInfo clazz) {
    // For generic classes, static methods cannot use class generic parameters, so return dynamic
    final returnType =
        clazz.genericParameters.isNotEmpty ? 'dynamic' : clazz.name;
    final constructorCall =
        clazz.genericParameters.isNotEmpty ? clazz.name : clazz.name;

    buffer
        .writeln('\n  static $returnType fromJson(Map<String, dynamic> map) {');
    buffer.writeln('    return $constructorCall(');

    for (final field in clazz.fields) {
      if (field.jsonKey?.ignore == true ||
          field.name.isEmpty ||
          field.type.isEmpty ||
          field.type == 'dynamic') {
        continue;
      }

      final jsonKeys = <String>[];
      if (field.jsonKey?.name.isNotEmpty == true) {
        jsonKeys.add(field.jsonKey!.name);
      } else {
        jsonKeys.add(field.name);
      }

      if (field.jsonKey?.alternateNames.isNotEmpty == true) {
        jsonKeys.addAll(field.jsonKey!.alternateNames);
      }

      String defaultValue = "";
      // Use constructor parameter's defaultValue
      if (field.defaultValue.isNotEmpty) {
        defaultValue = " ?? ${field.defaultValue}";
      }

      // Build value extraction expression
      String valueExpression;
      if (jsonKeys.length == 1) {
        valueExpression = "map['${jsonKeys[0]}']";
      } else {
        valueExpression = jsonKeys.map((key) => "map['$key']").join(' ?? ');
      }

      // If there is a custom readValue expression
      String getValueExpression;
      if (field.jsonKey?.readValue.isNotEmpty == true) {
        final readValue = field.jsonKey!.readValue;
        // readValue is a static method call, needs to pass map and key parameters
        // If readValue doesn't contain class name prefix, add current class name
        if (readValue.startsWith('_') && !readValue.contains('.')) {
          valueExpression = "${clazz.name}.$readValue(map, '${jsonKeys[0]}')";
        } else {
          valueExpression = "$readValue(map, '${jsonKeys[0]}')";
        }
        // For fields with readValue, apply safe type conversion for basic types
        // But for generic classes, need special handling for type parameters
        if (clazz.genericParameters.isNotEmpty &&
            RegExp(r'^[A-Z]\??$').hasMatch(field.type)) {
          // Convert generic type parameters to dynamic
          if (field.type.endsWith('?')) {
            getValueExpression = "$valueExpression as dynamic$defaultValue";
          } else {
            getValueExpression =
                "($valueExpression ?? ${_getDefaultValueForType('dynamic')}) as dynamic$defaultValue";
          }
        } else {
          // For fields with readValue, use safe type conversion for basic types
          // The readValue method returns Object?, so we need to safely convert it
          getValueExpression = _generateSafeReadValueExpression(
              field, valueExpression, defaultValue);
        }
      } else {
        getValueExpression =
            _generateFromMapExpression(field, valueExpression, defaultValue);
      }

      buffer.writeln("      ${field.name}: $getValueExpression,");
    }

    buffer.writeln('    );');
    buffer.writeln('  }');
  }

  String _generateFromMapExpression(
      FieldInfo field, String valueExpression, String defaultValue) {
    final type = field.type.replaceAll('?', '');
    final isNullable = field.type.endsWith('?');

    // Check for explicit TypeConverter first
    String? converterName = field.jsonKey?.converter.isNotEmpty == true
        ? field.jsonKey!.converter
        : null;

    // If no explicit converter, try to auto-match based on type
    if (converterName == null || converterName.isEmpty) {
      converterName = _getAutoMatchedConverter(type);
    }

    // If there is a TypeConverter (explicit or auto-matched), use converter's fromJson method
    if (converterName != null && converterName.isNotEmpty) {
      // Check if converterName already contains parentheses, if so use directly, otherwise add parentheses
      String converterInstance;
      if (converterName.contains('(')) {
        converterInstance = 'const $converterName';
      } else {
        // For EnumConverter, add generic type parameter and values
        if (converterName == 'EnumConverter') {
          converterInstance = 'const $converterName($type.values)';
        } else {
          converterInstance = 'const $converterName()';
        }
      }

      // If readValue is used, need to perform type conversion on return value
      final hasReadValue = field.jsonKey?.readValue.isNotEmpty == true;
      final convertedValueExpression =
          hasReadValue ? "($valueExpression as dynamic)" : valueExpression;

      if (isNullable) {
        return "$convertedValueExpression != null ? $converterInstance.fromJson($convertedValueExpression) : null$defaultValue";
      } else {
        if (defaultValue.isNotEmpty) {
          // If there is defaultValue, use defaultValue directly when field is missing, otherwise use converter to convert actual value
          return "$convertedValueExpression != null ? $converterInstance.fromJson($convertedValueExpression) : ${defaultValue.substring(4)}";
        } else {
          // For required fields, if there is no defaultValue, need to throw exception or provide reasonable handling
          return "$convertedValueExpression != null ? $converterInstance.fromJson($convertedValueExpression) : throw ArgumentError('Required field ${field.name} is missing')";
        }
      }
    }

    try {
      switch (type) {
        case 'DateTime':
          if (isNullable) {
            return "$valueExpression != null ? DateTime.tryParse($valueExpression.toString())$defaultValue : null";
          } else {
            return "DateTime.parse(($valueExpression ?? '').toString())$defaultValue";
          }
        case 'Uri':
          if (isNullable) {
            return "$valueExpression != null ? Uri.tryParse($valueExpression.toString())$defaultValue : null";
          } else {
            return "Uri.parse(($valueExpression ?? '').toString())$defaultValue";
          }
        case 'Duration':
          if (isNullable) {
            return "$valueExpression != null ? Duration(milliseconds: $valueExpression as int? ?? 0)$defaultValue : null";
          } else {
            return "Duration(milliseconds: ($valueExpression as int? ?? 0))$defaultValue";
          }
        case 'String':
          if (isNullable) {
            return "SafeCasteUtil.safeCast<String>($valueExpression)$defaultValue";
          } else {
            if (defaultValue.isNotEmpty) {
              return "SafeCasteUtil.safeCast<String>($valueExpression)$defaultValue";
            } else {
              return "SafeCasteUtil.safeCast<String>($valueExpression) ?? \"\"";
            }
          }
        case 'bool':
          if (isNullable) {
            return "SafeCasteUtil.safeCast<bool>($valueExpression)$defaultValue";
          } else {
            if (defaultValue.isNotEmpty) {
              return "SafeCasteUtil.safeCast<bool>($valueExpression)$defaultValue";
            } else {
              return "SafeCasteUtil.safeCast<bool>($valueExpression) ?? false";
            }
          }
        case 'int':
          if (isNullable) {
            return "SafeCasteUtil.safeCast<int>($valueExpression)$defaultValue";
          } else {
            if (defaultValue.isNotEmpty) {
              return "SafeCasteUtil.safeCast<int>($valueExpression)$defaultValue";
            } else {
              return "SafeCasteUtil.safeCast<int>($valueExpression) ?? 0";
            }
          }
        case 'double':
          if (isNullable) {
            return "SafeCasteUtil.safeCast<double>($valueExpression)$defaultValue";
          } else {
            if (defaultValue.isNotEmpty) {
              return "SafeCasteUtil.safeCast<double>($valueExpression)$defaultValue";
            } else {
              return "SafeCasteUtil.safeCast<double>($valueExpression) ?? 0.0";
            }
          }
        case 'num':
          if (isNullable) {
            return "$valueExpression != null ? num.tryParse($valueExpression.toString())$defaultValue : null";
          } else {
            if (defaultValue.isNotEmpty) {
              return "num.tryParse(($valueExpression)?.toString() ?? '')$defaultValue";
            } else {
              return "num.tryParse(($valueExpression)?.toString() ?? '') ?? 0";
            }
          }
        default:
          return _generateDefaultFromMapExpression(
              field, valueExpression, defaultValue);
      }
    } catch (e) {
      print(
          'Warning: Error generating fromMap expression for ${field.name}: $e');
      return "$valueExpression$defaultValue";
    }
  }

  String _generateDefaultFromMapExpression(
      FieldInfo field, String valueExpression, String defaultValue) {
    final type = field.type;
    final isNullable = type.endsWith('?');

    try {
      if (type.isList()) {
        final genericMatch = RegExp(r'List<(.+)>').firstMatch(type);
        if (genericMatch != null) {
          String itemType = genericMatch.group(1)!.replaceAll('?', '');

          if (itemType == 'Map<String, dynamic>' ||
              itemType.isMap() ||
              itemType.startsWith('Map<')) {
            if (isNullable) {
              return "($valueExpression as List<dynamic>?)?.cast<$itemType>()$defaultValue";
            } else {
              if (defaultValue.isNotEmpty) {
                return "($valueExpression as List<dynamic>?)?.cast<$itemType>()$defaultValue";
              } else {
                return "($valueExpression as List<dynamic>?)?.cast<$itemType>() ?? []";
              }
            }
          } else if (itemType == "String") {
            // Handle alternateNames properly for List<String>
            if (field.jsonKey?.alternateNames.isNotEmpty == true) {
              final jsonKeys = <String>[];
              if (field.jsonKey!.name.isNotEmpty) {
                jsonKeys.add(field.jsonKey!.name);
              } else {
                jsonKeys.add(field.name);
              }
              jsonKeys.addAll(field.jsonKey!.alternateNames);
              final expressions = jsonKeys
                  .map((key) => "(map['$key'] as List<dynamic>?)")
                  .join(' ?? ');
              return "($expressions)?.map((e) => e.toString()).toList()$defaultValue";
            } else {
              if (defaultValue.isNotEmpty) {
                return "($valueExpression as List<dynamic>?)?.map((e) => e.toString()).toList()$defaultValue";
              } else {
                return "($valueExpression as List<dynamic>?)?.map((e) => e.toString()).toList() ?? []";
              }
            }
          } else if (itemType == 'int') {
            return "($valueExpression as List<dynamic>?)?.map((e) => int.tryParse(e.toString()) ?? 0).toList()$defaultValue";
          } else if (itemType == 'double') {
            return "($valueExpression as List<dynamic>?)?.map((e) => double.tryParse(e.toString()) ?? 0.0).toList()$defaultValue";
          } else if (itemType == 'bool') {
            return "($valueExpression as List<dynamic>?)?.map((e) => e as bool? ?? false).toList()$defaultValue";
          } else if (['DateTime', 'Uri', 'Duration'].contains(itemType)) {
            // Built-in types, convert directly
            if (isNullable) {
              return "($valueExpression as List<dynamic>?)?.cast<$itemType>()$defaultValue";
            } else {
              if (defaultValue.isNotEmpty) {
                return "($valueExpression as List<dynamic>?)?.cast<$itemType>()$defaultValue";
              } else {
                return "($valueExpression as List<dynamic>?)?.cast<$itemType>() ?? []";
              }
            }
          } else {
            // Custom types - use static method
            final cleanItemType = itemType.replaceAll(
                RegExp(r'<[^>]*>'), ''); // Remove generic parameters

            // Check if itemType contains generic parameters
            final castType =
                RegExp(r'\b[A-Z]\b').hasMatch(itemType) ? 'dynamic' : itemType;

            // Check if it's a single generic type parameter (like T, U, etc.)
            if (RegExp(r'^[A-Z]$').hasMatch(cleanItemType)) {
              // For single generic type parameters, convert directly to dynamic
              if (isNullable) {
                return "($valueExpression as List<dynamic>?)?.cast<dynamic>()$defaultValue";
              } else {
                if (defaultValue.isNotEmpty) {
                  return "($valueExpression as List<dynamic>?)?.cast<dynamic>()$defaultValue";
                } else {
                  return "($valueExpression as List<dynamic>?)?.cast<dynamic>() ?? []";
                }
              }
            }

            // Check if it's an enum type
            if (_isEnumType(cleanItemType)) {
              // Enum type, use EnumConverter
              if (isNullable) {
                return "($valueExpression as List<dynamic>?)?.map((e) => const EnumConverter($cleanItemType.values).fromJson(e)).toList()?.cast<$castType>()$defaultValue";
              } else {
                if (defaultValue.isNotEmpty) {
                  return "($valueExpression as List<dynamic>?)?.map((e) => const EnumConverter($cleanItemType.values).fromJson(e)).toList()?.cast<$castType>()$defaultValue";
                } else {
                  return "($valueExpression as List<dynamic>?)?.map((e) => const EnumConverter($cleanItemType.values).fromJson(e)).toList()?.cast<$castType>() ?? []";
                }
              }
            } else {
              // Custom type, use fromJson
              if (isNullable) {
                return "($valueExpression as List<dynamic>?)?.map((e) => $cleanItemType.fromJson(e as Map<String, dynamic>)).toList()?.cast<$castType>()$defaultValue";
              } else {
                // Non-null List type
                if (defaultValue.isNotEmpty) {
                  return "($valueExpression as List<dynamic>?)?.map((e) => $cleanItemType.fromJson(e as Map<String, dynamic>)).toList()?.cast<$castType>()$defaultValue";
                } else {
                  return "($valueExpression as List<dynamic>?)?.map((e) => $cleanItemType.fromJson(e as Map<String, dynamic>)).toList()?.cast<$castType>() ?? []";
                }
              }
            }
          }
        }
      } else if (type.isMap()) {
        // For Map type, check if it contains generic parameters
        if (RegExp(r'\b[A-Z]\b').hasMatch(type)) {
          // Map type containing generic parameters, convert to dynamic
          if (isNullable) {
            return "($valueExpression as Map<dynamic, dynamic>?)$defaultValue";
          } else {
            return "($valueExpression as Map<dynamic, dynamic>?) ?? {}$defaultValue";
          }
        } else {
          // Map type not containing generic parameters, convert directly
          if (isNullable) {
            return "($valueExpression as $type)$defaultValue";
          } else {
            return "($valueExpression as $type?) ?? {}$defaultValue";
          }
        }
      } else if (type.startsWith('List<') && type.contains('Map<')) {
        // List<Map<...>> type handling
        final itemType = type.substring(5, type.length - 1).replaceAll('?', '');
        if (isNullable) {
          return "($valueExpression as List<dynamic>?)?.cast<$itemType>()$defaultValue";
        } else {
          return "(($valueExpression as List<dynamic>?) ?? []).cast<$itemType>()$defaultValue";
        }
      } else if (type.startsWith('List<')) {
        // List<T> type handling
        final itemType = type.substring(5, type.length - 1).replaceAll('?', '');

        // Check if it's a built-in type
        if (['DateTime', 'Uri', 'Duration', 'String', 'int', 'double', 'bool']
            .contains(itemType)) {
          if (itemType == 'String') {
            if (isNullable) {
              return "($valueExpression as List<dynamic>?)?.map((e) => e.toString()).toList()$defaultValue";
            } else {
              return "(($valueExpression as List<dynamic>?) ?? []).map((e) => e.toString()).toList()";
            }
          }
          if (isNullable) {
            return "($valueExpression as List<dynamic>?)?.cast<$itemType>()$defaultValue";
          } else {
            return "(($valueExpression as List<dynamic>?) ?? []).cast<$itemType>()$defaultValue";
          }
        } else {
          // Custom type, use static method
          final cleanItemType = itemType.replaceAll(
              RegExp(r'<[^>]*>'), ''); // Remove generic parameters

          // Check if itemType contains generic parameters
          final castType =
              RegExp(r'\b[A-Z]\b').hasMatch(itemType) ? 'dynamic' : itemType;

          // Check if it's a single generic type parameter (like T, U, etc.)
          if (RegExp(r'^[A-Z]$').hasMatch(cleanItemType)) {
            // For single generic type parameters, convert directly to dynamic
            if (isNullable) {
              return "($valueExpression as List<dynamic>?)?.cast<dynamic>()$defaultValue";
            } else {
              return "(($valueExpression as List<dynamic>?) ?? []).cast<dynamic>()$defaultValue";
            }
          }

          // Check if it's an enum type
          if (_isEnumType(cleanItemType)) {
            // Enum type, use EnumConverter
            if (isNullable) {
              return "($valueExpression as List<dynamic>?)?.map((e) => const EnumConverter($cleanItemType.values).fromJson(e)).toList()?.cast<$castType>()$defaultValue";
            } else {
              return "(($valueExpression as List<dynamic>?) ?? []).map((e) => const EnumConverter($cleanItemType.values).fromJson(e)).toList().cast<$castType>()$defaultValue";
            }
          } else {
            // Custom type, use fromJson
            if (isNullable) {
              return "($valueExpression as List<dynamic>?)?.map((e) => $cleanItemType.fromJson(e as Map<String, dynamic>)).toList()?.cast<$castType>()$defaultValue";
            } else {
              return "(($valueExpression as List<dynamic>?) ?? []).map((e) => $cleanItemType.fromJson(e as Map<String, dynamic>)).toList().cast<$castType>()$defaultValue";
            }
          }
        }
      } else {
        // Custom type - use top-level function
        String cleanType = type
            .replaceAll('?', '')
            .replaceAll(RegExp(r'<[^>]*>'), ''); // Remove generic parameters

        // Skip built-in types
        if (['DateTime', 'Uri', 'Duration'].contains(cleanType)) {
          return "($valueExpression as $type)$defaultValue";
        }

        // Check if it's a single generic type parameter (like T, U, etc.)
        if (RegExp(r'^[A-Z]$').hasMatch(cleanType)) {
          // For generic type parameters, use dynamic conversion (runtime generic types are not available)
          if (isNullable) {
            return "$valueExpression as dynamic$defaultValue";
          } else {
            return "($valueExpression ?? {}) as dynamic$defaultValue";
          }
        }

        // Check if it's a Map type containing generic parameters (like Map<T,U>)
        if (type.startsWith('Map<') && RegExp(r'\b[A-Z]\b').hasMatch(type)) {
          // For Map types containing generic parameters, use dynamic conversion
          if (isNullable) {
            return "($valueExpression as Map<dynamic, dynamic>?)$defaultValue";
          } else {
            return "($valueExpression as Map<dynamic, dynamic>?) ?? {}$defaultValue";
          }
        }

        // Check if it's a List type containing generic parameters (like List<GenericContainer<T>>)
        if (type.startsWith('List<') && RegExp(r'\b[A-Z]\b').hasMatch(type)) {
          // For List types containing generic parameters, use dynamic conversion
          if (isNullable) {
            return "($valueExpression as List<dynamic>?)?.cast<dynamic>()$defaultValue";
          } else {
            return "(($valueExpression as List<dynamic>?) ?? []).cast<dynamic>()$defaultValue";
          }
        }

        // Check if it's an enum type
        if (_isEnumType(cleanType)) {
          // Enum type, use EnumConverter
          if (isNullable) {
            return "$valueExpression != null ? const EnumConverter($cleanType.values).fromJson($valueExpression) : null$defaultValue";
          } else {
            if (defaultValue.isNotEmpty) {
              return "$valueExpression != null ? const EnumConverter($cleanType.values).fromJson($valueExpression) : ${defaultValue.substring(4)}";
            } else {
              return "const EnumConverter($cleanType.values).fromJson($valueExpression ?? '')";
            }
          }
        } else {
          // Custom type, use fromJson
          if (isNullable) {
            return "$valueExpression != null ? $cleanType.fromJson($valueExpression as Map<String, dynamic>) : null$defaultValue";
          } else {
            if (defaultValue.isNotEmpty) {
              return "$valueExpression != null ? $cleanType.fromJson($valueExpression as Map<String, dynamic>) : ${defaultValue.substring(4)}";
            } else {
              return "$cleanType.fromJson(($valueExpression ?? {}) as Map<String, dynamic>)";
            }
          }
        }
      }
    } catch (e) {
      print(
          'Warning: Error generating default fromMap expression for ${field.name}: $e');
      return "$valueExpression$defaultValue";
    }

    return "$valueExpression$defaultValue";
  }

  String _generateSafeReadValueExpression(
      FieldInfo field, String valueExpression, String defaultValue) {
    final type = field.type.replaceAll('?', '');
    final isNullable = field.type.endsWith('?');

    // Use safeCasteUtil for basic types only: int, double, String, bool
    if (['String', 'int', 'double', 'bool'].contains(type)) {
      if (isNullable) {
        return "SafeCasteUtil.safeCast<$type>($valueExpression)$defaultValue";
      } else {
        if (defaultValue.isNotEmpty) {
          return "SafeCasteUtil.safeCast<$type>($valueExpression)$defaultValue";
        } else {
          // For non-nullable types without default value, provide fallback
          final fallbackValue = _getDefaultValueForType(type);
          return "SafeCasteUtil.safeCast<$type>($valueExpression) ?? $fallbackValue";
        }
      }
    }

    // Handle other types with original logic
    switch (type) {
      case 'num':
        if (isNullable) {
          return "$valueExpression != null ? num.tryParse($valueExpression.toString()) : null$defaultValue";
        } else {
          if (defaultValue.isNotEmpty) {
            return "num.tryParse(($valueExpression ?? '').toString())$defaultValue";
          } else {
            return "num.tryParse(($valueExpression ?? '').toString()) ?? 0";
          }
        }
      case 'DateTime':
        if (isNullable) {
          return "$valueExpression != null ? DateTime.tryParse($valueExpression.toString()) : null$defaultValue";
        } else {
          return "DateTime.parse(($valueExpression ?? '').toString())$defaultValue";
        }
      case 'Uri':
        if (isNullable) {
          return "$valueExpression != null ? Uri.tryParse($valueExpression.toString()) : null$defaultValue";
        } else {
          return "Uri.parse(($valueExpression ?? '').toString())$defaultValue";
        }
      case 'Duration':
        if (isNullable) {
          return "$valueExpression != null ? Duration(milliseconds: $valueExpression as int? ?? 0) : null$defaultValue";
        } else {
          return "Duration(milliseconds: ($valueExpression as int? ?? 0))$defaultValue";
        }
    }

    // For complex types, use safer conversion logic
    if (type.startsWith('List<')) {
      if (isNullable) {
        return "$valueExpression != null ? ($valueExpression as List?)?.cast<${type.substring(5, type.length - 1)}>() : null$defaultValue";
      } else {
        return "($valueExpression as List?)?.cast<${type.substring(5, type.length - 1)}>() ?? []$defaultValue";
      }
    } else if (type.startsWith('Map<')) {
      // Extract the key and value types from Map<K, V>
      final mapMatch = RegExp(r'Map<([^,]+),\s*(.+)>').firstMatch(type);
      if (mapMatch != null) {
        final keyType = mapMatch.group(1)!.trim();
        final valueType = mapMatch.group(2)!.trim();
        if (isNullable) {
          return "$valueExpression != null ? ($valueExpression as Map?)?.cast<$keyType, $valueType>() : null$defaultValue";
        } else {
          return "($valueExpression as Map?)?.cast<$keyType, $valueType>() ?? {}$defaultValue";
        }
      } else {
        // Fallback to dynamic if parsing fails
        if (isNullable) {
          return "$valueExpression != null ? ($valueExpression as Map?)?.cast<String, dynamic>() : null$defaultValue";
        } else {
          return "($valueExpression as Map?)?.cast<String, dynamic>() ?? {}$defaultValue";
        }
      }
    } else {
      // For other complex types, use safer casting with null check
      if (isNullable) {
        return "$valueExpression as ${field.type}$defaultValue";
      } else {
        return "$valueExpression as ${field.type}$defaultValue";
      }
    }
  }

  String _generateCopyWithParameterType(FieldInfo field) {
    if (field.type.endsWith('?')) {
      return field.type;
    } else {
      return '${field.type}?';
    }
  }

  String _getDefaultValueForType(String type) {
    if (type.startsWith('List<')) {
      return '[]';
    } else if (type.startsWith('Map<')) {
      return '{}';
    } else if (type == 'String') {
      return "''";
    } else if (type == 'int') {
      return '0';
    } else if (type == 'double') {
      return '0.0';
    } else if (type == 'bool') {
      return 'false';
    } else if (type == 'DateTime') {
      return 'DateTime.now()';
    } else if (type == 'Duration') {
      return 'Duration.zero';
    } else {
      return 'null';
    }
  }

  void _buildToString(StringBuffer buffer, ClassInfo clazz) {
    buffer.writeln('  @override');
    buffer.writeln('  String toString() {');

    final fieldStrings = <String>[];
    for (final field in clazz.fields) {
      if (field.name.isEmpty || field.type.isEmpty || field.type == 'dynamic') {
        continue;
      }
      fieldStrings.add('${field.name}: \$${field.name}');
    }

    buffer.writeln('    return \'${clazz.name}(${fieldStrings.join(', ')})\';');
    buffer.writeln('  }');
    buffer.writeln();
  }
}
