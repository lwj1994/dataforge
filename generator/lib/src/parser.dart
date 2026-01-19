// @author luwenjie on 2026/01/17 14:37:53

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

import 'model.dart';

/// Parser for extracting class information from Dart analyzer elements
class GeneratorParser {
  final ClassElement classElement;
  final ConstantReader annotation;

  GeneratorParser(this.classElement, this.annotation);

  /// Parse the class element and return parse result
  ParseResult? parse() {
    try {
      final classes = <ClassInfo>[];

      // Use LibraryReader to safely access classes in the library
      final reader = LibraryReader(classElement.library);
      for (final element in reader.classes) {
        final annotationResult = _findDataforgeAnnotation(element);
        if (annotationResult != null) {
          final classInfo = _parseClassInfo(element,
              ConstantReader(annotationResult.object), annotationResult.prefix);
          classes.add(classInfo);
        }
      }

      if (classes.isEmpty) {
        return null;
      }

      final libraryName =
          classElement.library.identifier.split('/').last.split('.').first;

      return ParseResult(
        '',
        libraryName,
        classes,
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

  ClassInfo _parseClassInfo(
      ClassElement element, ConstantReader annotation, String? prefix) {
    final name = annotation.peek('name')?.stringValue ?? '';
    final includeFromJson = annotation.peek('includeFromJson')?.boolValue ??
        annotation.peek('fromMap')?.boolValue ??
        true;
    final includeToJson = annotation.peek('includeToJson')?.boolValue ??
        annotation.peek('fromMap')?.boolValue ??
        true;
    final deepCopyWith = annotation.peek('deepCopyWith')?.boolValue ?? true;

    final className = element.name ?? '';
    final mixinName = name.isEmpty ? '_$className' : '_$name';

    final genericParameters = _parseGenericParameters(element);
    final fields = _parseFields(element);

    return ClassInfo(
      name: className,
      mixinName: mixinName,
      fields: fields,
      includeFromJson: includeFromJson,
      includeToJson: includeToJson,
      deepCopyWith: deepCopyWith,
      genericParameters: genericParameters,
      dataforgePrefix: prefix,
    );
  }

  /// Parse generic parameters from class
  List<GenericParameter> _parseGenericParameters(ClassElement element) {
    final params = <GenericParameter>[];

    for (final typeParam in element.typeParameters) {
      final name = typeParam.name; // In analyzer 8+, name is nullable?
      final safeName = name ?? '';

      final bound = typeParam.bound?.getDisplayString(withNullability: true);
      params.add(GenericParameter(safeName, bound));
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
            // Need to cast to dynamic to access properties if strict type fails
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

          // Fallback: If no defaults were found via API, try parsing from toString()
          // This is a heuristic and might not cover all cases, but can help for common patterns.
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

      final type = field.type.getDisplayString(withNullability: true);
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
            break;
          }
        }
      }

      final fieldName = field.name ?? '';
      final defaultValue = parameterDefaults[fieldName] ?? '';
      final isRequired = parameterRequired[fieldName] ?? false;

      JsonKeyInfo? jsonKeyInfo;
      for (final metadata in _getAnnotations(field)) {
        final obj = (metadata as dynamic).computeConstantValue();
        if (obj == null) continue;

        if (obj.type?.element?.name == 'JsonKey') {
          jsonKeyInfo = _parseJsonKeyAnnotation(ConstantReader(obj));
          break;
        }
      }

      fields.add(FieldInfo(
        name: fieldName,
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

  JsonKeyInfo _parseJsonKeyAnnotation(ConstantReader reader) {
    List<String> alternateNames = [];
    final altNamesObj = reader.peek('alternateNames');
    if (altNamesObj != null && altNamesObj.listValue.isNotEmpty) {
      alternateNames = altNamesObj.listValue
          .map((e) => e.toStringValue() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }

    // Extract fromJson function reference
    String fromJsonFunc = '';
    final fromJsonObj = reader.peek('fromJson');
    if (fromJsonObj != null && !fromJsonObj.isNull) {
      try {
        fromJsonFunc = fromJsonObj.revive().accessor;
      } catch (_) {
        // If revive fails, try to get the function name from the type
      }
    }

    // Extract toJson function reference
    String toJsonFunc = '';
    final toJsonObj = reader.peek('toJson');
    if (toJsonObj != null && !toJsonObj.isNull) {
      try {
        toJsonFunc = toJsonObj.revive().accessor;
      } catch (_) {
        // If revive fails, try to get the function name from the type
      }
    }

    return JsonKeyInfo(
      name: reader.peek('name')?.stringValue ?? '',
      alternateNames: alternateNames,
      readValue: reader.peek('readValue')?.revive().accessor ?? '',
      ignore: reader.peek('ignore')?.boolValue ?? false,
      converter: reader
              .peek('converter')
              ?.objectValue
              .type
              ?.getDisplayString(withNullability: false) ??
          '',
      includeIfNull: reader.peek('includeIfNull')?.boolValue,
      fromJson: fromJsonFunc,
      toJson: toJsonFunc,
    );
  }
}

class _AnnotationResult {
  final DartObject object;
  final String? prefix;
  _AnnotationResult(this.object, {this.prefix});
}
