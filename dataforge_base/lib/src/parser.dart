// @author luwenjie on 2026/01/17 14:37:53

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import 'model.dart';

/// Parser for extracting class information from Dart analyzer elements.
///
/// This base parser only depends on `package:analyzer` and can be used
/// without build_runner. Subclasses can extend this to add source_gen
/// or other integrations.
class BaseParser {
  final ClassElement classElement;
  final DartObject annotation;

  final List<ClassInfo> _extraClasses = [];
  final Set<String> _processedClasses = {};

  BaseParser(this.classElement, this.annotation);

  /// Parse the class element and return parse result
  ParseResult? parse() {
    try {
      // Find Dataforge annotation on the main class
      final annotationResult = _findDataforgeAnnotation(classElement);
      if (annotationResult == null) {
        return null;
      }

      final className = classElement.name;
      if (className != null) {
        _processedClasses.add(className);
      }

      final classInfo = _parseClassInfo(
        classElement,
        annotationResult.object,
        annotationResult.prefix,
      );

      final libraryName =
          classElement.library.identifier.split('/').last.split('.').first;

      return ParseResult(
        '',
        libraryName,
        [classInfo, ..._extraClasses],
        [],
        primaryClassName: classElement.name,
      );
    } catch (e, stackTrace) {
      print('Error parsing class: $e\n$stackTrace');
      return null;
    }
  }

  // Helper to extract annotations safely
  List<dynamic> _getAnnotations(Element element) {
    try {
      final meta = element.metadata as dynamic;
      if (meta is List) {
        return meta;
      }
      try {
        return meta.annotations;
      } catch (_) {}
    } catch (e) {
      print('Error accessing metadata for ${element.name}: $e');
    }
    return [];
  }

  // Find @Dataforge annotation on a class
  _AnnotationResult? _findDataforgeAnnotation(ClassElement element) {
    for (final metadata in _getAnnotations(element)) {
      final obj = (metadata as dynamic).computeConstantValue();
      if (obj?.type?.element?.name == 'Dataforge') {
        String? prefix;
        // Try to extract prefix from source
        try {
          if (metadata is ElementAnnotation) {
            final source = metadata.toSource();
            final match = RegExp(r'@(\w+)\.Dataforge').firstMatch(source);
            if (match != null) {
              prefix = match.group(1);
            }
          }
        } catch (e) {
          // Ignore source extraction errors
        }
        return _AnnotationResult(obj!, prefix: prefix);
      }
    }
    return null;
  }

  void _parseExtraClass(ClassElement element, DartObject annotation) {
    final name = element.name;
    if (name == null || _processedClasses.contains(name)) return;
    _processedClasses.add(name);

    // Try to find prefix again to ensure correct metadata
    final annotationResult = _findDataforgeAnnotation(element);

    final info = _parseClassInfo(element, annotation, annotationResult?.prefix);
    _extraClasses.add(info);
  }

  ClassInfo _parseClassInfo(
      ClassElement element, DartObject annotation, String? prefix) {
    final name = _readString(annotation, 'name') ?? '';
    final includeFromJson = _readBool(annotation, 'includeFromJson') ??
        _readBool(annotation, 'fromMap') ??
        true;
    final includeToJson = _readBool(annotation, 'includeToJson') ??
        _readBool(annotation, 'fromMap') ??
        true;
    final deepCopyWith = _readBool(annotation, 'deepCopyWith') ?? true;

    final className = element.name;
    final mixinName = name.isEmpty ? '_$className' : '_$name';

    final genericParameters = _parseGenericParameters(element);
    final fields = _parseFields(element);

    return ClassInfo(
      name: className ?? '',
      mixinName: mixinName,
      fields: fields,
      includeFromJson: includeFromJson,
      includeToJson: includeToJson,
      deepCopyWith: deepCopyWith,
      genericParameters: genericParameters,
      dataforgePrefix: prefix,
    );
  }

  /// Read a string value from DartObject
  String? _readString(DartObject obj, String field) {
    return obj.getField(field)?.toStringValue();
  }

  /// Read a bool value from DartObject
  bool? _readBool(DartObject obj, String field) {
    return obj.getField(field)?.toBoolValue();
  }

  /// Parse generic parameters from class
  List<GenericParameter> _parseGenericParameters(ClassElement element) {
    final params = <GenericParameter>[];

    for (final typeParam in element.typeParameters) {
      final safeName = typeParam.name;

      final bound = typeParam.bound?.getDisplayString();
      params.add(GenericParameter(safeName ?? '', bound));
    }

    return params;
  }

  /// Parse fields from class
  List<FieldInfo> _parseFields(ClassElement element) {
    // Collect parameter defaults and required status from constructors
    final parameterDefaults = <String, String>{};
    final parameterRequired = <String, bool>{};
    for (final constructor in element.constructors) {
      if (!constructor.isFactory) {
        try {
          // Try multiple ways to access parameters for compatibility
          List<dynamic> params = [];
          try {
            params = (constructor as dynamic).parameters;
          } catch (_) {
            try {
              // Try formalParameters (sometimes used in newer APIs)
              params = (constructor as dynamic).formalParameters;
            } catch (_) {}
          }

          for (final parameter in params) {
            // Need to cast to dynamic to access properties if strict
            // type fails
            final p = parameter as dynamic;
            try {
              if (p.hasDefaultValue == true) {
                final val = p.defaultValueCode;
                if (val != null && (p.name as String).isNotEmpty) {
                  parameterDefaults[p.name as String] = val as String;
                }
              }
              if (p.isRequiredNamed == true || p.isRequiredPositional == true) {
                if ((p.name as String).isNotEmpty) {
                  parameterRequired[p.name as String] = true;
                }
              }
            } catch (_) {}
          }

          // Fallback: If no defaults were found via API, try parsing
          // from toString(). This is a heuristic and might not cover
          // all cases, but can help for common patterns.
          if (parameterDefaults.isEmpty && parameterRequired.isEmpty) {
            final signature = constructor.toString();
            // Matches: Type fieldName = defaultValue
            final defaultRegex =
                RegExp(r'(?:[\w\<\>\?]+\s+)?(\w+)\s*=\s*([^,\)]+)');
            for (final match in defaultRegex.allMatches(signature)) {
              final name = match.group(1);
              final value = match.group(2)?.trim();
              if (name != null && value != null) {
                parameterDefaults[name] = value;
              }
            }
            // Matches: required Type fieldName
            final requiredRegex =
                RegExp(r'required\s+(?:[\w\<\>\?]+\s+)?(\w+)');
            for (final match in requiredRegex.allMatches(signature)) {
              final name = match.group(1);
              if (name != null) {
                parameterRequired[name] = true;
              }
            }
          }
        } catch (e) {
          print('Error parsing constructor params: $e');
        }
      }
    }

    final fields = <FieldInfo>[];

    for (final field in element.fields) {
      if (field.isStatic || field.isPrivate || field.isSynthetic) {
        continue;
      }

      final type = field.type.getDisplayString();
      final isFunction = field.type is FunctionType;
      final isRecord = field.type is RecordType;

      final typeElement = field.type.element;
      final isEnum = typeElement is EnumElement;
      final isDateTime = typeElement?.name == 'DateTime' &&
          typeElement?.library?.isDartCore == true;

      bool isDataforge = false;
      if (typeElement is ClassElement) {
        for (final metadata in _getAnnotations(typeElement)) {
          final obj = (metadata as dynamic).computeConstantValue();
          if (obj?.type?.element?.name == 'Dataforge') {
            isDataforge = true;
            _parseExtraClass(typeElement, obj);
            break;
          }
        }
      }

      final fieldName = field.name;
      final defaultValue = parameterDefaults[fieldName] ?? '';
      final isRequired = parameterRequired[fieldName] ?? false;

      JsonKeyInfo? jsonKeyInfo;
      for (final metadata in _getAnnotations(field)) {
        final obj = (metadata as dynamic).computeConstantValue();
        if (obj == null) continue;

        if (obj.type?.element?.name == 'JsonKey') {
          jsonKeyInfo = _parseJsonKeyAnnotation(obj as DartObject);
          break;
        }
      }

      fields.add(FieldInfo(
        name: fieldName ?? '',
        type: type,
        isFinal: field.isFinal,
        isFunction: isFunction,
        isRecord: isRecord,
        isDataforge: isDataforge,
        isEnum: isEnum,
        isDateTime: isDateTime,
        jsonKey: jsonKeyInfo,
        defaultValue: defaultValue,
        isRequired: isRequired,
      ));
    }

    return fields;
  }

  JsonKeyInfo _parseJsonKeyAnnotation(DartObject obj) {
    List<String> alternateNames = [];
    final altNamesField = obj.getField('alternateNames');
    if (altNamesField != null) {
      final altNamesList = altNamesField.toListValue();
      if (altNamesList != null && altNamesList.isNotEmpty) {
        alternateNames = altNamesList
            .map((e) => e.toStringValue() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }

    // Extract toJson function reference
    String toJsonFunc = '';
    final toJsonField = obj.getField('toJson');
    if (toJsonField != null && !toJsonField.isNull) {
      try {
        final func = toJsonField.toFunctionValue();
        toJsonFunc = _getFunctionName(func);
      } catch (_) {}
    }

    // Extract readValue function reference
    String readValueFunc = '';
    final readValueField = obj.getField('readValue');
    if (readValueField != null && !readValueField.isNull) {
      try {
        final func = readValueField.toFunctionValue();
        readValueFunc = _getFunctionName(func);
      } catch (_) {}
    }

    // Extract fromJson function reference
    String fromJsonFunc = '';
    final fromJsonField = obj.getField('fromJson');
    if (fromJsonField != null && !fromJsonField.isNull) {
      try {
        final func = fromJsonField.toFunctionValue();
        fromJsonFunc = _getFunctionName(func);
      } catch (_) {}
    }

    return JsonKeyInfo(
      name: obj.getField('name')?.toStringValue() ?? '',
      alternateNames: alternateNames,
      readValue: readValueFunc,
      ignore: obj.getField('ignore')?.toBoolValue() ?? false,
      converter: (obj.getField('converter')?.isNull == false)
          ? obj
                  .getField('converter')
                  ?.type
                  ?.getDisplayString(withNullability: false) ??
              ''
          : '',
      includeIfNull: obj.getField('includeIfNull')?.toBoolValue(),
      fromJson: fromJsonFunc,
      toJson: toJsonFunc,
    );
  }

  String _getFunctionName(ExecutableElement? func) {
    if (func == null) return '';
    if (func is MethodElement && func.isStatic) {
      final className = func.enclosingElement?.name;
      // In older analyzer versions, enclosingElement.name might be null or implement differently
      // But typically for MethodElement it's a ClassElement so it has a name.
      if (className != null && className.isNotEmpty) {
        return '$className.${func.name}';
      }
    }
    return func.name ?? '';
  }
}

class _AnnotationResult {
  final DartObject object;
  final String? prefix;
  _AnnotationResult(this.object, {this.prefix});
}
