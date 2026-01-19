// @author luwenjie on 2026/01/17 14:37:53

import 'package:collection/collection.dart';
import 'model.dart';

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

  /// Generate the complete code output
  String generate() {
    final buffer = StringBuffer();

    // Generate code for each class
    for (final clazz in result.classes) {
      if (result.primaryClassName != null &&
          clazz.name != result.primaryClassName) {
        continue;
      }
      // Validate class information
      if (clazz.name.isEmpty || clazz.mixinName.isEmpty) {
        print(
            'Warning: Skipping class with empty name or mixinName: ${clazz.name}');
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
          print(
              'Warning: Skipping invalid field: name="${field.name}", type="${field.type}"');
          continue;
        }
        buffer.writeln('  abstract final ${field.type} ${field.name};');
      }

      // Generate methods
      final validFields = clazz.fields
          .where((field) =>
              field.name.isNotEmpty &&
              field.type.isNotEmpty &&
              field.type != 'dynamic' &&
              !field.isFunction)
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
            buffer, clazz, genericParams, validFields);
      }
    }

    return buffer.toString();
  }

  /// Build copyWith method
  void _buildCopyWith(StringBuffer buffer, ClassInfo clazz,
      String genericParams, List<FieldInfo> validFields) {
    if (clazz.deepCopyWith) {
      // Chained copyWith style
      final genericArgs = genericParams.isEmpty
          ? '<${clazz.name}>'
          : genericParams.replaceFirst('>', ', ${clazz.name}$genericParams>');
      buffer.writeln(
          '  ${clazz.mixinName}CopyWith$genericArgs get copyWith => ${clazz.mixinName}CopyWith$genericArgs._(this);');
    } else {
      // Traditional copyWith style
      _buildTraditionalCopyWith(buffer, clazz, genericParams, validFields);
    }
    buffer.writeln();
  }

  /// Build traditional copyWith method
  void _buildTraditionalCopyWith(StringBuffer buffer, ClassInfo clazz,
      String genericParams, List<FieldInfo> validFields) {
    buffer.writeln('  ${clazz.name}$genericParams copyWith({');
    for (final field in validFields) {
      _writeParameter(buffer, field);
    }
    buffer.writeln('  }) {');
    buffer.writeln('    return ${clazz.name}(');
    for (final field in validFields) {
      _writeAssignment(buffer, field, 'this');
    }
    buffer.writeln('    );');
    buffer.writeln('  }');
  }

  /// Build chained copyWith helper class
  void _buildChainedCopyWithHelperClass(StringBuffer buffer, ClassInfo clazz,
      String genericParams, List<FieldInfo> validFields) {
    final copyWithClassName = '${clazz.mixinName}CopyWith';
    final returnType = 'R';
    final genericParamsWithR = genericParams.isEmpty
        ? '<$returnType>'
        : genericParams.replaceFirst('>', ', $returnType>');

    buffer.writeln('class $copyWithClassName$genericParamsWithR {');
    buffer.writeln('  final ${clazz.mixinName}$genericParams _instance;');
    buffer.writeln(
        '  final $returnType Function(${clazz.name}$genericParams)? _then;');
    buffer.writeln('  $copyWithClassName._(this._instance, [this._then]);');

    buffer.writeln();
    buffer.writeln('  R call({');
    // Use Object? with sentinel default for all parameters
    for (final field in validFields) {
      buffer.writeln(
          '    Object? ${field.name} = ${_getPrefix(clazz)}dataforgeUndefined,');
    }
    buffer.writeln('  }) {');
    buffer.writeln('    final res = ${clazz.name}$genericParams(');
    for (final field in validFields) {
      // Use sentinel check to distinguish null from omitted
      buffer.writeln(
          '      ${field.name}: ${field.name} == ${_getPrefix(clazz)}dataforgeUndefined ? _instance.${field.name} : ${field.name} as ${field.type},');
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
          _generateNestedCopyWithChain(
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
    return result.classes.firstWhereOrNull((c) => c.name == name);
  }

  // Helper to build a combined field accessor name (e.g., user$address$street)
  // Uses $ separator to avoid conflicts with existing property names
  String _buildFieldAccessorName(List<String> path) {
    if (path.isEmpty) return '';
    return path.join('\$');
  }

  // Helper to generate the nested copyWith chain for the call method
  // Uses recursion to handle multi-level null checks
  void _generateNestedCopyWithChain(
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

  void _writeParameter(StringBuffer buffer, FieldInfo field) {
    final type = field.type.endsWith('?') ? field.type : '${field.type}?';
    buffer.writeln('    $type ${field.name},');
  }

  void _writeAssignment(StringBuffer buffer, FieldInfo field, String instance) {
    buffer.writeln(
        '      ${field.name}: ${field.name} ?? $instance.${field.name},');
  }

  void _buildEquality(
      StringBuffer buffer, ClassInfo clazz, List<FieldInfo> validFields) {
    buffer.writeln('  @override');
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
    buffer.writeln();
  }

  void _buildHashCode(
      StringBuffer buffer, ClassInfo clazz, List<FieldInfo> validFields) {
    buffer.writeln('  @override');
    buffer.writeln('  int get hashCode => Object.hashAll([');
    for (final field in validFields) {
      buffer.writeln('        ${field.name},');
    }
    buffer.writeln('      ]);');
    buffer.writeln();
  }

  void _buildToString(
      StringBuffer buffer, ClassInfo clazz, List<FieldInfo> validFields) {
    buffer.writeln('  @override');
    buffer.write('  String toString() => \'${clazz.name}(');

    for (int i = 0; i < validFields.length; i++) {
      final field = validFields[i];
      final isLast = i == validFields.length - 1;
      buffer.write('${field.name}: \$${field.name}${isLast ? '' : ', '}');
    }

    buffer.writeln(')\';');
    buffer.writeln();
  }

  void _buildToJson(
      StringBuffer buffer, ClassInfo clazz, List<FieldInfo> validFields) {
    buffer.writeln('  Map<String, dynamic> toJson() {');
    buffer.writeln('    return {');

    for (final field in validFields) {
      if (field.jsonKey?.ignore == true) continue;

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
        if (isNullable) {
          valueAccess =
              '${field.name} != null ? $customToJson(${field.name}!) : null';
        } else {
          valueAccess = '$customToJson(${field.name})';
        }
      }
      // Priority 2: Custom converter
      else if (customConverter != null && customConverter.isNotEmpty) {
        valueAccess = 'const $customConverter().toJson(${field.name})';
      }
      // Priority 3: Auto-matched converters (DateTime, Enum)
      else if (field.isDateTime) {
        valueAccess =
            'const ${_getPrefix(clazz)}DefaultDateTimeConverter().toJson(${field.name})';
      } else if (field.isEnum) {
        valueAccess =
            '${_getPrefix(clazz)}DefaultEnumConverter($cleanType.values).toJson(${field.name})';
      }
      // Priority 4: Default (direct access)
      else {
        valueAccess = field.name;
      }

      buffer.writeln('      \'$jsonKey\': $valueAccess,');
    }

    buffer.writeln('    };');
    buffer.writeln('  }');
    buffer.writeln();
  }

  void _buildFromJson(StringBuffer buffer, ClassInfo clazz,
      String genericParams, List<FieldInfo> validFields) {
    final genericConstraints = clazz.genericParameters.isNotEmpty
        ? '<${clazz.genericParameters.map((p) => p.name).join(', ')}>'
        : '';

    buffer.writeln(
        '  static ${clazz.name}$genericConstraints fromJson$genericConstraints(Map<String, dynamic> json) {');
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

      final cleanType = field.type.replaceAll('?', '');
      final isNullable = field.type.endsWith('?');
      final customFromJson = jsonKeyInfo?.fromJson;
      final customConverter = jsonKeyInfo?.converter;

      String conversion;
      // Priority 1: Custom fromJson function (highest priority)
      if (customFromJson != null && customFromJson.isNotEmpty) {
        if (isNullable) {
          conversion =
              '$valueExpression != null ? $customFromJson($valueExpression) : null';
        } else {
          conversion = '$customFromJson($valueExpression)';
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
                "${_getPrefix(clazz)}SafeCasteUtil.readRequiredValue<$cleanType>(json, '$jsonKey')";
            usedRequired = true;
          } else {
            conversion =
                "${_getPrefix(clazz)}SafeCasteUtil.readValue<$cleanType>(json, '$jsonKey')";
          }
        } else {
          conversion =
              "${_getPrefix(clazz)}SafeCasteUtil.safeCast<$cleanType>($valueExpression)";
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
            "const ${_getPrefix(clazz)}DefaultDateTimeConverter().fromJson($valueExpression)";
        if (!isNullable) {
          final defaultValue = field.defaultValue.isNotEmpty
              ? ' ?? ${field.defaultValue}'
              : ' ?? DateTime.fromMillisecondsSinceEpoch(0)';
          conversion += defaultValue;
        }
      } else if (field.isEnum) {
        String stringValueExpr;
        if (jsonKeyInfo == null ||
            (jsonKeyInfo.readValue.isEmpty &&
                jsonKeyInfo.alternateNames.isEmpty)) {
          stringValueExpr =
              "${_getPrefix(clazz)}SafeCasteUtil.readValue<String>(json, '$jsonKey')";
        } else {
          stringValueExpr =
              "${_getPrefix(clazz)}SafeCasteUtil.safeCast<String>($valueExpression)";
        }
        conversion =
            "${_getPrefix(clazz)}DefaultEnumConverter($cleanType.values).fromJson($stringValueExpr)";
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
      } else if (field.isDataforge) {
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
                  "${_getPrefix(clazz)}SafeCasteUtil.readRequiredObject(json, '$jsonKey', $cleanType.fromJson)";
              usedRequired = true;
            } else {
              baseExpression =
                  "${_getPrefix(clazz)}SafeCasteUtil.readObject(json, '$jsonKey', $cleanType.fromJson)";
            }
          } else {
            baseExpression =
                "${_getPrefix(clazz)}SafeCasteUtil.parseObject($valueExpression, $cleanType.fromJson)";
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

      buffer.writeln('      ${field.name}: $conversion,');
    }

    buffer.writeln('    );');
    buffer.writeln('  }');
  }
}
