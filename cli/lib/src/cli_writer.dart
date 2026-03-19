import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dataforge_base/src/model.dart';
import 'package:dataforge_base/src/type_utils.dart';
import 'package:dataforge_base/src/writer.dart';
import 'package:path/path.dart' as p;

class CliWriter {
  static const String _generatedFileIgnoreLine =
      '// ignore_for_file: prefer_const_constructors, prefer_single_quotes, '
      'unnecessary_cast, unnecessary_non_null_assertion, unused_element';

  final ParseResult result;
  final String? projectRoot;
  final bool debugMode;
  final String? _dataforgeAnnotationPrefix;
  late final Set<String> _allEnumTypes;
  late final Set<String> _allJsonModelTypes;

  CliWriter(this.result, {this.projectRoot, this.debugMode = false})
      : _dataforgeAnnotationPrefix = _getDataforgeAnnotationPrefix(result) {
    final scannedTypes = _scanProjectTypes();
    _allEnumTypes = scannedTypes.enums;
    _allJsonModelTypes = scannedTypes.jsonModels;
  }

  /// Scan project Dart files once at init to build type metadata caches.
  _ScannedTypes _scanProjectTypes() {
    final enumTypes = <String>{};
    final jsonModelTypes = <String>{};
    final searchDir =
        projectRoot != null ? Directory(projectRoot!) : Directory.current;
    if (!searchDir.existsSync()) {
      return _ScannedTypes(enumTypes, jsonModelTypes);
    }

    final dartFiles = searchDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) =>
            file.path.endsWith('.dart') && !file.path.endsWith('.data.dart'))
        .toList();

    for (final file in dartFiles) {
      try {
        final content = file.readAsStringSync();
        final parseResult = parseString(content: content, path: file.path);
        if (parseResult.errors.isNotEmpty) {
          continue;
        }

        for (final declaration in parseResult.unit.declarations) {
          if (declaration is EnumDeclaration) {
            enumTypes.add(declaration.name.lexeme);
          } else if (declaration is ClassDeclaration) {
            final className = declaration.name.lexeme;
            final hasDataforgeAnnotation = declaration.metadata.any((annotation) {
              final name = annotation.name.name;
              return _isDataClassAnnotation(name);
            });
            final hasFromJsonFactory = declaration.members.any((member) {
              if (member is ConstructorDeclaration) {
                return member.factoryKeyword != null &&
                    member.name?.lexeme == 'fromJson';
              }
              if (member is MethodDeclaration) {
                return member.isStatic && member.name.lexeme == 'fromJson';
              }
              return false;
            });

            if (hasDataforgeAnnotation || hasFromJsonFactory) {
              jsonModelTypes.add(className);
            }
          }
        }
      } catch (_) {}
    }

    return _ScannedTypes(enumTypes, jsonModelTypes);
  }

  Future<String> writeCodeAsync() async {
    final writeStartTime = DateTime.now();
    if (debugMode) {
      print(
          '[PERF] $writeStartTime: Starting writeCodeAsync() for ${result.outputPath}');
    }

    // Pre-process classes to inject prefix and heuristics results
    final updatedClasses = <ClassInfo>[];
    for (final clazz in result.classes) {
      final updatedFields = <FieldInfo>[];
      for (final field in clazz.fields) {
        final cleanType =
            _removeGenericParameters(field.type.replaceAll('?', ''));

        bool isEnum = field.isEnum;
        if (!isEnum) {
          isEnum = _isEnumType(cleanType);
        }

        bool isDataforge = field.isDataforge;
        if (!isDataforge) {
          isDataforge = _isJsonModelType(cleanType);
        }

        bool isInnerEnum = field.isInnerEnum;
        if (!isInnerEnum &&
            (field.type.startsWith('List<') ||
                field.type.startsWith('Set<') ||
                field.type.startsWith('Map<'))) {
          final innerType =
              _extractLastTypeArgument(field.type).replaceAll('?', '').trim();
          isInnerEnum = _isEnumType(innerType);
        }

        bool isInnerDataforge = field.isInnerDataforge;
        if (!isInnerDataforge &&
            (field.type.startsWith('List<') ||
                field.type.startsWith('Set<') ||
                field.type.startsWith('Map<'))) {
          final innerType =
              _extractLastTypeArgument(field.type).replaceAll('?', '').trim();
          isInnerDataforge = _isJsonModelType(innerType);
        }

        updatedFields.add(field.copyWith(
          isEnum: isEnum,
          isDataforge: isDataforge,
          isInnerEnum: isInnerEnum,
          isInnerDataforge: isInnerDataforge,
        ));
      }

      updatedClasses.add(clazz.copyWith(
        fields: updatedFields,
        dataforgePrefix: _dataforgeAnnotationPrefix,
      ));
    }

    final updatedResult = ParseResult(
        result.outputPath, result.partOf, updatedClasses, result.imports,
        primaryClassName: result.primaryClassName);

    // Generate content using shared GeneratorWriter
    final generator = GeneratorWriter(updatedResult);
    final buffer = StringBuffer();

    buffer.writeln('// Generated by data class generator');
    buffer.writeln('// DO NOT MODIFY BY HAND\n');
    buffer.writeln('$_generatedFileIgnoreLine\n');
    buffer.writeln(result.partOf);
    buffer.writeln();

    final generatedContent = generator.generate();
    buffer.write(generatedContent);

    final fileWriteStartTime = DateTime.now();

    final file = File(result.outputPath);
    await file.create(recursive: true);
    await file.writeAsString(buffer.toString());

    final fileWriteEndTime = DateTime.now();
    if (debugMode) {
      print(
          '[PERF] $fileWriteEndTime: File write completed in ${fileWriteEndTime.difference(fileWriteStartTime).inMilliseconds}ms');
    }

    await _processOriginalFilesAsync(
      requiresCollectionImport: generatedContent.contains('DeepCollectionEquality'),
    );

    return result.outputPath;
  }

  /// Get the prefix for dataforge_annotation based on import statements
  static String? _getDataforgeAnnotationPrefix(ParseResult result) {
    for (final import in result.imports) {
      if (import.uri ==
              'package:dataforge_annotation/dataforge_annotation.dart' &&
          import.alias != null) {
        return import.alias;
      }
    }
    return null; // No prefix needed if no alias is used
  }

  /// Check if a type is an enum using the pre-scanned enum type cache.
  bool _isEnumType(String type) {
    final cleanType = _removeGenericParameters(type.replaceAll('?', ''));
    return _allEnumTypes.contains(cleanType);
  }

  bool _isDataClassAnnotation(String name) {
    final cleanName = name.contains('.') ? name.split('.').last : name;
    return cleanName == 'DataClass' ||
        cleanName == 'dataClass' ||
        cleanName == 'Dataforge' ||
        cleanName == 'dataforge';
  }

  bool _isJsonModelType(String type) {
    final cleanType = _removeGenericParameters(type.replaceAll('?', ''));
    return _allJsonModelTypes.contains(cleanType);
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

  String _extractLastTypeArgument(String type) =>
      TypeUtils.extractLastTypeArgument(type);

  /// Process original files asynchronously
  Future<void> _processOriginalFilesAsync({
    required bool requiresCollectionImport,
  }) async {
    // Infer original file path from output path
    final originalFilePath =
        result.outputPath.replaceAll('.data.dart', '.dart');

    await _batchProcessOriginalFileAsync(
      originalFilePath,
      requiresCollectionImport: requiresCollectionImport,
    );
  }

  /// Batch process all file modifications in a single read-write operation (async)
  Future<void> _batchProcessOriginalFileAsync(
    String filePath, {
    required bool requiresCollectionImport,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return;

      final content = await file.readAsString();
      final lines = content.split('\n');
      bool modified = false;

      final dataFileName = p.basename(result.outputPath);

      // Step 1: Add collection import if needed
      if (requiresCollectionImport && !_hasCollectionImport(lines)) {
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
      }
    } catch (e) {
      if (debugMode) print('Error in batch processing $filePath: $e');
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
    final insertIndex = _findImportInsertIndex(lines);
    lines.insert(
      insertIndex,
      "import 'package:collection/collection.dart';",
    );
  }

  /// Check if part declaration exists in lines
  bool _hasPartDeclarationInLines(List<String> lines, String dataFileName) {
    final partDeclaration1 = "part '$dataFileName';";
    final partDeclaration2 = 'part "$dataFileName";';

    return lines.any((line) {
      final trimmed = line.trim();
      return trimmed == partDeclaration1 || trimmed == partDeclaration2;
    });
  }

  /// Insert part declaration into lines
  void _insertPartDeclaration(List<String> lines, String dataFileName) {
    final partDeclaration = "part '$dataFileName';";
    int insertIndex = _findPartInsertIndex(lines);
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
      // Find class declaration line
      final classPattern =
          RegExp(r'\bclass\s+' + RegExp.escape(className) + r'\b');
      if (classPattern.hasMatch(lines[i]) && !lines[i].contains('mixin')) {
        int endIndex = i;
        while (endIndex < lines.length && !lines[endIndex].contains('{')) {
          endIndex++;
        }
        if (endIndex >= lines.length) {
          return false;
        }

        final indent = RegExp(r'^\s*').firstMatch(lines[i])!.group(0)!;
        final header = lines.sublist(i, endIndex + 1).join('\n');
        final normalizedHeader = header.replaceAll(RegExp(r'\s+'), ' ').trim();
        final genericPart = _extractGenericPart(normalizedHeader, className);
        final mixinName = '_$className$genericPart';
        if (normalizedHeader.contains(mixinName)) {
          return false;
        }

        String updatedHeader = normalizedHeader;
        if (updatedHeader.contains(' with ')) {
          if (updatedHeader.contains(' implements ')) {
            updatedHeader = updatedHeader.replaceFirst(
              ' implements ',
              ', $mixinName implements ',
            );
          } else {
            updatedHeader = updatedHeader.replaceFirst('{', ', $mixinName {');
          }
        } else if (updatedHeader.contains(' implements ')) {
          updatedHeader = updatedHeader.replaceFirst(
            ' implements ',
            ' with $mixinName implements ',
          );
        } else {
          updatedHeader = updatedHeader.replaceFirst('{', ' with $mixinName {');
        }

        lines.replaceRange(
          i,
          endIndex + 1,
          <String>['$indent$updatedHeader'],
        );
        return true;
      }
    }
    return false;
  }

  int _findImportInsertIndex(List<String> lines) {
    int insertIndex = 0;
    for (int i = 0; i < lines.length; i++) {
      final trimmed = lines[i].trim();
      if (trimmed.isEmpty || trimmed.startsWith('//') || trimmed.startsWith('/*')) {
        continue;
      }
      if (trimmed.startsWith('library ')) {
        insertIndex = i + 1;
        continue;
      }
      if (trimmed.startsWith('import ') || trimmed.startsWith('export ')) {
        insertIndex = i + 1;
        continue;
      }
      if (trimmed.startsWith('part ') && !trimmed.startsWith('part of ')) {
        return i;
      }
      break;
    }
    return insertIndex;
  }

  int _findPartInsertIndex(List<String> lines) {
    int insertIndex = 0;
    for (int i = 0; i < lines.length; i++) {
      final trimmed = lines[i].trim();
      if (trimmed.isEmpty || trimmed.startsWith('//') || trimmed.startsWith('/*')) {
        continue;
      }
      if (trimmed.startsWith('library ') ||
          trimmed.startsWith('import ') ||
          trimmed.startsWith('export ') ||
          (trimmed.startsWith('part ') && !trimmed.startsWith('part of '))) {
        insertIndex = i + 1;
        continue;
      }
      break;
    }
    return insertIndex;
  }

  String _extractGenericPart(String header, String className) {
    final classToken = 'class $className';
    final classIndex = header.indexOf(classToken);
    if (classIndex == -1) return '';

    int index = classIndex + classToken.length;
    while (index < header.length && header[index].trim().isEmpty) {
      index++;
    }
    if (index >= header.length || header[index] != '<') {
      return '';
    }

    int depth = 0;
    for (int i = index; i < header.length; i++) {
      final char = header[i];
      if (char == '<') {
        depth++;
      } else if (char == '>') {
        depth--;
        if (depth == 0) {
          return header.substring(index, i + 1);
        }
      }
    }
    return '';
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
}

class _ScannedTypes {
  final Set<String> enums;
  final Set<String> jsonModels;

  const _ScannedTypes(this.enums, this.jsonModels);
}
