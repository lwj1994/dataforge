import 'dart:io';

import 'model.dart';

class Writer {
  final ParseResult result;
  final String? projectRoot;
  final bool debugMode;
  late final String _dataforgeAnnotationPrefix;
  final Set<String> _enumTypeCache = {};

  Writer(this.result, {this.projectRoot, this.debugMode = false}) {
    _dataforgeAnnotationPrefix = _getDataforgeAnnotationPrefix();
  }

  /// Get the prefix for dataforge_annotation based on import statements
  String _getDataforgeAnnotationPrefix() {
    for (final import in result.imports) {
      if (import.uri ==
              'package:dataforge_annotation/dataforge_annotation.dart' &&
          import.alias != null) {
        return '${import.alias!}.';
      }
    }
    return ''; // No prefix needed if no alias is used
  }

  /// Get SafeCasteUtil with proper prefix based on import alias
  String _getSafeCasteUtil() {
    final prefix = _getDataforgeAnnotationPrefix();
    return '${prefix}SafeCasteUtil';
  }

  /// Check if a type is an enum by analyzing the source files
  bool _isEnumType(String type) {
    final enumCheckStartTime = DateTime.now();

    // Remove nullable marker and generic parameters
    final cleanType = _removeGenericParameters(type.replaceAll('?', ''));
    if (_enumTypeCache.contains(cleanType)) {
      return true;
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
          _enumTypeCache.add(cleanType);
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
    if (!type.contains('<')) {
      return type;
    }

    final buffer = StringBuffer();
    int depth = 0;

    for (int i = 0; i < type.length; i++) {
      final char = type[i];

      if (char == '<') {
        depth++;
      } else if (char == '>') {
        depth--;
      } else if (depth == 0) {
        buffer.write(char);
      }
    }

    return buffer.toString();
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

    // Insert collection import after the last import
    if (lastImportIndex >= 0) {
      lines.insert(
          lastImportIndex + 1, "import 'package:collection/collection.dart';");
    } else {
      // If no imports found, insert at the beginning
      lines.insert(0, "import 'package:collection/collection.dart';");
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
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Find class declaration line
      final classPattern =
          RegExp(r'\bclass\s+' + RegExp.escape(className) + r'\b');
      if (classPattern.hasMatch(line) && !line.contains('mixin')) {
        String genericPart = '';
        final genericStartIndex = line.indexOf('<');

        // Check for presence of generics and that it's part of the class name
        final classDefRegex =
            RegExp('^\\s*(abstract\\s+)?class\\s+$className\\s*<');
        if (genericStartIndex != -1 && classDefRegex.hasMatch(line)) {
          int depth = 0;
          int genericEndIndex = -1;
          for (int j = genericStartIndex; j < line.length; j++) {
            if (line[j] == '<') {
              depth++;
            } else if (line[j] == '>') {
              depth--;
              if (depth == 0) {
                genericEndIndex = j;
                break;
              }
            }
          }
          if (genericEndIndex != -1) {
            genericPart =
                line.substring(genericStartIndex, genericEndIndex + 1);
          }
        }

        final mixinName = '_$className$genericPart';
        final trimmedLine = line.trim();

        // Check if already has the correct with clause
        final mixinPattern = RegExp('\\b${RegExp.escape(mixinName)}\\b');
        if (mixinPattern.hasMatch(trimmedLine)) {
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
      final classPattern =
          RegExp(r'\bclass\s+' + RegExp.escape(className) + r'\b');
      if (!inClass && classPattern.hasMatch(line) && !line.contains('mixin')) {
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

      // Generate generic parameters string with bounds
      final genericParams = clazz.genericParameters.isNotEmpty
          ? '<${clazz.genericParameters.map((p) => p.toString()).join(', ')}>'
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
      if (clazz.deepCopyWith &&
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
    final validFields = clazz.fields
        .where((f) =>
            f.name.isNotEmpty &&
            f.type.isNotEmpty &&
            f.type != 'dynamic' &&
            !f.isFunction)
        .toList();

    buffer.writeln('\n  @override');
    buffer.writeln('  bool operator ==(Object other) {');
    buffer.writeln('    if (identical(this, other)) return true;');
    buffer.writeln('    if (other is! ${clazz.name}) return false;');
    buffer.writeln();

    if (validFields.isEmpty) {
      buffer.writeln('    return true;');
    } else {
      buffer.write('    return ');
      for (int i = 0; i < validFields.length; i++) {
        final field = validFields[i];
        final isLast = i == validFields.length - 1;
        buffer.write('other.${field.name} == ${field.name}');
        if (!isLast) {
          buffer.write(' && ');
        }
      }
      buffer.writeln(';');
    }
    buffer.writeln('  }');
  }

  void _buildHashCode(StringBuffer buffer, ClassInfo clazz) {
    final validFields = clazz.fields
        .where((f) =>
            f.name.isNotEmpty &&
            f.type.isNotEmpty &&
            f.type != 'dynamic' &&
            !f.isFunction)
        .toList();

    buffer.writeln('\n  @override');
    buffer.writeln('  int get hashCode => Object.hashAll([');
    for (final field in validFields) {
      buffer.writeln('        ${field.name},');
    }
    buffer.writeln('      ]);');
  }

  void _buildCopyWith(StringBuffer buffer, ClassInfo clazz) {
    // Generate generic parameter string with bounds for mixin declaration
    final genericParams = clazz.genericParameters.isNotEmpty
        ? '<${clazz.genericParameters.map((p) => p.toString()).join(', ')}>'
        : '';

    final validFields = clazz.fields
        .where((f) =>
            f.name.isNotEmpty &&
            f.type.isNotEmpty &&
            f.type != 'dynamic' &&
            !f.isFunction)
        .toList();

    if (clazz.deepCopyWith) {
      // Chained copyWith style
      final genericArgs = genericParams.isEmpty
          ? '<${clazz.name}>'
          : genericParams.replaceFirst('>', ', ${clazz.name}$genericParams>');
      buffer.writeln(
          '\n  _${clazz.name}CopyWith$genericArgs get copyWith => _${clazz.name}CopyWith$genericArgs._(this);');
    } else {
      // Traditional copyWith style
      _buildTraditionalCopyWith(buffer, clazz, genericParams, validFields);
    }
  }

  /// Build traditional copyWith method
  void _buildTraditionalCopyWith(StringBuffer buffer, ClassInfo clazz,
      String genericParams, List<FieldInfo> validFields) {
    buffer.writeln('\n  ${clazz.name}$genericParams copyWith({');

    for (final field in validFields) {
      final type = field.type.endsWith('?') ? field.type : '${field.type}?';
      buffer.writeln('    $type ${field.name},');
    }

    buffer.writeln('  }) {');
    buffer.writeln('    return ${clazz.name}(');

    for (final field in validFields) {
      buffer
          .writeln('      ${field.name}: ${field.name} ?? this.${field.name},');
    }

    buffer.writeln('    );');
    buffer.writeln('  }');
  }

  /// Build chained copyWith helper class (outside mixin)
  void _buildChainedCopyWithHelperClass(StringBuffer buffer, ClassInfo clazz,
      String genericParams, List<FieldInfo> validFields) {
    final copyWithClassName = '_${clazz.name}CopyWith';
    final returnType = 'R';
    final genericParamsWithR = genericParams.isEmpty
        ? '<$returnType>'
        : genericParams.replaceFirst('>', ', $returnType>');

    buffer.writeln('class $copyWithClassName$genericParamsWithR {');
    buffer.writeln('  final _${clazz.name}$genericParams _instance;');
    buffer.writeln(
        '  final $returnType Function(${clazz.name}$genericParams)? _then;');
    buffer.writeln('  $copyWithClassName._(this._instance, [this._then]);');

    buffer.writeln();
    buffer.writeln('  R call({');
    // Use Object? with sentinel default for all parameters
    for (final field in validFields) {
      buffer.writeln(
          '    Object? ${field.name} = ${_dataforgeAnnotationPrefix}dataforgeUndefined,');
    }
    buffer.writeln('  }) {');
    buffer.writeln('    final res = ${clazz.name}$genericParams(');
    for (final field in validFields) {
      // Use sentinel check to distinguish null from omitted
      buffer.writeln(
          '      ${field.name}: ${field.name} == ${_dataforgeAnnotationPrefix}dataforgeUndefined ? _instance.${field.name} : ${field.name} as ${field.type},');
    }
    buffer.writeln('    );');
    buffer.writeln('    return _then != null ? _then!(res) : res as R;');
    buffer.writeln('  }');
    buffer.writeln();

    // Generate single-field update methods
    for (final field in validFields) {
      buffer.writeln('  R ${field.name}(${field.type} value) {');
      buffer.writeln('    final res = ${clazz.name}$genericParams(');
      for (final f in validFields) {
        if (f.name == field.name) {
          buffer.writeln('      ${f.name}: value,');
        } else {
          buffer.writeln('      ${f.name}: _instance.${f.name},');
        }
      }
      buffer.writeln('    );');
      buffer.writeln('    return _then != null ? _then!(res) : res as R;');
      buffer.writeln('  }');
      buffer.writeln();
    }

    // Generate chained copyWith accessors (Flat Accessor Pattern)
    if (clazz.deepCopyWith) {
      _generateNestedFieldAccessors(
          buffer, clazz, genericParams, validFields, [], clazz);
    }

    buffer.writeln('}');
  }

  void _buildToJson(StringBuffer buffer, ClassInfo clazz) {
    buffer.writeln('\n  Map<String, dynamic> toJson() {');
    buffer.writeln('    return {');

    for (final field in clazz.fields) {
      if (field.jsonKey?.ignore == true ||
          field.name.isEmpty ||
          field.type.isEmpty ||
          field.type == 'dynamic' ||
          field.isFunction) {
        continue;
      }

      final jsonKey = field.jsonKey?.name.isNotEmpty == true
          ? field.jsonKey!.name
          : field.name;

      final cleanType = field.type.replaceAll('?', '');
      final isNullable = field.type.endsWith('?');
      String valueAccess;
      final jsonKeyInfo = field.jsonKey;
      final customToJson = jsonKeyInfo?.toJson;
      final customConverter = jsonKeyInfo?.converter;

      // Priority 1: Custom toJson function (highest priority)
      if (customToJson != null && customToJson.isNotEmpty) {
        // Check if toJsonFunc needs class prefix (for static methods starting with _)
        final fullToJsonFunc =
            customToJson.startsWith('_') && !customToJson.contains('.')
                ? '${clazz.name}.$customToJson'
                : customToJson;
        if (isNullable) {
          valueAccess =
              '${field.name} != null ? $fullToJsonFunc(${field.name}!) : null';
        } else {
          valueAccess = '$fullToJsonFunc(${field.name})';
        }
      }
      // Priority 2: Custom converter
      else if (customConverter != null && customConverter.isNotEmpty) {
        valueAccess = 'const $customConverter().toJson(${field.name})';
      }
      // Priority 3: Auto-matched converters (DateTime, Enum)
      else if (field.isDateTime) {
        valueAccess =
            'const ${_dataforgeAnnotationPrefix}DefaultDateTimeConverter().toJson(${field.name})';
      } else if (field.isEnum || _isEnumType(cleanType)) {
        valueAccess =
            '${_dataforgeAnnotationPrefix}DefaultEnumConverter($cleanType.values).toJson(${field.name})';
      }
      // Priority 4: Default (direct access)
      else {
        valueAccess = field.name;
      }

      buffer.writeln("      '$jsonKey': $valueAccess,");
    }

    buffer.writeln('    };');
    buffer.writeln('  }');
  }

  void _buildFromJson(StringBuffer buffer, ClassInfo clazz) {
    // For generic classes, generate both static fromJson and factory method
    if (clazz.genericParameters.isNotEmpty) {
      _buildGenericFromJson(buffer, clazz);
    } else {
      _buildRegularFromJson(buffer, clazz);
    }
  }

  /// Build fromJson methods for generic classes
  void _buildGenericFromJson(StringBuffer buffer, ClassInfo clazz) {
    // Generate static fromJson method that returns the generic type
    final genericParams = clazz.genericParameters.map((p) => p.name).join(', ');
    final genericConstraints =
        clazz.genericParameters.map((p) => p.toString()).join(', ');
    buffer.writeln(
        '\n  static ${clazz.name}<$genericParams> fromJson<$genericConstraints>(Map<String, dynamic> map) {');
    buffer.writeln('    return ${clazz.name}<$genericParams>(');

    _buildFromJsonFields(buffer, clazz);

    buffer.writeln('    );');
    buffer.writeln('  }');
  }

  /// Build cached readValue variables for fromJson methods
  void _buildReadValueCacheVariables(StringBuffer buffer, ClassInfo clazz) {
    for (final field in clazz.fields) {
      if (field.jsonKey?.ignore == true ||
          field.name.isEmpty ||
          field.type.isEmpty ||
          field.type == 'dynamic' ||
          field.jsonKey?.readValue.isEmpty != false) {
        continue;
      }

      final jsonKeys = <String>[];
      if (field.jsonKey?.name.isNotEmpty == true) {
        jsonKeys.add(field.jsonKey!.name);
      } else {
        jsonKeys.add(field.name);
      }

      final readValue = field.jsonKey!.readValue;
      final readValueCall =
          readValue.startsWith('_') && !readValue.contains('.')
              ? '${clazz.name}.$readValue(map, \'${jsonKeys[0]}\')'
              : '$readValue(map, \'${jsonKeys[0]}\')';

      final cachedVarName = '${field.name}ReadValue';
      buffer.writeln('    final $cachedVarName = $readValueCall;');
    }
  }

  /// Build fromJson method for regular (non-generic) classes
  void _buildRegularFromJson(StringBuffer buffer, ClassInfo clazz) {
    buffer.writeln(
        '\n  static ${clazz.name} fromJson(Map<String, dynamic> map) {');

    // First, generate all cached readValue variables
    _buildReadValueCacheVariables(buffer, clazz);

    buffer.writeln('    return ${clazz.name}(');

    _buildFromJsonFields(buffer, clazz);

    buffer.writeln('    );');
    buffer.writeln('  }');
  }

  /// Build field assignments for fromJson methods
  void _buildFromJsonFields(StringBuffer buffer, ClassInfo clazz) {
    for (final field in clazz.fields) {
      if (field.jsonKey?.ignore == true ||
          field.name.isEmpty ||
          field.type.isEmpty ||
          field.type == 'dynamic' ||
          field.isFunction) {
        continue;
      }

      final jsonKey = field.jsonKey?.name.isNotEmpty == true
          ? field.jsonKey!.name
          : field.name;

      final jsonKeyInfo = field.jsonKey;

      String valueExpression;
      if (jsonKeyInfo != null && jsonKeyInfo.readValue.isNotEmpty) {
        final readValue = jsonKeyInfo.readValue;
        final readValueCall =
            readValue.startsWith('_') && !readValue.contains('.')
                ? '${clazz.name}.$readValue(map, \'$jsonKey\')'
                : '$readValue(map, \'$jsonKey\')';
        valueExpression = readValueCall;
      } else if (jsonKeyInfo != null && jsonKeyInfo.alternateNames.isNotEmpty) {
        final allKeys = [jsonKey, ...jsonKeyInfo.alternateNames];
        valueExpression = "(${allKeys.map((k) => "map['$k']").join(' ?? ')})";
      } else {
        valueExpression = "map['$jsonKey']";
      }

      final cleanType = field.type.replaceAll('?', '');
      final isNullable = field.type.endsWith('?');
      final customFromJson = jsonKeyInfo?.fromJson;
      final customConverter = jsonKeyInfo?.converter;

      String conversion;
      // Priority 1: Custom fromJson function (highest priority)
      if (customFromJson != null && customFromJson.isNotEmpty) {
        // Check if fromJsonFunc needs class prefix (for static methods starting with _)
        final fullFromJsonFunc =
            customFromJson.startsWith('_') && !customFromJson.contains('.')
                ? '${clazz.name}.$customFromJson'
                : customFromJson;
        if (isNullable) {
          conversion =
              '$valueExpression != null ? $fullFromJsonFunc($valueExpression) : null';
        } else {
          conversion = '$fullFromJsonFunc($valueExpression)';
        }
      }
      // Priority 2: Custom converter
      else if (customConverter != null && customConverter.isNotEmpty) {
        if (jsonKeyInfo != null && jsonKeyInfo.readValue.isNotEmpty) {
          // If readValue is used, check if the value is already the target type
          // If so, return it directly. Otherwise, use the converter.
          conversion =
              "((dynamic v) => v is $cleanType ? v : const $customConverter().fromJson(v))($valueExpression)";
        } else {
          conversion = "const $customConverter().fromJson($valueExpression)";
        }

        if (!isNullable) {
          conversion += ' as $cleanType';
        }
      } else if (['int', 'double', 'String', 'bool'].contains(cleanType)) {
        bool usedRequired = false;
        if (jsonKeyInfo == null ||
            (jsonKeyInfo.readValue.isEmpty &&
                jsonKeyInfo.alternateNames.isEmpty)) {
          if (field.isRequired && !isNullable && field.defaultValue.isEmpty) {
            conversion =
                "${_getSafeCasteUtil()}.readRequiredValue<$cleanType>(map, '$jsonKey')";
            usedRequired = true;
          } else {
            conversion =
                "${_getSafeCasteUtil()}.readValue<$cleanType>(map, '$jsonKey')";
          }
        } else {
          conversion =
              "${_getSafeCasteUtil()}.safeCast<$cleanType>($valueExpression)";
        }

        if (!isNullable && !usedRequired) {
          final defaultValue = field.defaultValue.isNotEmpty
              ? field.defaultValue
              : ({
                    'int': '0',
                    'double': '0.0',
                    'String': "''",
                    'bool': 'false',
                  }[cleanType] ??
                  'null');
          conversion += ' ?? $defaultValue';
        }
      } else if (field.isDateTime) {
        conversion =
            "const ${_dataforgeAnnotationPrefix}DefaultDateTimeConverter().fromJson($valueExpression)";
        if (!isNullable) {
          final defaultValue = field.defaultValue.isNotEmpty
              ? ' ?? ${field.defaultValue}'
              : ' ?? DateTime.fromMillisecondsSinceEpoch(0)';
          conversion += defaultValue;
        }
      } else if (field.isEnum || _isEnumType(cleanType)) {
        String stringValueExpr;
        if (jsonKeyInfo == null ||
            (jsonKeyInfo.readValue.isEmpty &&
                jsonKeyInfo.alternateNames.isEmpty)) {
          stringValueExpr =
              "${_getSafeCasteUtil()}.readValue<String>(map, '$jsonKey')";
        } else {
          stringValueExpr =
              "${_getSafeCasteUtil()}.safeCast<String>($valueExpression)";
        }
        conversion =
            "${_dataforgeAnnotationPrefix}DefaultEnumConverter($cleanType.values).fromJson($stringValueExpr)";
        if (!isNullable) {
          final defaultValue = field.defaultValue.isNotEmpty
              ? ' ?? ${field.defaultValue}'
              : ' ?? $cleanType.values.first';
          conversion += defaultValue;
        }
      } else if (cleanType.startsWith('List<')) {
        final innerType = cleanType.substring(5, cleanType.length - 1);
        final innerTypeClean = innerType.replaceAll('?', '').trim();
        final isPrimitive = [
              'int',
              'double',
              'num',
              'String',
              'bool',
              'dynamic',
              'Object',
              'DateTime'
            ].contains(innerTypeClean) ||
            innerTypeClean.startsWith('Map<') ||
            innerTypeClean.startsWith('List<');

        if (isPrimitive) {
          conversion =
              "($valueExpression as List<dynamic>?)?.cast<$innerType>()";
        } else {
          if (innerType.endsWith('?')) {
            conversion =
                "($valueExpression as List<dynamic>?)?.map((e) => e == null ? null : $innerTypeClean.fromJson(e as Map<String, dynamic>)).toList()";
          } else {
            conversion =
                "($valueExpression as List<dynamic>?)?.map((e) => $innerTypeClean.fromJson(e as Map<String, dynamic>)).toList()";
          }
        }

        if (!isNullable) {
          conversion += field.defaultValue.isNotEmpty
              ? ' ?? ${field.defaultValue}'
              : ' ?? []';
        }
      } else if (cleanType.startsWith('Map<')) {
        conversion = "$valueExpression as Map<String, dynamic>?";
        if (!isNullable && field.defaultValue.isNotEmpty) {
          conversion += ' ?? ${field.defaultValue}';
        }
      } else if (field.isDataforge || _hasFromJsonMethod(cleanType)) {
        String baseExpression;
        bool usedRequired = false;

        if (jsonKeyInfo != null && jsonKeyInfo.readValue.isNotEmpty) {
          final valParam = 'v';
          final castExpression = (isNullable || field.defaultValue.isNotEmpty)
              ? 'as $cleanType?'
              : 'as $cleanType';

          baseExpression =
              "((dynamic $valParam) { if ($valParam is $cleanType) return $valParam; if ($valParam is Map<String, dynamic>) return $cleanType.fromJson($valParam); return $valParam $castExpression; })($valueExpression)";
        } else {
          if (jsonKeyInfo == null ||
              (jsonKeyInfo.readValue.isEmpty &&
                  jsonKeyInfo.alternateNames.isEmpty)) {
            if (field.isRequired && !isNullable && field.defaultValue.isEmpty) {
              baseExpression =
                  "${_getSafeCasteUtil()}.readRequiredObject(map, '$jsonKey', $cleanType.fromJson)";
              usedRequired = true;
            } else {
              baseExpression =
                  "${_getSafeCasteUtil()}.readObject(map, '$jsonKey', $cleanType.fromJson)";
            }
          } else {
            baseExpression =
                "${_getSafeCasteUtil()}.parseObject($valueExpression, $cleanType.fromJson)";
          }
        }

        conversion = baseExpression;
        if (!isNullable && !usedRequired) {
          if (field.defaultValue.isNotEmpty) {
            conversion = "($baseExpression) ?? ${field.defaultValue}";
          } else {
            conversion = "($baseExpression)!";
          }
        }
      } else {
        conversion = "$valueExpression";
        if (!isNullable && field.defaultValue.isNotEmpty) {
          conversion += ' ?? ${field.defaultValue}';
        }
      }

      buffer.writeln("      ${field.name}: $conversion,");
    }
  }

  /// Check if a type has a fromJson method (heuristic: assume custom classes do)
  bool _hasFromJsonMethod(String type) {
    // Primitive types don't have fromJson
    const primitiveTypes = {
      'String',
      'int',
      'double',
      'bool',
      'num',
      'Object',
      'dynamic',
      'DateTime',
      'Duration',
      'Uri',
      'BigInt'
    };
    final cleanType = _removeGenericParameters(type.replaceAll('?', ''));
    if (primitiveTypes.contains(cleanType)) return false;
    if (cleanType.startsWith('List<') || cleanType.startsWith('Map<'))
      return false;
    // Assume other types (custom classes) have fromJson
    return true;
  }

  /// Recursively generate nested field accessors for deep copyWith operations
  void _generateNestedFieldAccessors(
    StringBuffer buffer,
    ClassInfo clazz,
    String genericParams,
    List<FieldInfo> validFields,
    List<String> fieldPath,
    ClassInfo rootClazz,
  ) {
    for (final field in validFields) {
      // Check if field type matches any parsed Dataforge class
      final nestedTypeName = field.type.replaceAll('?', '');
      final nestedClass = _findClassByName(nestedTypeName);

      if (nestedClass != null) {
        final currentPath = [...fieldPath, field.name];

        // Generate accessors for fields of the nested class
        for (final nestedField in nestedClass.fields) {
          final fullPath = [...currentPath, nestedField.name];
          final getterName = _buildFieldAccessorName(fullPath);
          final paramType = nestedField.type;

          buffer.writeln('\n  R $getterName($paramType value) {');
          _generateNestedCopyWithChainNew(
              buffer, currentPath, nestedField.name, field, rootClazz);
          buffer.writeln('  }');
        }

        // Recursively generate deeper accessors
        _generateNestedFieldAccessors(buffer, nestedClass, genericParams,
            nestedClass.fields, currentPath, rootClazz);
      }
    }
  }

  // Helper to find a ClassInfo by name
  ClassInfo? _findClassByName(String name) {
    for (final c in result.classes) {
      if (c.name == name) return c;
    }
    return null;
  }

  // Helper to build a combined field accessor name (e.g., user$address$street)
  // Uses $ separator to avoid conflicts with existing property names
  String _buildFieldAccessorName(List<String> path) {
    if (path.isEmpty) return '';
    return path.join('\$');
  }

  // Helper to generate the nested copyWith chain for the call method
  // Uses recursion to handle multi-level null checks
  void _generateNestedCopyWithChainNew(
      StringBuffer buffer,
      List<String> currentPath,
      String nestedFieldName,
      FieldInfo parentField,
      ClassInfo rootClazz) {
    buffer.write('    return call(');

    final rootFieldName = currentPath.first;

    // Build the value expression recursively
    final valueExpression = _buildNestedValueExpression(
        currentPath, nestedFieldName, '_instance', rootClazz, 0);

    buffer.writeln('      $rootFieldName: $valueExpression,');
    buffer.writeln('    );');
  }

  String _buildNestedValueExpression(List<String> path, String targetField,
      String currentAccess, ClassInfo currentClass, int index) {
    final fieldName = path[index];
    final field = currentClass.fields.firstWhere((f) => f.name == fieldName,
        orElse: () => FieldInfo(
            name: fieldName,
            type: 'dynamic',
            isFinal: false,
            isFunction: false,
            isRecord: false,
            defaultValue: ''));
    final isLast = index == path.length - 1;

    final access = '$currentAccess.$fieldName';
    final safeAccess = field.type.endsWith('?') ? '$access!' : access;

    String nextValue;
    if (isLast) {
      nextValue = '$safeAccess.copyWith($targetField: value)';
    } else {
      final nextClassName = field.type.replaceAll('?', '');
      final nextClass = _findClassByName(nextClassName);

      if (nextClass == null) {
        nextValue = 'value';
      } else {
        nextValue = _buildNestedValueExpression(
            path, targetField, access, nextClass, index + 1);
      }
      final nextFieldName = path[index + 1];
      nextValue = '$safeAccess.copyWith($nextFieldName: $nextValue)';
    }

    if (field.type.endsWith('?')) {
      return '($access == null ? $access : $nextValue)';
    } else {
      return nextValue;
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
