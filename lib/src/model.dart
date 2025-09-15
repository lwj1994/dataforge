import 'package:collection/collection.dart';

/// Information about an import statement
class ImportInfo {
  final String uri;
  final String? alias;
  final bool isDeferred;
  final List<String> showCombinators;
  final List<String> hideCombinators;

  const ImportInfo({
    required this.uri,
    this.alias,
    this.isDeferred = false,
    this.showCombinators = const [],
    this.hideCombinators = const [],
  });

  @override
  String toString() {
    return 'ImportInfo{uri: $uri, alias: $alias, isDeferred: $isDeferred, showCombinators: $showCombinators, hideCombinators: $hideCombinators}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImportInfo &&
        other.uri == uri &&
        other.alias == alias &&
        other.isDeferred == isDeferred &&
        const DeepCollectionEquality()
            .equals(other.showCombinators, showCombinators) &&
        const DeepCollectionEquality()
            .equals(other.hideCombinators, hideCombinators);
  }

  @override
  int get hashCode => Object.hashAll([
        uri,
        alias,
        isDeferred,
        const DeepCollectionEquality().hash(showCombinators),
        const DeepCollectionEquality().hash(hideCombinators),
      ]);
}

class ParseResult {
  final String outputPath;
  final String partOf;
  final List<ClassInfo> classes;
  final List<ImportInfo> imports;

  ParseResult(this.outputPath, this.partOf, this.classes,
      [this.imports = const []]);

  @override
  String toString() {
    return 'ParseResult{outputPath: $outputPath, partOf: $partOf, classes: $classes, imports: $imports}';
  }
}

class GenericParameter {
  final String name;
  final String? bound;

  const GenericParameter(this.name, [this.bound]);

  @override
  String toString() => bound != null ? '$name extends $bound' : name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GenericParameter &&
        other.name == name &&
        other.bound == bound;
  }

  @override
  int get hashCode => Object.hash(name, bound);
}

class ClassInfo {
  final String name;
  final String mixinName;
  final List<FieldInfo> fields;
  final bool includeFromJson;
  final bool includeToJson;
  final bool chainedCopyWith;
  final List<GenericParameter> genericParameters;

  const ClassInfo({
    required this.name,
    required this.mixinName,
    required this.fields,
    this.includeFromJson = true,
    this.includeToJson = true,
    this.genericParameters = const [],
    this.chainedCopyWith = true,
  });

  ClassInfo copyWith({
    String? name,
    String? mixinName,
    List<FieldInfo>? fields,
    bool? includeFromJson,
    bool? includeToJson,
    List<GenericParameter>? genericParameters,
    bool? chainedCopyWith,
  }) {
    return ClassInfo(
      name: name ?? this.name,
      mixinName: mixinName ?? this.mixinName,
      fields: fields ?? this.fields,
      includeFromJson: includeFromJson ?? this.includeFromJson,
      includeToJson: includeToJson ?? this.includeToJson,
      genericParameters: genericParameters ?? this.genericParameters,
      chainedCopyWith: chainedCopyWith ?? this.chainedCopyWith,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'mixinName': mixinName,
      'fields': fields.map((x) => x.toMap()).toList(),
      'includeFromJson': includeFromJson,
      'includeToJson': includeToJson,
      'genericParameters': genericParameters
          .map((x) => {'name': x.name, 'bound': x.bound})
          .toList(),
      'chainedCopyWith': chainedCopyWith,
    };
  }

  factory ClassInfo.fromMap(Map<String, dynamic> map) {
    // Support legacy fields for backward compatibility
    final legacyFromMap = map['fromMap'] as bool? ?? true;
    final legacyIncludeFromMap =
        map['includeFromMap'] as bool? ?? legacyFromMap;
    final legacyIncludeToMap = map['includeToMap'] as bool? ?? legacyFromMap;

    return ClassInfo(
      name: map['name'] as String? ?? '',
      mixinName: map['mixinName'] as String? ?? '',
      fields: (map['fields'] as List<dynamic>?)
              ?.map((e) => FieldInfo.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      includeFromJson: map['includeFromJson'] as bool? ?? legacyIncludeFromMap,
      includeToJson: map['includeToJson'] as bool? ?? legacyIncludeToMap,
      genericParameters: (map['genericParameters'] as List<dynamic>?)
              ?.map((e) => e is Map<String, dynamic>
                  ? GenericParameter(e['name'] as String, e['bound'] as String?)
                  : GenericParameter(e.toString()))
              .toList() ??
          [],
      chainedCopyWith: map['chainedCopyWith'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'ClassInfo(name: $name, mixinName: $mixinName, fields: $fields, includeFromJson: $includeFromJson, includeToJson: $includeToJson, genericParameters: $genericParameters, chainedCopyWith: $chainedCopyWith)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClassInfo &&
        other.name == name &&
        other.mixinName == mixinName &&
        const DeepCollectionEquality().equals(other.fields, fields) &&
        other.includeFromJson == includeFromJson &&
        other.includeToJson == includeToJson &&
        const DeepCollectionEquality()
            .equals(other.genericParameters, genericParameters) &&
        other.chainedCopyWith == chainedCopyWith;
  }

  @override
  int get hashCode => Object.hashAll([
        name,
        mixinName,
        const DeepCollectionEquality().hash(fields),
        includeFromJson,
        includeToJson,
        const DeepCollectionEquality().hash(genericParameters),
        chainedCopyWith,
      ]);
}

class FieldInfo {
  final String name;
  final String type;
  final bool isFinal;
  final bool isFunction;
  final JsonKeyInfo? jsonKey;
  final bool isRecord;
  final String defaultValue;

  const FieldInfo({
    required this.name,
    required this.type,
    required this.isFinal,
    required this.isFunction,
    this.jsonKey,
    required this.isRecord,
    required this.defaultValue,
  });

  FieldInfo copyWith({
    String? name,
    String? type,
    bool? isFinal,
    bool? isFunction,
    JsonKeyInfo? jsonKey,
    bool? isRecord,
    String? defaultValue,
  }) {
    return FieldInfo(
      name: name ?? this.name,
      type: type ?? this.type,
      isFinal: isFinal ?? this.isFinal,
      isFunction: isFunction ?? this.isFunction,
      jsonKey: jsonKey ?? this.jsonKey,
      isRecord: isRecord ?? this.isRecord,
      defaultValue: defaultValue ?? this.defaultValue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'isFinal': isFinal,
      'isFunction': isFunction,
      'jsonKey': jsonKey?.toMap(),
      'isRecord': isRecord,
      'defaultValue': defaultValue,
    };
  }

  static FieldInfo fromMap(Map<String, dynamic> map) {
    return FieldInfo(
      name: map['name'] as String? ?? '',
      type: map['type'] as String? ?? 'dynamic',
      isFinal: map['isFinal'] as bool? ?? false,
      isFunction: map['isFunction'] as bool? ?? false,
      jsonKey: map['jsonKey'] != null
          ? JsonKeyInfo.fromMap(map['jsonKey'] as Map<String, dynamic>)
          : null,
      isRecord: map['isRecord'] as bool? ?? false,
      defaultValue: map['defaultValue'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'FieldInfo(name: $name, type: $type, isFinal: $isFinal, isFunction: $isFunction, jsonKey: $jsonKey, isRecord: $isRecord, defaultValue: $defaultValue)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FieldInfo &&
        other.name == name &&
        other.type == type &&
        other.isFinal == isFinal &&
        other.isFunction == isFunction &&
        other.jsonKey == jsonKey &&
        other.isRecord == isRecord &&
        other.defaultValue == defaultValue;
  }

  @override
  int get hashCode => Object.hashAll([
        name,
        type,
        isFinal,
        isFunction,
        jsonKey,
        isRecord,
        defaultValue,
      ]);
}

class JsonKeyInfo {
  final String name;
  final List<String> alternateNames;
  final String readValue;
  final bool ignore;
  final String converter;
  final bool? includeIfNull;
  final String fromJson;
  final String toJson;

  const JsonKeyInfo({
    required this.name,
    required this.alternateNames,
    required this.readValue,
    required this.ignore,
    this.converter = '',
    this.includeIfNull,
    this.fromJson = '',
    this.toJson = '',
  });

  JsonKeyInfo copyWith({
    String? name,
    List<String>? alternateNames,
    String? readValue,
    bool? ignore,
    String? converter,
    bool? includeIfNull,
    String? fromJson,
    String? toJson,
  }) {
    return JsonKeyInfo(
      name: name ?? this.name,
      alternateNames: alternateNames ?? this.alternateNames,
      readValue: readValue ?? this.readValue,
      ignore: ignore ?? this.ignore,
      converter: converter ?? this.converter,
      includeIfNull: includeIfNull ?? this.includeIfNull,
      fromJson: fromJson ?? this.fromJson,
      toJson: toJson ?? this.toJson,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'alternateNames': alternateNames,
      'readValue': readValue,
      'ignore': ignore,
      'converter': converter,
      'includeIfNull': includeIfNull,
      'fromJson': fromJson,
      'toJson': toJson,
    };
  }

  static JsonKeyInfo fromMap(Map<String, dynamic> map) {
    return JsonKeyInfo(
      name: map['name'] as String? ?? '',
      alternateNames: (map['alternateNames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      readValue: map['readValue'] as String? ?? '',
      ignore: map['ignore'] as bool? ?? false,
      converter: map['converter'] as String? ?? '',
      includeIfNull: map['includeIfNull'] as bool?,
      fromJson: map['fromJson'] as String? ?? '',
      toJson: map['toJson'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'JsonKeyInfo(name: $name, alternateNames: $alternateNames, readValue: $readValue, ignore: $ignore, converter: $converter, includeIfNull: $includeIfNull, fromJson: $fromJson, toJson: $toJson)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JsonKeyInfo &&
        other.name == name &&
        const DeepCollectionEquality()
            .equals(other.alternateNames, alternateNames) &&
        other.readValue == readValue &&
        other.ignore == ignore &&
        other.converter == converter &&
        other.includeIfNull == includeIfNull &&
        other.fromJson == fromJson &&
        other.toJson == toJson;
  }

  @override
  int get hashCode => Object.hashAll([
        name,
        const DeepCollectionEquality().hash(alternateNames),
        readValue,
        ignore,
        converter,
        includeIfNull,
        fromJson,
        toJson,
      ]);
}

/// Represents a flattened field path for nested copyWith operations
class FlattenedField {
  /// The full path of the field (e.g., "ceo_address_street")
  final String path;

  /// The original field name (e.g., "street")
  final String fieldName;

  /// The type of the field
  final String type;

  /// The original FieldInfo object
  final FieldInfo originalField;

  const FlattenedField({
    required this.path,
    required this.fieldName,
    required this.type,
    required this.originalField,
  });

  @override
  String toString() {
    return 'FlattenedField{path: $path, fieldName: $fieldName, type: $type}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlattenedField &&
        other.path == path &&
        other.fieldName == fieldName &&
        other.type == type &&
        other.originalField == originalField;
  }

  @override
  int get hashCode => Object.hash(path, fieldName, type, originalField);
}
