import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;

import 'model.dart';

/// Parse Dart files and extract DataClass annotation information
///
/// This class is responsible for:
/// - Parsing Dart source code AST
/// - Extracting @DataClass and @JsonKey annotations
/// - Building class information models
///
/// Usage example:
/// ```dart
/// final parser = Parser('/path/to/file.dart');
/// final result = parser.parseDartFile();
/// ```
class Parser {
  /// Path to the Dart file to be parsed
  final String path;

  /// Optional output directory
  final String? outputDirectory;

  /// Cache for frequently used calculation results
  final Map<String, bool> _annotationCache = {};

  /// Create parser instance
  ///
  /// [path] must be a valid Dart file path
  /// [outputDirectory] optional output directory
  Parser(this.path, {this.outputDirectory});

  /// Check if it's a DataClass or Dataforge annotation
  bool _isDataClassAnnotation(String name) {
    return _annotationCache.putIfAbsent(name, () {
      final cleanName = name.contains('.') ? name.split('.').last : name;
      return cleanName == 'DataClass' ||
          cleanName == 'dataClass' ||
          cleanName == 'Dataforge' ||
          cleanName == 'dataforge';
    });
  }

  /// Parse Dart file and return parse result
  ///
  /// Returns [ParseResult] if file contains classes with DataClass annotation
  /// Returns `null` if file doesn't contain relevant annotations or parsing fails
  ParseResult? parseDartFile() {
    final file = File(path);
    if (path.endsWith(".data.dart")) return null;

    if (!file.existsSync()) {
      print('Error: File does not exist: $path');
      return null;
    }

    final content = file.readAsStringSync();
    late ParseStringResult parseRes;

    try {
      parseRes = parseString(content: content);
    } catch (e) {
      print('Error parsing file $path: $e');
      return null;
    }

    if (parseRes.errors.isNotEmpty) {
      print('Parse errors in $path:');
      for (final error in parseRes.errors) {
        print('  ${error.message}');
      }
      return null;
    }

    // Parsing file silently
    final classes = <ClassInfo>[];
    final imports = <ImportInfo>[];
    final unit = parseRes.unit;

    // Parse import statements
    for (var directive in unit.directives) {
      if (directive is ImportDirective) {
        final uri = directive.uri.stringValue;
        if (uri != null) {
          String? alias;
          if (directive.asKeyword != null && directive.prefix != null) {
            alias = directive.prefix!.name;
          }

          final showCombinators = <String>[];
          final hideCombinators = <String>[];

          for (var combinator in directive.combinators) {
            if (combinator is ShowCombinator) {
              showCombinators.addAll(combinator.shownNames.map((e) => e.name));
            } else if (combinator is HideCombinator) {
              hideCombinators.addAll(combinator.hiddenNames.map((e) => e.name));
            }
          }

          imports.add(ImportInfo(
            uri: uri,
            alias: alias,
            isDeferred: directive.deferredKeyword != null,
            showCombinators: showCombinators,
            hideCombinators: hideCombinators,
          ));
        }
      }
    }

    for (var declaration in unit.declarations) {
      if (declaration is ClassDeclaration) {
        final meta = declaration.metadata.firstWhereOrNull((e) {
          final annotationName = e.name.name;
          return _isDataClassAnnotation(annotationName);
        });

        if (meta == null) continue;

        final className = declaration.name.lexeme;

        // Validate class name validity
        if (className.isEmpty || className.trim().isEmpty) {
          print('Warning: Skipping class with empty name');
          continue;
        }

        // Ensure class name is a valid Dart identifier
        if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(className)) {
          print('Warning: Skipping class with invalid name "$className"');
          continue;
        }

        // Parse generic parameters
        final genericParameters = <GenericParameter>[];
        if (declaration.typeParameters != null) {
          for (final typeParam in declaration.typeParameters!.typeParameters) {
            final name = typeParam.name.lexeme;
            final bound = typeParam.bound?.toSource();
            genericParameters.add(GenericParameter(name, bound));
          }
        }

        final fields = <FieldInfo>[];
        final defaultValueMap = <String, String>{};
        // Found class silently

        bool? fromMap;
        bool? includeFromJson;
        bool? includeToJson;
        bool? chainedCopyWith;
        String mixinName = "";
        final arguments = meta.arguments?.arguments ?? [];

        for (var value in arguments) {
          if (value is NamedExpression) {
            final name = value.name.label.name;
            final expressionSource = value.expression.toSource();

            switch (name) {
              case "fromMap":
                // Legacy support: fromMap controls both includeFromJson/toJson
                // Global config no longer overrides these; default to true
                if (expressionSource == "null") {
                  fromMap = true;
                } else {
                  fromMap = expressionSource == "true";
                }
                break;
              case "includeFromJson":
                // If null, default to true regardless of global config
                if (expressionSource == "null") {
                  includeFromJson = true;
                } else {
                  includeFromJson = expressionSource == "true";
                }
                break;
              case "includeToJson":
                // If null, default to true regardless of global config
                if (expressionSource == "null") {
                  includeToJson = true;
                } else {
                  includeToJson = expressionSource == "true";
                }
                break;
              case "chainedCopyWith":
                // If null, default to true (matches annotation default)
                if (expressionSource == "null") {
                  chainedCopyWith = true;
                } else {
                  chainedCopyWith = expressionSource == "true";
                }
                break;
              case "name":
                mixinName =
                    expressionSource.replaceAll('"', "").replaceAll("'", "");
                break;
              // fromMapName and toMapName are no longer supported
              // Methods are now fixed as 'fromJson' and 'toJson'
            }
          }
        }

        // Method names are now fixed as 'fromJson' and 'toJson'

        // Parse default values of constructor parameters
        for (final member
            in declaration.members.whereType<ConstructorDeclaration>()) {
          if (member.factoryKeyword == null) {
            // Primary constructor
            for (var parameter in member.parameters.parameters) {
              if (parameter is DefaultFormalParameter &&
                  parameter.defaultValue != null) {
                final paramName = parameter.name?.lexeme;
                final defaultValue = parameter.defaultValue?.toSource();
                if (paramName != null && defaultValue != null) {
                  defaultValueMap[paramName] = defaultValue;
                }
              }
            }
          }
        }

        // Parse fields
        for (final member in declaration.members) {
          if (member is FieldDeclaration && !member.isStatic) {
            final isFunction = member.fields.type is GenericFunctionType;
            final isRecord = member.fields.type is RecordTypeAnnotation;
            final type = member.fields.type?.toSource() ?? 'dynamic';
            JsonKeyInfo? jsonKeyInfo;

            // Parse JsonKey annotation and @ignore annotation
            for (var annotation in member.metadata) {
              final annotationName = annotation.name.name;
              final cleanName = annotationName.contains(".")
                  ? annotationName.split(".").last
                  : annotationName;

              // Handle @ignore annotation
              if (cleanName == "ignore") {
                jsonKeyInfo = JsonKeyInfo(
                  name: "",
                  readValue: "",
                  ignore: true,
                  alternateNames: [],
                  converter: "",
                  includeIfNull: null,
                );
              }
              // Handle @JsonKey annotation
              else if (cleanName == "JsonKey") {
                jsonKeyInfo = JsonKeyInfo(
                  name: "",
                  readValue: "",
                  ignore: false,
                  alternateNames: [],
                  converter: "",
                  includeIfNull: null,
                );

                final arguments = annotation.arguments?.arguments ?? [];

                for (var element in arguments) {
                  if (element is NamedExpression) {
                    final paramName = element.name.label.name;
                    final expressionSource = element.expression.toSource();

                    switch (paramName) {
                      case "name":
                        jsonKeyInfo = jsonKeyInfo!.copyWith(
                          name: expressionSource
                              .replaceAll('"', "")
                              .replaceAll("'", ""),
                        );
                        break;
                      case "readValue":
                        jsonKeyInfo = jsonKeyInfo!.copyWith(
                          readValue: expressionSource,
                        );
                        break;
                      case "ignore":
                        jsonKeyInfo = jsonKeyInfo!.copyWith(
                          ignore: expressionSource == "true",
                        );
                        break;
                      case "alternateNames":
                        try {
                          // Safer parsing of alternateNames
                          final cleanSource = expressionSource.replaceAll(
                              RegExp(r'[\[\]"\s]'), '');
                          final names = cleanSource
                              .split(',')
                              .where((e) => e.isNotEmpty)
                              .map((e) => e.replaceAll("'", ""))
                              .toList();

                          jsonKeyInfo = jsonKeyInfo!.copyWith(
                            alternateNames: names,
                          );
                        } catch (e) {
                          print(
                              'Warning: Failed to parse alternateNames for ${member.fields.variables.first.name.lexeme}: $e');
                        }
                        break;
                      case "converter":
                        jsonKeyInfo = jsonKeyInfo!.copyWith(
                          converter: expressionSource,
                        );
                        break;

                      case "includeIfNull":
                        jsonKeyInfo = jsonKeyInfo!.copyWith(
                          includeIfNull: expressionSource == "true",
                        );
                        break;
                      case "fromJson":
                        jsonKeyInfo = jsonKeyInfo!.copyWith(
                          fromJson: expressionSource,
                        );
                        break;
                      case "toJson":
                        jsonKeyInfo = jsonKeyInfo!.copyWith(
                          toJson: expressionSource,
                        );
                        break;
                    }
                  }
                }
              }
            }

            // Add field information
            for (final varDecl in member.fields.variables) {
              if (!varDecl.isConst) {
                final name = varDecl.name.lexeme;

                // Validate field validity
                if (name.isEmpty) {
                  print('Warning: Skipping field with empty name');
                  continue;
                }

                if (type.isEmpty || type.trim().isEmpty) {
                  print('Warning: Skipping field "$name" with empty type');
                  continue;
                }

                // Skip invalid types
                if (type == 'void') {
                  print(
                      'Warning: Skipping field "$name" with invalid type "$type"');
                  continue;
                }

                fields.add(
                  FieldInfo(
                    name: name,
                    type: type,
                    isFinal: varDecl.isFinal,
                    isFunction: isFunction,
                    jsonKey: jsonKeyInfo,
                    isRecord: isRecord,
                    defaultValue: defaultValueMap[name] ?? "",
                  ),
                );
              }
            }
          }
        }

        // Validate ignored fields
        for (final field in fields) {
          if (field.jsonKey?.ignore == true) {
            final isNullable = field.type.endsWith('?');
            final hasDefaultValue = field.defaultValue.isNotEmpty;

            if (!isNullable && !hasDefaultValue) {
              print(
                  'Warning: Field "${field.name}" in class "$className" is marked as @JsonKey(ignore: true) '
                  'but is not nullable and has no default value. '
                  'Ignored fields must be either nullable (${field.type}?) or have a default value in the constructor.');
            }
          }
        }

        // Handle backward compatibility: if new parameters are not specified, use fromMap parameter or configuration defaults
        final finalIncludeFromJson = includeFromJson ?? fromMap ?? true;
        final finalIncludeToJson = includeToJson ?? fromMap ?? true;
        final finalChainedCopyWith = chainedCopyWith ?? true;

        classes.add(
          ClassInfo(
            name: className,
            mixinName: mixinName.isEmpty ? '_$className' : mixinName,
            fields: fields,
            includeFromJson: finalIncludeFromJson,
            includeToJson: finalIncludeToJson,
            genericParameters: genericParameters,
            chainedCopyWith: finalChainedCopyWith,
          ),
        );
      }
    }

    if (classes.isEmpty) return null;

    final baseName = p.basename(path);
    final partOf = "part of '$baseName';";

    // If output directory is specified, use that directory; otherwise use original file's directory
    final String outputPath;
    if (outputDirectory != null) {
      final fileName = p.basenameWithoutExtension(path);
      outputPath = p.join(outputDirectory!, '$fileName.data.dart');
    } else {
      outputPath = path.replaceAll('.dart', '.data.dart');
    }

    return ParseResult(outputPath, partOf, classes, imports);
  }
}
