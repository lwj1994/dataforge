import 'package:collection/collection.dart';

class ParseResult {
  final String outputPath;
  final String partOf;
  final List<ClassInfo> classes;

  ParseResult(this.outputPath, this.partOf, this.classes);

  @override
  String toString() {
    return 'ParseResult{outputPath: $outputPath, partOf: $partOf, classes: $classes, }';
  }
}

class ClassInfo {
  final String name;
  final String mixinName;
  final List<FieldInfo> fields;
  final bool includeFromJson;
  final bool includeToJson;
  final List<String> genericParameters;

  const ClassInfo({
    required this.name,
    required this.mixinName,
    required this.fields,
    this.includeFromJson = true,
    this.includeToJson = true,
    this.genericParameters = const [],
  });

  ClassInfo copyWith({
    String? name,
    String? mixinName,
    List<FieldInfo>? fields,
    bool? includeFromJson,
    bool? includeToJson,
    List<String>? genericParameters,
  }) {
    return ClassInfo(
      name: name ?? this.name,
      mixinName: mixinName ?? this.mixinName,
      fields: fields ?? this.fields,
      includeFromJson: includeFromJson ?? this.includeFromJson,
      includeToJson: includeToJson ?? this.includeToJson,
      genericParameters: genericParameters ?? this.genericParameters,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'mixinName': mixinName,
      'fields': fields.map((x) => x.toMap()).toList(),
      'includeFromJson': includeFromJson,
      'includeToJson': includeToJson,
      'genericParameters': genericParameters,
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
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  @override
  String toString() {
    return 'ClassInfo(name: $name, mixinName: $mixinName, fields: $fields, includeFromJson: $includeFromJson, includeToJson: $includeToJson, genericParameters: $genericParameters)';
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
            .equals(other.genericParameters, genericParameters);
  }

  @override
  int get hashCode => Object.hashAll([
        name,
        mixinName,
        const DeepCollectionEquality().hash(fields),
        includeFromJson,
        includeToJson,
        const DeepCollectionEquality().hash(genericParameters),
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

  const JsonKeyInfo({
    required this.name,
    required this.alternateNames,
    required this.readValue,
    required this.ignore,
    this.converter = '',
    this.includeIfNull,
  });

  JsonKeyInfo copyWith({
    String? name,
    List<String>? alternateNames,
    String? readValue,
    bool? ignore,
    String? converter,
    bool? includeIfNull,
  }) {
    return JsonKeyInfo(
      name: name ?? this.name,
      alternateNames: alternateNames ?? this.alternateNames,
      readValue: readValue ?? this.readValue,
      ignore: ignore ?? this.ignore,
      converter: converter ?? this.converter,
      includeIfNull: includeIfNull ?? this.includeIfNull,
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
    );
  }

  @override
  String toString() {
    return 'JsonKeyInfo(name: $name, alternateNames: $alternateNames, readValue: $readValue, ignore: $ignore, converter: $converter, includeIfNull: $includeIfNull)';
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
        other.includeIfNull == includeIfNull;
  }

  @override
  int get hashCode => Object.hashAll([
        name,
        const DeepCollectionEquality().hash(alternateNames),
        readValue,
        ignore,
        converter,
        includeIfNull,
      ]);
}
