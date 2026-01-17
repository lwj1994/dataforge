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
        final dataforgeAnnotation = _findDataforgeAnnotation(element);
        if (dataforgeAnnotation != null) {
          final classInfo =
              _parseClassInfo(element, ConstantReader(dataforgeAnnotation));
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
  DartObject? _findDataforgeAnnotation(ClassElement element) {
    for (final metadata in _getAnnotations(element)) {
      final obj = (metadata as dynamic).computeConstantValue();
      if (obj?.type?.element?.name == 'Dataforge') {
        return obj;
      }
    }
    return null;
  }

  ClassInfo _parseClassInfo(ClassElement element, ConstantReader annotation) {
    final name = annotation.peek('name')?.stringValue ?? '';
    final includeFromJson = annotation.peek('includeFromJson')?.boolValue ??
        annotation.peek('fromMap')?.boolValue ??
        true;
    final includeToJson = annotation.peek('includeToJson')?.boolValue ??
        annotation.peek('fromMap')?.boolValue ??
        true;
    final chainedCopyWith =
        annotation.peek('chainedCopyWith')?.boolValue ?? true;

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
      chainedCopyWith: chainedCopyWith,
      genericParameters: genericParameters,
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
    // Collect parameter defaults from constructors
    final parameterDefaults = <String, String>{};
    /*
    for (final constructor in element.constructors) {
      if (!constructor.isFactory) {
        try {
          // Use dynamic cast to bypass potential interface changes or missing legacy mixins
          final params = (constructor as dynamic).parameters; 
          for (final parameter in params) {
            if (parameter.hasDefaultValue == true) { 
               final val = parameter.defaultValueCode;
               if (val != null && parameter.name.isNotEmpty) { 
                  parameterDefaults[parameter.name ?? ''] = val;
               }
            }
          }
        } catch (e) {
          print('Error parsing constructor params: $e');
        }
      }
    }
    */

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

    return JsonKeyInfo(
      name: reader.peek('name')?.stringValue ?? '',
      alternateNames: alternateNames,
      readValue: reader.peek('readValue')?.revive().accessor ?? '',
      ignore: reader.peek('ignore')?.boolValue ?? false,
      converter: '', // Converter parsing not implemented yet
      includeIfNull: reader.peek('includeIfNull')?.boolValue,
      fromJson: reader.peek('fromJson')?.revive().accessor ?? '',
      toJson: reader.peek('toJson')?.revive().accessor ?? '',
    );
  }
}
