// @author luwenjie on 2026/01/17 14:37:53

import 'package:collection/collection.dart';
import 'circular_dependency_detector.dart';
import 'exceptions.dart';
import 'logger.dart';
import 'model.dart';
import 'type_utils.dart';

/// Code writer for generating data class code
///
/// This writer generates:
/// - Mixin with abstract fields
/// - copyWith methods (traditional or chained)
/// - Equality operators (==, hashCode)
/// - toString method
/// - fromJson/toJson methods
class GeneratorWriter {
  final ParseResult result;

  GeneratorWriter(this.result);

  String _getPrefix(ClassInfo clazz) =>
      clazz.dataforgePrefix != null ? '${clazz.dataforgePrefix}.' : '';

  List<String> _splitTopLevelTypeArguments(String typeArguments) =>
      TypeUtils.splitTopLevelTypeArguments(typeArguments);

  /// Generate the complete code output
  String generate() {
    final buffer = StringBuffer();

    // Detect circular dependencies
    final detector = CircularDependencyDetector();
    for (final clazz in result.classes) {
      detector.addClass(clazz);
    }
    final cycles = detector.detectCycles();
    if (cycles.isNotEmpty) {
      final warning = CircularDependencyDetector.formatCycleWarning(cycles);
      DataforgeLogger.warning(warning);
    }

    // Generate code for each class
    for (final clazz in result.classes) {
      if (result.primaryClassName != null &&
          clazz.name != result.primaryClassName) {
        continue;
      }
      // Validate class information
      if (clazz.name.isEmpty || clazz.mixinName.isEmpty) {
        DataforgeLogger.warning(
          'Skipping class with empty name or mixinName: ${clazz.name}',
        );
        continue;
      }

      // Generate generic parameters string with bounds
      final genericParams = clazz.genericParameters.isNotEmpty
          ? '<${clazz.genericParameters.map((p) => p.toString()).join(', ')}>'
          : '';

      // Generate mixin
      buffer.writeln('mixin ${clazz.mixinName}$genericParams {');

      // Generate abstract fields
      for (final field in clazz.fields) {
        if (field.name.isEmpty ||
            field.type.isEmpty ||
            field.type == 'dynamic') {
          DataforgeLogger.warning(
            'Skipping invalid field: name="${field.name}", type="${field.type}"',
          );
          continue;
        }
        buffer.writeln('  abstract final ${field.type} ${field.name};');
      }

      // Generate methods
      final validFields = clazz.fields
          .where(
            (field) =>
                field.name.isNotEmpty &&
                field.type.isNotEmpty &&
                field.type != 'dynamic' &&
                !field.isFunction,
          )
          .toList();

      _buildCopyWith(buffer, clazz, genericParams, validFields);
      _buildEquality(buffer, clazz, validFields);
      _buildHashCode(buffer, clazz, validFields);
      _buildToString(buffer, clazz, validFields);

      if (clazz.includeToJson) {
        _buildToJson(buffer, clazz, validFields);
      }

      if (clazz.includeFromJson) {
        _buildFromJson(buffer, clazz, genericParams, validFields);
      }

      buffer.writeln('}');
      buffer.writeln();

      // Generate chained copyWith helper class if needed
      if (clazz.deepCopyWith) {
        _buildChainedCopyWithHelperClass(
          buffer,
          clazz,
          genericParams,
          validFields,
        );
      }
    }

    return buffer.toString();
  }

  /// Build copyWith method
  void _buildCopyWith(
    StringBuffer buffer,
    ClassInfo clazz,
    String genericParams,
    List<FieldInfo> validFields,
  ) {
    if (clazz.deepCopyWith) {
      // Chained copyWith style
      final genericArgs = genericParams.isEmpty
          ? '<${clazz.name}>'
          : genericParams.replaceFirst('>', ', ${clazz.name}$genericParams>');
      buffer.writeln("  @pragma('vm:prefer-inline')");
      buffer.writeln(
        '  ${clazz.name}CopyWith$genericArgs get copyWith => ${clazz.name}CopyWith$genericArgs(this);',
      );
    } else {
      // Traditional copyWith style
      _buildTraditionalCopyWith(buffer, clazz, genericParams, validFields);
    }
    buffer.writeln();
  }

  /// Build traditional copyWith method
  void _buildTraditionalCopyWith(
    StringBuffer buffer,
    ClassInfo clazz,
    String genericParams,
    List<FieldInfo> validFields,
  ) {
    buffer.writeln("  @pragma('vm:prefer-inline')");
    buffer.writeln('  ${clazz.name}$genericParams copyWith({');
    for (final field in validFields) {
      _writeParameter(buffer, field, clazz);
    }
    buffer.writeln('  }) {');
    buffer.writeln('    return ${clazz.name}(');
    for (final field in validFields) {
      _writeAssignment(buffer, field, 'this', clazz);
    }
    buffer.writeln('    );');
    buffer.writeln('  }');
  }

  /// Build a type cast expression for copyWith method
  ///
  /// All types use SafeCasteUtil.copyWithCast/copyWithCastNullable for safe
  /// casting with error reporting via DataforgeConfig.reportCopyWithError.
  String _buildTypeCastExpression(
    String variable,
    String type,
    String fieldName,
    ClassInfo? clazz, {
    String instanceReference = '_instance',
  }) {
    final cleanType = type.replaceAll('?', '').trim();
    final isNullable = type.endsWith('?');

    if (cleanType.startsWith('List<')) {
      final innerType = cleanType.substring(5, cleanType.length - 1);
      if (isNullable) {
        return '${_getPrefix(clazz!)}SafeCasteUtil.copyWithCastNullableList<$innerType>($variable, \'$fieldName\', $instanceReference.$fieldName)';
      } else {
        return '${_getPrefix(clazz!)}SafeCasteUtil.copyWithCastList<$innerType>($variable, \'$fieldName\', $instanceReference.$fieldName)';
      }
    } else if (cleanType.startsWith('Set<')) {
      final innerType = cleanType.substring(4, cleanType.length - 1);
      if (isNullable) {
        return '${_getPrefix(clazz!)}SafeCasteUtil.copyWithCastNullableSet<$innerType>($variable, \'$fieldName\', $instanceReference.$fieldName)';
      } else {
        return '${_getPrefix(clazz!)}SafeCasteUtil.copyWithCastSet<$innerType>($variable, \'$fieldName\', $instanceReference.$fieldName)';
      }
    } else if (cleanType.startsWith('Map<')) {
      final innerTypes = cleanType.substring(4, cleanType.length - 1);
      final parts = _splitTopLevelTypeArguments(innerTypes);
      final keyType = parts.first.trim();
      final valueType = parts.last.trim();
      if (isNullable) {
        return '${_getPrefix(clazz!)}SafeCasteUtil.copyWithCastNullableMap<$keyType, $valueType>($variable, \'$fieldName\', $instanceReference.$fieldName)';
      } else {
        return '${_getPrefix(clazz!)}SafeCasteUtil.copyWithCastMap<$keyType, $valueType>($variable, \'$fieldName\', $instanceReference.$fieldName)';
      }
    } else if (cleanType == 'double') {
      final prefix = clazz != null ? _getPrefix(clazz) : '';
      if (isNullable) {
        return '${prefix}SafeCasteUtil.copyWithCastNullable<double>($variable, \'$fieldName\', $instanceReference.$fieldName)';
      } else {
        return '${prefix}SafeCasteUtil.copyWithCast<double>($variable, \'$fieldName\', $instanceReference.$fieldName)';
      }
    } else if (cleanType == 'int') {
      final prefix = clazz != null ? _getPrefix(clazz) : '';
      if (isNullable) {
        return '${prefix}SafeCasteUtil.copyWithCastNullable<int>($variable, \'$fieldName\', $instanceReference.$fieldName)';
      } else {
        return '${prefix}SafeCasteUtil.copyWithCast<int>($variable, \'$fieldName\', $instanceReference.$fieldName)';
      }
    } else if (cleanType == 'String') {
      final prefix = clazz != null ? _getPrefix(clazz) : '';
      if (isNullable) {
        return '${prefix}SafeCasteUtil.copyWithCastNullable<String>($variable, \'$fieldName\', $instanceReference.$fieldName)';
      } else {
        return "${prefix}SafeCasteUtil.copyWithCast<String>($variable, '$fieldName', $instanceReference.$fieldName)";
      }
    } else if (cleanType == 'bool') {
      final prefix = clazz != null ? _getPrefix(clazz) : '';
      if (isNullable) {
        return '${prefix}SafeCasteUtil.copyWithCastNullable<bool>($variable, \'$fieldName\', $instanceReference.$fieldName)';
      } else {
        return '${prefix}SafeCasteUtil.copyWithCast<bool>($variable, \'$fieldName\', $instanceReference.$fieldName)';
      }
    } else {
      // For custom types, use SafeCasteUtil.copyWithCast to catch and report errors
      final prefix = clazz != null ? _getPrefix(clazz) : '';
      if (isNullable) {
        return '${prefix}SafeCasteUtil.copyWithCastNullable<$cleanType>($variable, \'$fieldName\', $instanceReference.$fieldName)';
      } else {
        // For non-nullable custom types, use copyWithCast and provide fallback
        // We use _instance.$fieldName as the default value to return if casting fails
        return '${prefix}SafeCasteUtil.copyWithCast<$cleanType>($variable, \'$fieldName\', $instanceReference.$fieldName)';
      }
    }
  }

  /// Build chained copyWith helper class
  void _buildChainedCopyWithHelperClass(
    StringBuffer buffer,
    ClassInfo clazz,
    String genericParams,
    List<FieldInfo> validFields,
  ) {
    final copyWithClassName = '${clazz.name}CopyWith';
    final returnType = 'R';
    final genericParamsWithR = genericParams.isEmpty
        ? '<$returnType>'
        : genericParams.replaceFirst('>', ', $returnType>');

    buffer.writeln('class $copyWithClassName$genericParamsWithR {');
    buffer.writeln('  final ${clazz.mixinName}$genericParams _instance;');
    buffer.writeln(
      '  final $returnType Function(${clazz.name}$genericParams)? _then;',
    );
    buffer.writeln('  // ignore: library_private_types_in_public_api');
    buffer.writeln('  $copyWithClassName(this._instance, [this._then]);');

    buffer.writeln();
    buffer.writeln("  @pragma('vm:prefer-inline')");
    buffer.writeln('  R call({');
    // Use Object? with sentinel default for all parameters
    for (final field in validFields) {
      buffer.writeln(
        '    Object? ${field.name} = ${_getPrefix(clazz)}dataforgeUndefined,',
      );
    }
    buffer.writeln('  }) {');
    buffer.writeln('    final res = ${clazz.name}$genericParams(');
    for (final field in validFields) {
      // Use sentinel check to distinguish null from omitted
      final castExpr =
          _buildTypeCastExpression(field.name, field.type, field.name, clazz);
      if (castExpr.contains('SafeCasteUtil')) {
        buffer.writeln(
          '      ${field.name}: $castExpr,',
        );
      } else {
        buffer.writeln(
          '      ${field.name}: (${field.name} == ${_getPrefix(clazz)}dataforgeUndefined ? _instance.${field.name} : $castExpr),',
        );
      }
    }
    buffer.writeln('    );');
    buffer.writeln('    return (_then != null ? _then!(res) : res as R);');
    buffer.writeln('  }');
    buffer.writeln();
    // Generate single-field update methods
    for (final field in validFields) {
      buffer.writeln("  @pragma('vm:prefer-inline')");
      buffer.writeln('  R ${field.name}(${field.type} value) {');
      buffer.writeln('    final res = call(');
      buffer.writeln('      ${field.name}: value,');
      buffer.writeln('    );');
      buffer.writeln('    return res;');
      buffer.writeln('  }');
      buffer.writeln();
    }

    // Generate nested copyWith getters
    for (final field in validFields) {
      final type = field.type.replaceAll('?', '').trim();
      final baseName = type.split('<').first;
      final nestedClass = _findClassByName(baseName);

      if (nestedClass != null) {
        final isNullable = field.type.endsWith('?');
        final genericPart = type.contains('<')
            ? type.substring(type.indexOf('<') + 1, type.lastIndexOf('>'))
            : '';

        final nestedCopyWithName = '${nestedClass.name}CopyWith';
        final nestedGenericArgs = genericPart.isEmpty ? 'R' : '$genericPart, R';
        final nestedType = '$nestedCopyWithName<$nestedGenericArgs>';

        if (isNullable) {
          buffer.writeln("  @pragma('vm:prefer-inline')");
          buffer.writeln(
            '  $nestedType? get \$${field.name} => _instance.${field.name} == null',
          );
          buffer.writeln('      ? null');
          buffer.writeln(
            '      : $nestedType(_instance.${field.name}!, (v) => call(${field.name}: v));',
          );
        } else {
          buffer.writeln("  @pragma('vm:prefer-inline')");
          buffer.writeln(
            '  $nestedType get \$${field.name} => $nestedType(_instance.${field.name}, (v) => call(${field.name}: v));',
          );
        }
        buffer.writeln();
      }
    }

    buffer.writeln('}');
  }

  // Helper to find a ClassInfo by name
  ClassInfo? _findClassByName(String name) {
    final baseName = name.split('<').first.trim();
    return result.classes.firstWhereOrNull((c) => c.name == baseName);
  }

  void _writeParameter(StringBuffer buffer, FieldInfo field, ClassInfo clazz) {
    if (field.type.endsWith('?')) {
      buffer.writeln(
        '    Object? ${field.name} = ${_getPrefix(clazz)}dataforgeUndefined,',
      );
      return;
    }

    buffer.writeln('    ${field.type}? ${field.name},');
  }

  void _writeAssignment(
    StringBuffer buffer,
    FieldInfo field,
    String instance,
    ClassInfo clazz,
  ) {
    if (field.type.endsWith('?')) {
      final castExpression = _buildTypeCastExpression(
        field.name,
        field.type,
        field.name,
        clazz,
        instanceReference: instance,
      );
      buffer.writeln(
        '      ${field.name}: (${field.name} == ${_getPrefix(clazz)}dataforgeUndefined ? $instance.${field.name} : $castExpression),',
      );
      return;
    }

    buffer.writeln(
      '      ${field.name}: (${field.name} ?? $instance.${field.name}),',
    );
  }

  /// Check if a field type is a collection type (List, Set, or Map)
  bool _isCollectionType(String type) {
    final cleanType = type.replaceAll('?', '').trim();
    return cleanType.startsWith('List<') ||
        cleanType.startsWith('Set<') ||
        cleanType.startsWith('Map<');
  }

  void _buildEquality(
    StringBuffer buffer,
    ClassInfo clazz,
    List<FieldInfo> validFields,
  ) {
    buffer.writeln('  @override');
    buffer.writeln('  bool operator ==(Object other) {');
    buffer.writeln('    if (identical(this, other)) return true;');
    buffer.writeln('    if (other is! ${clazz.name}) return false;');
    buffer.writeln();

    if (validFields.isEmpty) {
      buffer.writeln('    return true;');
    } else {
      // Check if any field is a collection type
      final hasCollectionField = validFields.any(
        (f) => _isCollectionType(f.type),
      );

      if (hasCollectionField) {
        // Use field-by-field comparison when collection types are present
        for (final field in validFields) {
          if (_isCollectionType(field.type)) {
            // Use DeepCollectionEquality for List and Map types
            buffer.writeln(
              '    if (!const DeepCollectionEquality().equals(${field.name}, other.${field.name})) {',
            );
            buffer.writeln('      return false;');
            buffer.writeln('    }');
          } else {
            buffer.writeln('    if (${field.name} != other.${field.name}) {');
            buffer.writeln('      return false;');
            buffer.writeln('    }');
          }
        }
        buffer.writeln('    return true;');
      } else {
        // Use compact single-line return for non-collection classes
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
    }
    buffer.writeln('  }');
    buffer.writeln();
  }

  void _buildHashCode(
    StringBuffer buffer,
    ClassInfo clazz,
    List<FieldInfo> validFields,
  ) {
    buffer.writeln('  @override');
    buffer.writeln('  int get hashCode => Object.hashAll([');
    for (final field in validFields) {
      if (_isCollectionType(field.type)) {
        // Use DeepCollectionEquality.hash for List and Map types
        buffer.writeln(
          '        const DeepCollectionEquality().hash(${field.name}),',
        );
      } else {
        buffer.writeln('        ${field.name},');
      }
    }
    buffer.writeln('      ]);');
    buffer.writeln();
  }

  void _buildToString(
    StringBuffer buffer,
    ClassInfo clazz,
    List<FieldInfo> validFields,
  ) {
    buffer.writeln('  @override');
    buffer.write("  String toString() => '${clazz.name}(");

    for (int i = 0; i < validFields.length; i++) {
      final field = validFields[i];
      final isLast = i == validFields.length - 1;
      buffer.write('${field.name}: \$${field.name}${isLast ? '' : ', '}');
    }

    buffer.writeln(")';");
    buffer.writeln();
  }

  String _buildConverterReference(String converterExpression) {
    final trimmed = converterExpression.trim();
    if (trimmed.isEmpty) return trimmed;

    final simpleTypePattern =
        RegExp(r'^[A-Za-z_]\w*(?:\.\w+)*(?:<[^<>]+>)?$');
    final lastSegment = trimmed.split('.').last;
    final startsWithTypeName =
        lastSegment.isNotEmpty && RegExp(r'^[A-Z]').hasMatch(lastSegment);
    if (simpleTypePattern.hasMatch(trimmed) && startsWithTypeName) {
      return 'const $trimmed()';
    }
    return trimmed;
  }

  String _buildConverterCall(
    String converterExpression,
    String methodName,
    String argument,
  ) {
    final converterRef = _buildConverterReference(converterExpression);
    return '($converterRef).$methodName($argument)';
  }

  String _buildMissingValueError(
    FieldInfo field,
    String expectedType, {
    String? detail,
  }) {
    final suffix = detail == null ? '' : ' $detail';
    return 'throw ArgumentError(\'Required field "${field.name}" (type: $expectedType) is missing or invalid.$suffix\')';
  }

  String _buildRequiredExpression(
    String expression,
    FieldInfo field,
    String expectedType, {
    String? detail,
  }) {
    return '(($expression) ?? (${_buildMissingValueError(field, expectedType, detail: detail)}))';
  }

  String _buildNestedToJsonExpression(String expression, bool isNullable) {
    if (isNullable) {
      return '($expression?.toJson())';
    }
    return '$expression.toJson()';
  }

  String _buildEnumValueExpression(
    ClassInfo clazz,
    FieldInfo field,
    String enumType,
    String valueExpression, {
    required bool isNullable,
  }) {
    final prefix = _getPrefix(clazz);
    final converter =
        'const ${prefix}DefaultEnumConverter<$enumType>($enumType.values)';
    final safeString =
        '${prefix}SafeCasteUtil.safeCast<String>($valueExpression)';

    if (isNullable) {
      return '($valueExpression is $enumType ? $valueExpression : $converter.fromJson($safeString))';
    }

    return '($valueExpression is $enumType ? $valueExpression : ${_buildRequiredExpression('$converter.fromJson($safeString)', field, enumType)})';
  }

  void _buildToJson(
    StringBuffer buffer,
    ClassInfo clazz,
    List<FieldInfo> validFields,
  ) {
    buffer.writeln('  Map<String, dynamic> toJson() {');
    buffer.writeln('    return {');

    for (final field in validFields) {
      if (field.jsonKey?.ignore == true) continue;

      final jsonKey = field.jsonKey?.name.isNotEmpty == true
          ? field.jsonKey!.name
          : field.name;

      final cleanType = field.type.replaceAll('?', '').trim();
      final isNullable = field.type.endsWith('?');
      String valueAccess;
      final jsonKeyInfo = field.jsonKey;
      final customToJson = jsonKeyInfo?.toJson;
      final customConverter = jsonKeyInfo?.converter;

      // Priority 1: Custom toJson function (highest priority)
      if (customToJson != null && customToJson.isNotEmpty) {
        if (isNullable) {
          valueAccess =
              '(${field.name} != null ? $customToJson(${field.name}!) : null)';
        } else {
          valueAccess = '($customToJson(${field.name}))';
        }
      }
      // Priority 2: Custom converter
      else if (customConverter != null && customConverter.isNotEmpty) {
        valueAccess = _buildConverterCall(
          customConverter,
          'toJson',
          field.name,
        );
      }
      // Priority 3: Auto-matched converters (DateTime, Enum)
      else if (field.isDateTime || cleanType == 'DateTime') {
        valueAccess =
            'const ${_getPrefix(clazz)}DefaultDateTimeConverter().toJson(${field.name})';
      } else if (field.isEnum) {
        valueAccess =
            '${_getPrefix(clazz)}DefaultEnumConverter($cleanType.values).toJson(${field.name})';
      } else if (field.isDataforge) {
        valueAccess = _buildNestedToJsonExpression(field.name, isNullable);
      } else if (cleanType.startsWith('List<')) {
        final innerType = cleanType.substring(5, cleanType.length - 1);
        final innerTypeClean = innerType.replaceAll('?', '').trim();

        if (field.isInnerDataforge) {
          final mapLogic = innerType.endsWith('?')
              ? '(e) => e?.toJson()'
              : '(e) => e.toJson()';
          valueAccess = isNullable
              ? '${field.name}?.map($mapLogic).toList()'
              : '${field.name}.map($mapLogic).toList()';
        } else if (innerTypeClean == 'DateTime') {
          final mapLogic =
              '(e) => const ${_getPrefix(clazz)}DefaultDateTimeConverter().toJson(e)';
          valueAccess = isNullable
              ? '${field.name}?.map($mapLogic).toList()'
              : '${field.name}.map($mapLogic).toList()';
        } else if (field.isInnerEnum) {
          final mapLogic =
              '(e) => const ${_getPrefix(clazz)}DefaultEnumConverter<$innerTypeClean>($innerTypeClean.values).toJson(e)';
          valueAccess = isNullable
              ? '${field.name}?.map($mapLogic).toList()'
              : '${field.name}.map($mapLogic).toList()';
        } else {
          valueAccess = field.name;
        }
      } else if (cleanType.startsWith('Set<')) {
        final innerType = cleanType.substring(4, cleanType.length - 1);
        final innerTypeClean = innerType.replaceAll('?', '').trim();

        if (field.isInnerEnum) {
          final mapLogic =
              '(e) => const ${_getPrefix(clazz)}DefaultEnumConverter<$innerTypeClean>($innerTypeClean.values).toJson(e)';
          if (isNullable) {
            valueAccess = '${field.name}?.map($mapLogic).toList()';
          } else {
            valueAccess = '${field.name}.map($mapLogic).toList()';
          }
        } else if (field.isInnerDataforge) {
          final mapLogic = innerType.endsWith('?')
              ? '(e) => e?.toJson()'
              : '(e) => e.toJson()';
          if (isNullable) {
            valueAccess = '${field.name}?.map($mapLogic).toList()';
          } else {
            valueAccess = '${field.name}.map($mapLogic).toList()';
          }
        } else if (innerTypeClean == 'DateTime') {
          final mapLogic =
              '(e) => const ${_getPrefix(clazz)}DefaultDateTimeConverter().toJson(e)';
          if (isNullable) {
            valueAccess = '${field.name}?.map($mapLogic).toList()';
          } else {
            valueAccess = '${field.name}.map($mapLogic).toList()';
          }
        } else {
          if (isNullable) {
            valueAccess = '${field.name}?.toList()';
          } else {
            valueAccess = '${field.name}.toList()';
          }
        }
      } else if (cleanType.startsWith('Map<')) {
        final mapTypeParts = _splitTopLevelTypeArguments(
          cleanType.substring(4, cleanType.length - 1),
        );
        final keyType = mapTypeParts.first.trim();
        final innerType = mapTypeParts.last;
        final innerTypeClean = innerType.replaceAll('?', '').trim();

        if (keyType == 'String' &&
            field.isInnerEnum &&
            innerTypeClean.isNotEmpty) {
          final mapLogic =
              '(k, e) => MapEntry(k, const ${_getPrefix(clazz)}DefaultEnumConverter<$innerTypeClean>($innerTypeClean.values).toJson(e))';
          if (isNullable) {
            valueAccess = '${field.name}?.map($mapLogic)';
          } else {
            valueAccess = '${field.name}.map($mapLogic)';
          }
        } else if (keyType == 'String' && field.isInnerDataforge) {
          final mapLogic = innerType.endsWith('?')
              ? '(k, v) => MapEntry(k, v?.toJson())'
              : '(k, v) => MapEntry(k, v.toJson())';
          if (isNullable) {
            valueAccess = '${field.name}?.map($mapLogic)';
          } else {
            valueAccess = '${field.name}.map($mapLogic)';
          }
        } else if (keyType == 'String' && innerTypeClean == 'DateTime') {
          final mapLogic = innerType.endsWith('?')
              ? '(k, v) => MapEntry(k, v == null ? null : const ${_getPrefix(clazz)}DefaultDateTimeConverter().toJson(v))'
              : '(k, v) => MapEntry(k, const ${_getPrefix(clazz)}DefaultDateTimeConverter().toJson(v))';
          if (isNullable) {
            valueAccess = '${field.name}?.map($mapLogic)';
          } else {
            valueAccess = '${field.name}.map($mapLogic)';
          }
        } else {
          valueAccess = field.name;
        }
      }
      // Priority 4: Default (direct access)
      else {
        valueAccess = field.name;
      }

      if (jsonKeyInfo?.includeIfNull == false && isNullable) {
        buffer.writeln(
            "      if (${field.name} != null) '$jsonKey': $valueAccess,");
      } else {
        buffer.writeln('      \'$jsonKey\': $valueAccess,');
      }
    }

    buffer.writeln('    };');
    buffer.writeln('  }');
    buffer.writeln();
  }

  void _buildFromJson(
    StringBuffer buffer,
    ClassInfo clazz,
    String genericParams,
    List<FieldInfo> validFields,
  ) {
    final genericConstraints = clazz.genericParameters.isNotEmpty
        ? '<${clazz.genericParameters.map((p) => p.name).join(', ')}>'
        : '';

    buffer.writeln(
      '  static ${clazz.name}$genericConstraints fromJson$genericConstraints(Map<String, dynamic> json) {',
    );
    buffer.writeln('    return ${clazz.name}(');

    for (final field in validFields) {
      if (field.jsonKey?.ignore == true) continue;

      final jsonKey = field.jsonKey?.name.isNotEmpty == true
          ? field.jsonKey!.name
          : field.name;

      final jsonKeyInfo = field.jsonKey;

      String valueExpression;
      if (jsonKeyInfo != null && jsonKeyInfo.readValue.isNotEmpty) {
        valueExpression = "${jsonKeyInfo.readValue}(json, '$jsonKey')";
      } else if (jsonKeyInfo != null && jsonKeyInfo.alternateNames.isNotEmpty) {
        final allKeys = [jsonKey, ...jsonKeyInfo.alternateNames];
        valueExpression = "(${allKeys.map((k) => "json['$k']").join(' ?? ')})";
      } else {
        valueExpression = "json['$jsonKey']";
      }

      final cleanType = field.type.replaceAll('?', '').trim();
      final isNullable = field.type.endsWith('?');
      final customFromJson = jsonKeyInfo?.fromJson;
      final customConverter = jsonKeyInfo?.converter;

      String conversion;
      // Priority 1: Custom fromJson function (highest priority)
      if (customFromJson != null && customFromJson.isNotEmpty) {
        if (isNullable) {
          conversion =
              '($valueExpression != null ? $customFromJson($valueExpression) : null)';
        } else {
          conversion = '($customFromJson($valueExpression))';
        }
      }
      // Priority 2: Custom converter
      else if (customConverter != null && customConverter.isNotEmpty) {
        if (jsonKeyInfo != null && jsonKeyInfo.readValue.isNotEmpty) {
          // If readValue is used, check if the value is already the
          // target type. If so, return it directly. Otherwise, use
          // the converter.
          final nullHandler = isNullable
              ? '(v == null ? null :'
              : "(v == null ? throw ArgumentError('Required field \"${field.name}\" (type: $cleanType) is null. Check that the JSON contains this field with a non-null value.') :";
          conversion =
              '((dynamic v) => $nullHandler (v is $cleanType ? v : ${_buildConverterCall(customConverter, 'fromJson', 'v')})))($valueExpression)';
        } else {
          conversion = _buildConverterCall(
            customConverter,
            'fromJson',
            valueExpression,
          );
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
                "${_getPrefix(clazz)}SafeCasteUtil.readRequiredValue<$cleanType>(json, '$jsonKey')";
            usedRequired = true;
          } else {
            conversion =
                "${_getPrefix(clazz)}SafeCasteUtil.readValue<$cleanType>(json, '$jsonKey')";
          }
        } else {
          conversion =
              '${_getPrefix(clazz)}SafeCasteUtil.safeCast<$cleanType>($valueExpression)';
        }

        if (field.defaultValue.isNotEmpty) {
          conversion = '(($conversion) ?? (${field.defaultValue}))';
        } else if (!isNullable && !usedRequired) {
          final defaultValue = ({
                'int': '0',
                'double': '0.0',
                'String': "''",
                'bool': 'false',
              }[cleanType] ??
              'null');
          conversion = '($conversion ?? $defaultValue)';
        }
      } else if (field.isDateTime || cleanType == 'DateTime') {
        bool usedRequired = false;
        if (jsonKeyInfo == null ||
            (jsonKeyInfo.readValue.isEmpty &&
                jsonKeyInfo.alternateNames.isEmpty)) {
          if (field.isRequired && !isNullable && field.defaultValue.isEmpty) {
            conversion =
                "${_getPrefix(clazz)}SafeCasteUtil.readRequiredValue<DateTime>(json, '$jsonKey')";
            usedRequired = true;
          } else {
            conversion =
                "${_getPrefix(clazz)}SafeCasteUtil.readValue<DateTime>(json, '$jsonKey')";
          }
        } else {
          conversion =
              '${_getPrefix(clazz)}SafeCasteUtil.safeCast<DateTime>($valueExpression)';
        }

        if (field.defaultValue.isNotEmpty) {
          conversion = '(($conversion) ?? (${field.defaultValue}))';
        } else if (!isNullable && !usedRequired) {
          conversion = _buildRequiredExpression(conversion, field, cleanType);
        }
      } else if (field.isEnum) {
        if (jsonKeyInfo != null && jsonKeyInfo.readValue.isNotEmpty) {
          final enumValueConversion = _buildEnumValueExpression(
            clazz,
            field,
            cleanType,
            'v',
            isNullable: isNullable,
          );
          conversion =
              '((dynamic v) => $enumValueConversion)($valueExpression)';
        } else {
          String stringValueExpr;
          if (jsonKeyInfo == null ||
              (jsonKeyInfo.readValue.isEmpty &&
                  jsonKeyInfo.alternateNames.isEmpty)) {
            stringValueExpr =
                "${_getPrefix(clazz)}SafeCasteUtil.readValue<String>(json, '$jsonKey')";
          } else {
            stringValueExpr =
                '${_getPrefix(clazz)}SafeCasteUtil.safeCast<String>($valueExpression)';
          }
          conversion =
              '${_getPrefix(clazz)}DefaultEnumConverter($cleanType.values).fromJson($stringValueExpr)';
        }
        if (field.defaultValue.isNotEmpty) {
          conversion = '(($conversion) ?? (${field.defaultValue}))';
        } else if (!isNullable) {
          conversion = _buildRequiredExpression(conversion, field, cleanType);
        }
      } else if (cleanType.startsWith('List<')) {
        final innerType = cleanType.substring(5, cleanType.length - 1);
        final innerTypeClean = innerType.replaceAll('?', '').trim();
        final isSupportedBasic = [
              'int',
              'double',
              'num',
              'String',
              'bool',
              'dynamic',
              'Object',
              'DateTime',
            ].contains(innerTypeClean) ||
            innerTypeClean == 'Map<String, dynamic>';

        String listExpr;
        bool isListExprNullable = true;

        if (jsonKeyInfo == null ||
            (jsonKeyInfo.readValue.isEmpty &&
                jsonKeyInfo.alternateNames.isEmpty)) {
          if (field.isInnerDataforge) {
            // readObjectList handles type conversion internally, no outer safeCast needed
            listExpr = "json['$jsonKey']";
            isListExprNullable = true;
          } else if (field.isInnerEnum) {
            listExpr =
                "${_getPrefix(clazz)}SafeCasteUtil.safeCast<List<dynamic>>(json['$jsonKey'])";
            isListExprNullable = true;
          } else {
            if (field.isRequired && !isNullable && field.defaultValue.isEmpty) {
              listExpr =
                  "${_getPrefix(clazz)}SafeCasteUtil.readRequiredValue<List<dynamic>>(json, '$jsonKey')";
              isListExprNullable = false;
            } else {
              listExpr =
                  "${_getPrefix(clazz)}SafeCasteUtil.readValue<List<dynamic>>(json, '$jsonKey')";
            }
          }
        } else {
          if (field.isInnerDataforge) {
            // readObjectList handles type conversion internally, no outer safeCast needed
            listExpr = valueExpression;
          } else {
            final safeCastType =
                field.isInnerEnum ? 'List<dynamic>' : cleanType;
            listExpr =
                '${_getPrefix(clazz)}SafeCasteUtil.safeCast<$safeCastType>($valueExpression)';
          }
        }

        if (isSupportedBasic) {
          if ([
            'String',
            'int',
            'double',
            'bool',
            'num',
            'DateTime',
          ].contains(innerTypeClean)) {
            String safeCastExpr;
            if (innerType.endsWith('?')) {
              safeCastExpr =
                  '.map((e) => ${_getPrefix(clazz)}SafeCasteUtil.safeCast<$innerTypeClean>(e)).toList()';
            } else if (innerTypeClean == 'DateTime') {
              safeCastExpr =
                  '.map((e) => ${_buildRequiredExpression('${_getPrefix(clazz)}SafeCasteUtil.safeCast<DateTime>(e)', field, innerTypeClean, detail: 'in collection field "${field.name}"')}).toList()';
            } else {
              String defaultValue;
              switch (innerTypeClean) {
                case 'String':
                  defaultValue = "''";
                  break;
                case 'int':
                  defaultValue = '0';
                  break;
                case 'double':
                  defaultValue = '0.0';
                  break;
                case 'bool':
                  defaultValue = 'false';
                  break;
                case 'num':
                  defaultValue = '0';
                  break;
                default:
                  defaultValue = 'null';
              }
              safeCastExpr =
                  '.map((e) => (${_getPrefix(clazz)}SafeCasteUtil.safeCast<$innerTypeClean>(e) ?? $defaultValue)).toList()';
            }
            conversion = (isListExprNullable
                ? '(($listExpr?$safeCastExpr))'
                : '($listExpr$safeCastExpr)');
          } else {
            conversion = (isListExprNullable
                ? '(($listExpr?.cast<$innerType>()))'
                : '($listExpr.cast<$innerType>())');
          }
        } else if (field.isInnerEnum) {
          final elementConversion = _buildEnumValueExpression(
            clazz,
            field,
            innerTypeClean,
            'e',
            isNullable: innerType.endsWith('?'),
          );
          final mapLogic = '.map((e) => $elementConversion).toList()';
          conversion = (isListExprNullable
              ? '(($listExpr?$mapLogic))'
              : '($listExpr$mapLogic)');
        } else if (field.isInnerDataforge) {
          conversion =
              '${_getPrefix(clazz)}SafeCasteUtil.readObjectList($listExpr, $innerTypeClean.fromJson)';
        } else {
          throw UnsupportedTypeException(
            unsupportedType: innerTypeClean,
            fieldName: field.name,
            supportedTypes: const [
              'int',
              'double',
              'num',
              'String',
              'bool',
              'dynamic',
              'Object',
              'DateTime',
              'Map<String, dynamic>',
              'Enum types',
              '@Dataforge annotated classes',
            ],
            context: 'Nested type in List<$innerTypeClean>',
          );
        }

        if (field.defaultValue.isNotEmpty) {
          conversion = '($conversion ?? (${field.defaultValue}))';
        } else if (!isNullable) {
          if (isListExprNullable) {
            conversion = '($conversion ?? (const []))';
          }
        }
      } else if (cleanType.startsWith('Set<')) {
        final innerType = cleanType.substring(4, cleanType.length - 1);
        final innerTypeClean = innerType.replaceAll('?', '').trim();
        final isSupportedBasic = [
              'int',
              'double',
              'num',
              'String',
              'bool',
              'dynamic',
              'Object',
              'DateTime',
            ].contains(innerTypeClean) ||
            innerTypeClean == 'Map<String, dynamic>';

        String setExpr;
        bool isSetExprNullable = true;

        if (jsonKeyInfo == null ||
            (jsonKeyInfo.readValue.isEmpty &&
                jsonKeyInfo.alternateNames.isEmpty)) {
          if (field.isRequired && !isNullable && field.defaultValue.isEmpty) {
            setExpr =
                "${_getPrefix(clazz)}SafeCasteUtil.readRequiredValue<List<dynamic>>(json, '$jsonKey')";
            isSetExprNullable = false;
          } else {
            setExpr =
                "${_getPrefix(clazz)}SafeCasteUtil.readValue<List<dynamic>>(json, '$jsonKey')";
          }
        } else {
          setExpr =
              '${_getPrefix(clazz)}SafeCasteUtil.safeCast<List<dynamic>>($valueExpression)';
        }

        if (isSupportedBasic) {
          if ([
            'String',
            'int',
            'double',
            'bool',
            'num',
            'DateTime',
          ].contains(innerTypeClean)) {
            String safeCastExpr;
            if (innerType.endsWith('?')) {
              safeCastExpr =
                  '.map((e) => ${_getPrefix(clazz)}SafeCasteUtil.safeCast<$innerTypeClean>(e)).toSet()';
            } else if (innerTypeClean == 'DateTime') {
              safeCastExpr =
                  '.map((e) => ${_buildRequiredExpression('${_getPrefix(clazz)}SafeCasteUtil.safeCast<DateTime>(e)', field, innerTypeClean, detail: 'in collection field "${field.name}"')}).toSet()';
            } else {
              String defaultValue;
              switch (innerTypeClean) {
                case 'String':
                  defaultValue = "''";
                  break;
                case 'int':
                  defaultValue = '0';
                  break;
                case 'double':
                  defaultValue = '0.0';
                  break;
                case 'bool':
                  defaultValue = 'false';
                  break;
                case 'num':
                  defaultValue = '0';
                  break;
                default:
                  defaultValue = 'null';
              }
              safeCastExpr =
                  '.map((e) => (${_getPrefix(clazz)}SafeCasteUtil.safeCast<$innerTypeClean>(e) ?? $defaultValue)).toSet()';
            }
            conversion = (isSetExprNullable
                ? '(($setExpr?$safeCastExpr))'
                : '($setExpr$safeCastExpr)');
          } else {
            conversion = (isSetExprNullable
                ? '(($setExpr?.cast<$innerType>().toSet()))'
                : '($setExpr.cast<$innerType>().toSet())');
          }
        } else if (field.isInnerEnum) {
          final elementConversion = _buildEnumValueExpression(
            clazz,
            field,
            innerTypeClean,
            'e',
            isNullable: innerType.endsWith('?'),
          );
          final mapLogic = '.map((e) => $elementConversion).toSet()';
          conversion = (isSetExprNullable
              ? '(($setExpr?$mapLogic))'
              : '($setExpr$mapLogic)');
        } else if (field.isInnerDataforge) {
          conversion =
              '(${_getPrefix(clazz)}SafeCasteUtil.readObjectList($setExpr, $innerTypeClean.fromJson)?.toSet())';
        } else {
          throw UnsupportedTypeException(
            unsupportedType: innerTypeClean,
            fieldName: field.name,
            supportedTypes: const [
              'int',
              'double',
              'num',
              'String',
              'bool',
              'dynamic',
              'Object',
              'DateTime',
              'Map<String, dynamic>',
              'Enum types',
              '@Dataforge annotated classes',
            ],
            context: 'Nested type in Set<$innerTypeClean>',
          );
        }

        if (field.defaultValue.isNotEmpty) {
          conversion = '($conversion ?? (${field.defaultValue}))';
        } else if (!isNullable) {
          if (isSetExprNullable) {
            conversion = '($conversion ?? (<$innerType>{}))';
          }
        }
      } else if (cleanType.startsWith('Map<')) {
        final mapTypeParts = _splitTopLevelTypeArguments(
          cleanType.substring(4, cleanType.length - 1),
        );
        final keyType = mapTypeParts[0].trim();
        final innerType = mapTypeParts.last.trim();
        final innerTypeClean = innerType.replaceAll('?', '').trim();

        if (keyType != 'String' &&
            keyType != 'dynamic' &&
            keyType != 'Object') {
          throw UnsupportedTypeException(
            unsupportedType: keyType,
            fieldName: field.name,
            supportedTypes: const ['String', 'dynamic', 'Object'],
            context:
                'Map key type must be String for JSON compatibility. Consider using Map<String, $innerTypeClean> instead of Map<$keyType, $innerTypeClean>.',
          );
        }

        if (innerTypeClean == 'DateTime') {
          String mapExpr;
          bool isMapExprNullable = true;
          if (jsonKeyInfo == null ||
              (jsonKeyInfo.readValue.isEmpty &&
                  jsonKeyInfo.alternateNames.isEmpty)) {
            if (field.isRequired && !isNullable && field.defaultValue.isEmpty) {
              mapExpr =
                  "${_getPrefix(clazz)}SafeCasteUtil.readRequiredValue<Map<String, dynamic>>(json, '$jsonKey')";
              isMapExprNullable = false;
            } else {
              mapExpr =
                  "${_getPrefix(clazz)}SafeCasteUtil.readValue<Map<String, dynamic>>(json, '$jsonKey')";
            }
          } else {
            mapExpr =
                '${_getPrefix(clazz)}SafeCasteUtil.safeCast<Map<String, dynamic>>($valueExpression)';
          }

          final safeCastExpr = innerType.endsWith('?')
              ? '.map((k, v) => MapEntry(k.toString(), ${_getPrefix(clazz)}SafeCasteUtil.safeCast<DateTime>(v)))'
              : '.map((k, v) => MapEntry(k.toString(), ${_buildRequiredExpression('${_getPrefix(clazz)}SafeCasteUtil.safeCast<DateTime>(v)', field, innerTypeClean, detail: 'in map field "${field.name}"')}))';

          conversion = (isMapExprNullable
              ? '($mapExpr?$safeCastExpr)'
              : '($mapExpr$safeCastExpr)');
        } else if (field.isInnerEnum) {
          String mapExpr;
          bool isMapExprNullable = true;
          if (jsonKeyInfo == null ||
              (jsonKeyInfo.readValue.isEmpty &&
                  jsonKeyInfo.alternateNames.isEmpty)) {
            if (field.isRequired && !isNullable && field.defaultValue.isEmpty) {
              mapExpr =
                  "${_getPrefix(clazz)}SafeCasteUtil.readRequiredValue<Map<String, dynamic>>(json, '$jsonKey')";
              isMapExprNullable = false;
            } else {
              mapExpr =
                  "${_getPrefix(clazz)}SafeCasteUtil.readValue<Map<String, dynamic>>(json, '$jsonKey')";
            }
          } else {
            mapExpr =
                '${_getPrefix(clazz)}SafeCasteUtil.safeCast<Map<String, dynamic>>($valueExpression)';
          }

          final valueConversion = _buildEnumValueExpression(
            clazz,
            field,
            innerTypeClean,
            'v',
            isNullable: innerType.endsWith('?'),
          );
          final safeCastExpr =
              '.map((k, v) => MapEntry(k.toString(), $valueConversion))';

          conversion = (isMapExprNullable
              ? '($mapExpr?$safeCastExpr)'
              : '($mapExpr$safeCastExpr)');
        } else if (field.isInnerDataforge) {
          String mapExpr;
          bool isMapExprNullable = true;
          if (jsonKeyInfo == null ||
              (jsonKeyInfo.readValue.isEmpty &&
                  jsonKeyInfo.alternateNames.isEmpty)) {
            if (field.isRequired && !isNullable && field.defaultValue.isEmpty) {
              mapExpr =
                  "${_getPrefix(clazz)}SafeCasteUtil.readRequiredValue<Map<String, dynamic>>(json, '$jsonKey')";
              isMapExprNullable = false;
            } else {
              mapExpr =
                  "${_getPrefix(clazz)}SafeCasteUtil.readValue<Map<String, dynamic>>(json, '$jsonKey')";
            }
          } else {
            mapExpr =
                '${_getPrefix(clazz)}SafeCasteUtil.safeCast<Map<String, dynamic>>($valueExpression)';
          }

          final safeCastExpr = innerType.endsWith('?')
              ? '.map((k, v) => MapEntry(k.toString(), (v == null ? null : $innerTypeClean.fromJson(v as Map<String, dynamic>))))'
              : '.map((k, v) => MapEntry(k.toString(), ($innerTypeClean.fromJson(v as Map<String, dynamic>))))';

          conversion = (isMapExprNullable
              ? '($mapExpr?$safeCastExpr)'
              : '($mapExpr$safeCastExpr)');
        } else if ([
          'String',
          'int',
          'double',
          'bool',
          'num',
          'dynamic',
          'Object',
        ].contains(innerTypeClean)) {
          // Basic Map: cast generated map
          if (field.isRequired && !isNullable && field.defaultValue.isEmpty) {
            conversion =
                "${_getPrefix(clazz)}SafeCasteUtil.readRequiredValue<Map<String, dynamic>>(json, '$jsonKey').cast<String, $innerTypeClean>()";
          } else {
            conversion =
                "${_getPrefix(clazz)}SafeCasteUtil.readValue<Map<String, dynamic>>(json, '$jsonKey')?.cast<String, $innerTypeClean>()";
          }
        } else {
          throw UnsupportedTypeException(
            unsupportedType: innerTypeClean,
            fieldName: field.name,
            supportedTypes: const [
              'int',
              'double',
              'num',
              'String',
              'bool',
              'dynamic',
              'Object',
              'DateTime',
              'Enum types',
              '@Dataforge annotated classes',
            ],
            context: 'Nested type in Map value Map<String, $innerTypeClean>',
          );
        }

        if (field.defaultValue.isNotEmpty) {
          conversion = '(($conversion) ?? (${field.defaultValue}))';
        }
      } else if (field.isDataforge) {
        String baseExpression;
        bool usedRequired = false;

        if (jsonKeyInfo != null && jsonKeyInfo.readValue.isNotEmpty) {
          final valParam = 'v';

          final nullCheck = (isNullable || field.defaultValue.isNotEmpty)
              ? 'if ($valParam == null) return null;'
              : "if ($valParam == null) throw ArgumentError('Required field \"${field.name}\" (type: $cleanType) is null. Ensure the JSON contains this field with a valid object value.');";

          baseExpression =
              "((dynamic $valParam) { $nullCheck if ($valParam is $cleanType) return $valParam; if ($valParam is Map) return $cleanType.fromJson(($valParam as Map).cast<String, dynamic>()); throw ArgumentError('Field \"${field.name}\" expects Map<String, dynamic> or $cleanType, but received: \${$valParam.runtimeType}'); })($valueExpression)";
        } else {
          if (jsonKeyInfo == null ||
              (jsonKeyInfo.readValue.isEmpty &&
                  jsonKeyInfo.alternateNames.isEmpty)) {
            if (field.isRequired && !isNullable && field.defaultValue.isEmpty) {
              baseExpression =
                  "${_getPrefix(clazz)}SafeCasteUtil.readRequiredObject(json['$jsonKey'], $cleanType.fromJson)";
              usedRequired = true;
            } else {
              baseExpression =
                  "${_getPrefix(clazz)}SafeCasteUtil.readObject(json['$jsonKey'], $cleanType.fromJson)";
            }
          } else {
            baseExpression =
                '${_getPrefix(clazz)}SafeCasteUtil.readObject($valueExpression, $cleanType.fromJson)';
          }
        }

        conversion = baseExpression;
        if (field.defaultValue.isNotEmpty) {
          conversion = '(($conversion) ?? (${field.defaultValue}))';
        } else if (!isNullable && !usedRequired) {
          conversion = '($baseExpression)!';
        }
      } else {
        conversion = '$valueExpression';
        if (field.defaultValue.isNotEmpty) {
          conversion = '(($conversion) ?? (${field.defaultValue}))';
        }
      }

      buffer.writeln('      ${field.name}: $conversion,');
    }

    buffer.writeln('    );');
    buffer.writeln('  }');
  }
}
