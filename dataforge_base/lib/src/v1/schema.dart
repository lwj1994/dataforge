import 'package:collection/collection.dart';

/// Resolves source names for symbols stored in a v1 schema.
///
/// A schema stores only stable symbol identity. Import prefixes belong to the
/// later rendering context.
typedef SymbolNameResolver = String Function(SymbolId symbol);

const DeepCollectionEquality _deepEquality = DeepCollectionEquality();

Never _formatError(String path, Object? value, String expected) {
  throw FormatException(
    'Invalid v1 schema value at "$path": expected $expected, got $value.',
  );
}

String _readString(Map<String, Object?> map, String key, String path) {
  final value = map[key];
  if (value is String) return value;
  return _formatError('$path.$key', value, 'String');
}

String? _readNullableString(Map<String, Object?> map, String key, String path) {
  final value = map[key];
  if (value == null || value is String) return value as String?;
  return _formatError('$path.$key', value, 'String?');
}

bool _readBool(Map<String, Object?> map, String key, String path) {
  final value = map[key];
  if (value is bool) return value;
  return _formatError('$path.$key', value, 'bool');
}

int _readInt(Map<String, Object?> map, String key, String path) {
  final value = map[key];
  if (value is int) return value;
  return _formatError('$path.$key', value, 'int');
}

Map<String, Object?> _readMap(Object? value, String path) {
  if (value is! Map) {
    return _formatError(path, value, 'Map<String, Object?>');
  }

  final result = <String, Object?>{};
  for (final entry in value.entries) {
    final key = entry.key;
    if (key is! String) {
      return _formatError('$path.<key>', key, 'String');
    }
    result[key] = entry.value;
  }
  return result;
}

List<Object?> _readList(Object? value, String path) {
  if (value is List) return List<Object?>.from(value);
  return _formatError(path, value, 'List<Object?>');
}

List<String> _readStringList(Object? value, String path) {
  final values = _readList(value, path);
  return List<String>.unmodifiable(
    values.indexed.map((entry) {
      final (index, item) = entry;
      if (item is String) return item;
      return _formatError('$path[$index]', item, 'String');
    }),
  );
}

T _enumByName<T extends Enum>(List<T> values, Object? value, String path) {
  if (value is String) {
    for (final candidate in values) {
      if (candidate.name == value) return candidate;
    }
  }
  return _formatError(path, value, values.map((e) => e.name).join('|'));
}

/// Stable identity of any Dart declaration.
///
/// Import prefixes are excluded because they belong to a source file's render
/// context, not to symbol identity.
final class SymbolId {
  final String libraryUri;
  final String name;

  const SymbolId({required this.libraryUri, required this.name})
    : assert(libraryUri != ''),
      assert(name != '');

  String get canonicalName => '$libraryUri::$name';

  Map<String, Object?> toMap() => {'libraryUri': libraryUri, 'name': name};

  factory SymbolId.fromMap(Map<String, Object?> map) {
    return SymbolId(
      libraryUri: _readString(map, 'libraryUri', r'$.symbol'),
      name: _readString(map, 'name', r'$.symbol'),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SymbolId &&
            other.libraryUri == libraryUri &&
            other.name == name;
  }

  @override
  int get hashCode => Object.hash(libraryUri, name);

  @override
  String toString() => canonicalName;
}

/// Stable identity of a Dataforge model schema.
final class SchemaId {
  final String libraryUri;
  final String name;

  const SchemaId({required this.libraryUri, required this.name})
    : assert(libraryUri != ''),
      assert(name != '');

  String get canonicalName => '$libraryUri::$name';

  SymbolId get symbol => SymbolId(libraryUri: libraryUri, name: name);

  Map<String, Object?> toMap() => {'libraryUri': libraryUri, 'name': name};

  factory SchemaId.fromMap(Map<String, Object?> map) {
    return SchemaId(
      libraryUri: _readString(map, 'libraryUri', r'$.schemaId'),
      name: _readString(map, 'name', r'$.schemaId'),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SchemaId &&
            other.libraryUri == libraryUri &&
            other.name == name;
  }

  @override
  int get hashCode => Object.hash(libraryUri, name);

  @override
  String toString() => canonicalName;
}

/// Stable scalar kinds whose enum member names define the wire names.
enum ScalarKind {
  dynamicType('dynamic'),
  object('Object'),
  string('String'),
  boolean('bool'),
  integer('int'),
  doublePrecision('double'),
  number('num'),
  never('Never'),
  voidType('void');

  final String dartType;

  const ScalarKind(this.dartType);
}

/// Analyzer-independent recursive type structure.
sealed class TypeShape {
  const TypeShape();

  String get kind;

  Map<String, Object?> toMap();

  /// Renders a type use; declaration bounds never leak into type arguments.
  String toDartType({SymbolNameResolver? resolveSymbol}) {
    return renderDartType(resolveSymbol ?? (symbol) => symbol.name);
  }

  String renderDartType(SymbolNameResolver resolveSymbol);

  static TypeShape fromMap(Map<String, Object?> map) {
    final kind = _readString(map, 'kind', r'$.typeShape');
    switch (kind) {
      case 'nullable':
        return NullableShape(
          TypeShape.fromMap(_readMap(map['inner'], r'$.typeShape.inner')),
        );
      case 'scalar':
        return ScalarShape(
          _enumByName(
            ScalarKind.values,
            map['scalarKind'],
            r'$.typeShape.scalarKind',
          ),
        );
      case 'enum':
        return EnumShape(
          SymbolId.fromMap(_readMap(map['symbol'], r'$.typeShape.symbol')),
        );
      case 'dateTime':
        return const DateTimeShape();
      case 'duration':
        return const DurationShape();
      case 'model':
        return ModelShape(
          SchemaId.fromMap(_readMap(map['modelId'], r'$.typeShape.modelId')),
          typeArguments: _readTypeShapeList(
            map['typeArguments'],
            r'$.typeShape.typeArguments',
          ),
          witnessArguments: _readTypeShapeList(
            map['witnessArguments'],
            r'$.typeShape.witnessArguments',
          ),
          includeFromJson: map['includeFromJson'] == null
              ? true
              : _readBool(map, 'includeFromJson', r'$.typeShape'),
          includeToJson: map['includeToJson'] == null
              ? true
              : _readBool(map, 'includeToJson', r'$.typeShape'),
        );
      case 'typeParameter':
        return TypeParameterShape(_readString(map, 'name', r'$.typeShape'));
      case 'list':
        return ListShape(
          TypeShape.fromMap(_readMap(map['element'], r'$.typeShape.element')),
        );
      case 'set':
        return SetShape(
          TypeShape.fromMap(_readMap(map['element'], r'$.typeShape.element')),
        );
      case 'map':
        return MapShape(
          key: TypeShape.fromMap(_readMap(map['key'], r'$.typeShape.key')),
          value: TypeShape.fromMap(
            _readMap(map['value'], r'$.typeShape.value'),
          ),
        );
      case 'record':
        final namedMap = _readMap(map['named'], r'$.typeShape.named');
        return RecordShape(
          positional: _readTypeShapeList(
            map['positional'],
            r'$.typeShape.positional',
          ),
          named: Map<String, TypeShape>.fromEntries(
            namedMap.entries.map(
              (entry) => MapEntry(
                entry.key,
                TypeShape.fromMap(
                  _readMap(entry.value, r'$.typeShape.named.' + entry.key),
                ),
              ),
            ),
          ),
        );
      case 'custom':
        return CustomShape(
          SymbolId.fromMap(_readMap(map['symbol'], r'$.typeShape.symbol')),
          typeArguments: _readTypeShapeList(
            map['typeArguments'],
            r'$.typeShape.typeArguments',
          ),
        );
      default:
        return _formatError(r'$.typeShape.kind', kind, 'known TypeShape kind');
    }
  }

  static List<TypeShape> _readTypeShapeList(Object? value, String path) {
    final list = _readList(value, path);
    return List<TypeShape>.unmodifiable(
      list.indexed.map((entry) {
        final (index, item) = entry;
        return TypeShape.fromMap(_readMap(item, '$path[$index]'));
      }),
    );
  }
}

final class NullableShape extends TypeShape {
  final TypeShape inner;

  const NullableShape(this.inner);

  @override
  String get kind => 'nullable';

  @override
  String renderDartType(SymbolNameResolver resolveSymbol) {
    return '${inner.renderDartType(resolveSymbol)}?';
  }

  @override
  Map<String, Object?> toMap() => {'kind': kind, 'inner': inner.toMap()};

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is NullableShape && other.inner == inner;

  @override
  int get hashCode => Object.hash(kind, inner);
}

final class ScalarShape extends TypeShape {
  final ScalarKind scalarKind;

  const ScalarShape(this.scalarKind);

  @override
  String get kind => 'scalar';

  @override
  String renderDartType(SymbolNameResolver resolveSymbol) =>
      scalarKind.dartType;

  @override
  Map<String, Object?> toMap() => {'kind': kind, 'scalarKind': scalarKind.name};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScalarShape && other.scalarKind == scalarKind;

  @override
  int get hashCode => Object.hash(kind, scalarKind);
}

final class EnumShape extends TypeShape {
  final SymbolId symbol;

  const EnumShape(this.symbol);

  @override
  String get kind => 'enum';

  @override
  String renderDartType(SymbolNameResolver resolveSymbol) =>
      resolveSymbol(symbol);

  @override
  Map<String, Object?> toMap() => {'kind': kind, 'symbol': symbol.toMap()};

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is EnumShape && other.symbol == symbol;

  @override
  int get hashCode => Object.hash(kind, symbol);
}

/// Dedicated DateTime node, avoiding lossy boolean flags in DTO round trips.
final class DateTimeShape extends TypeShape {
  const DateTimeShape();

  @override
  String get kind => 'dateTime';

  @override
  String renderDartType(SymbolNameResolver resolveSymbol) => 'DateTime';

  @override
  Map<String, Object?> toMap() => {'kind': kind};

  @override
  bool operator ==(Object other) => other is DateTimeShape;

  @override
  int get hashCode => kind.hashCode;
}

/// Dedicated node for immutable Duration values with a built-in v1 codec.
final class DurationShape extends TypeShape {
  const DurationShape();

  @override
  String get kind => 'duration';

  @override
  String renderDartType(SymbolNameResolver resolveSymbol) => 'Duration';

  @override
  Map<String, Object?> toMap() => {'kind': kind};

  @override
  bool operator ==(Object other) => other is DurationShape;

  @override
  int get hashCode => kind.hashCode;
}

final class ModelShape extends TypeShape {
  final SchemaId modelId;
  final List<TypeShape> typeArguments;
  final bool includeFromJson;
  final bool includeToJson;

  /// Witness types passed to the target model's public `$ModelType`, in
  /// declaration order.
  ///
  /// These are complete type trees instantiated with [typeArguments]. For
  /// example, if `Box<T>` declares `DataforgeType<List<T>>`, a `Box<Money>`
  /// field stores `List<Money>` here. The writer never reverse-engineers the
  /// target signature.
  final List<TypeShape> witnessArguments;

  ModelShape(
    this.modelId, {
    List<TypeShape> typeArguments = const [],
    List<TypeShape> witnessArguments = const [],
    this.includeFromJson = true,
    this.includeToJson = true,
  }) : typeArguments = List<TypeShape>.unmodifiable(typeArguments),
       witnessArguments = List<TypeShape>.unmodifiable(witnessArguments);

  @override
  String get kind => 'model';

  @override
  String renderDartType(SymbolNameResolver resolveSymbol) {
    final name = resolveSymbol(modelId.symbol);
    return _renderParameterizedType(name, typeArguments, resolveSymbol);
  }

  @override
  Map<String, Object?> toMap() => {
    'kind': kind,
    'modelId': modelId.toMap(),
    'typeArguments': typeArguments.map((shape) => shape.toMap()).toList(),
    'witnessArguments': witnessArguments.map((shape) => shape.toMap()).toList(),
    'includeFromJson': includeFromJson,
    'includeToJson': includeToJson,
  };

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ModelShape &&
            other.modelId == modelId &&
            _deepEquality.equals(other.typeArguments, typeArguments) &&
            _deepEquality.equals(other.witnessArguments, witnessArguments) &&
            other.includeFromJson == includeFromJson &&
            other.includeToJson == includeToJson;
  }

  @override
  int get hashCode => Object.hash(
    kind,
    modelId,
    _deepEquality.hash(typeArguments),
    _deepEquality.hash(witnessArguments),
    includeFromJson,
    includeToJson,
  );
}

final class TypeParameterShape extends TypeShape {
  final String name;

  const TypeParameterShape(this.name) : assert(name != '');

  @override
  String get kind => 'typeParameter';

  @override
  String renderDartType(SymbolNameResolver resolveSymbol) => name;

  @override
  Map<String, Object?> toMap() => {'kind': kind, 'name': name};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypeParameterShape && other.name == name;

  @override
  int get hashCode => Object.hash(kind, name);
}

final class ListShape extends TypeShape {
  final TypeShape element;

  const ListShape(this.element);

  @override
  String get kind => 'list';

  @override
  String renderDartType(SymbolNameResolver resolveSymbol) =>
      'List<${element.renderDartType(resolveSymbol)}>';

  @override
  Map<String, Object?> toMap() => {'kind': kind, 'element': element.toMap()};

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ListShape && other.element == element;

  @override
  int get hashCode => Object.hash(kind, element);
}

final class SetShape extends TypeShape {
  final TypeShape element;

  const SetShape(this.element);

  @override
  String get kind => 'set';

  @override
  String renderDartType(SymbolNameResolver resolveSymbol) =>
      'Set<${element.renderDartType(resolveSymbol)}>';

  @override
  Map<String, Object?> toMap() => {'kind': kind, 'element': element.toMap()};

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SetShape && other.element == element;

  @override
  int get hashCode => Object.hash(kind, element);
}

final class MapShape extends TypeShape {
  final TypeShape key;
  final TypeShape value;

  const MapShape({required this.key, required this.value});

  @override
  String get kind => 'map';

  @override
  String renderDartType(SymbolNameResolver resolveSymbol) {
    return 'Map<${key.renderDartType(resolveSymbol)}, '
        '${value.renderDartType(resolveSymbol)}>';
  }

  @override
  Map<String, Object?> toMap() => {
    'kind': kind,
    'key': key.toMap(),
    'value': value.toMap(),
  };

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MapShape && other.key == key && other.value == value;
  }

  @override
  int get hashCode => Object.hash(kind, key, value);
}

final class RecordShape extends TypeShape {
  final List<TypeShape> positional;
  final Map<String, TypeShape> named;

  RecordShape({
    List<TypeShape> positional = const [],
    Map<String, TypeShape> named = const {},
  }) : positional = List<TypeShape>.unmodifiable(positional),
       named = Map<String, TypeShape>.unmodifiable(named);

  @override
  String get kind => 'record';

  @override
  String renderDartType(SymbolNameResolver resolveSymbol) {
    final pieces = positional
        .map((shape) => shape.renderDartType(resolveSymbol))
        .toList();
    if (named.isNotEmpty) {
      final namedFields = named.entries
          .map(
            (entry) =>
                '${entry.value.renderDartType(resolveSymbol)} ${entry.key}',
          )
          .join(', ');
      pieces.add('{$namedFields}');
    }
    if (positional.length == 1 && named.isEmpty) {
      return '(${pieces.single},)';
    }
    return '(${pieces.join(', ')})';
  }

  @override
  Map<String, Object?> toMap() => {
    'kind': kind,
    'positional': positional.map((shape) => shape.toMap()).toList(),
    'named': named.map((name, shape) => MapEntry(name, shape.toMap())),
  };

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RecordShape &&
            _deepEquality.equals(other.positional, positional) &&
            _deepEquality.equals(other.named, named);
  }

  @override
  int get hashCode => Object.hash(
    kind,
    _deepEquality.hash(positional),
    _deepEquality.hash(named),
  );
}

final class CustomShape extends TypeShape {
  final SymbolId symbol;
  final List<TypeShape> typeArguments;

  CustomShape(this.symbol, {List<TypeShape> typeArguments = const []})
    : typeArguments = List<TypeShape>.unmodifiable(typeArguments);

  @override
  String get kind => 'custom';

  @override
  String renderDartType(SymbolNameResolver resolveSymbol) {
    final name = resolveSymbol(symbol);
    return _renderParameterizedType(name, typeArguments, resolveSymbol);
  }

  @override
  Map<String, Object?> toMap() => {
    'kind': kind,
    'symbol': symbol.toMap(),
    'typeArguments': typeArguments.map((shape) => shape.toMap()).toList(),
  };

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CustomShape &&
            other.symbol == symbol &&
            _deepEquality.equals(other.typeArguments, typeArguments);
  }

  @override
  int get hashCode =>
      Object.hash(kind, symbol, _deepEquality.hash(typeArguments));
}

String _renderParameterizedType(
  String name,
  List<TypeShape> arguments,
  SymbolNameResolver resolveSymbol,
) {
  if (arguments.isEmpty) return name;
  return '$name<${arguments.map((shape) => shape.renderDartType(resolveSymbol)).join(', ')}>';
}

/// Generic declaration metadata. Bounds render only in declarations; type uses
/// always render [name] alone.
final class TypeParameterSchema {
  final String name;
  final TypeShape? bound;

  const TypeParameterSchema({required this.name, this.bound})
    : assert(name != '');

  String toDeclaration({SymbolNameResolver? resolveSymbol}) {
    if (bound == null) return name;
    return '$name extends '
        '${bound!.toDartType(resolveSymbol: resolveSymbol)}';
  }

  String toUse() => name;

  Map<String, Object?> toMap() => {'name': name, 'bound': bound?.toMap()};

  factory TypeParameterSchema.fromMap(Map<String, Object?> map) {
    final boundValue = map['bound'];
    return TypeParameterSchema(
      name: _readString(map, 'name', r'$.typeParameter'),
      bound: boundValue == null
          ? null
          : TypeShape.fromMap(_readMap(boundValue, r'$.typeParameter.bound')),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TypeParameterSchema &&
            other.name == name &&
            other.bound == bound;
  }

  @override
  int get hashCode => Object.hash(name, bound);
}

enum ConstructorKind { generative, factory, redirectingFactory }

enum ParameterKind {
  requiredPositional,
  optionalPositional,
  requiredNamed,
  optionalNamed,
}

final class ConstructorParameterSchema {
  final String name;
  final TypeShape shape;
  final ParameterKind kind;
  final String? defaultValueCode;
  final String? fieldName;

  const ConstructorParameterSchema({
    required this.name,
    required this.shape,
    required this.kind,
    this.defaultValueCode,
    this.fieldName,
  }) : assert(name != '');

  Map<String, Object?> toMap() => {
    'name': name,
    'shape': shape.toMap(),
    'kind': kind.name,
    'defaultValueCode': defaultValueCode,
    'fieldName': fieldName,
  };

  factory ConstructorParameterSchema.fromMap(Map<String, Object?> map) {
    return ConstructorParameterSchema(
      name: _readString(map, 'name', r'$.constructorParameter'),
      shape: TypeShape.fromMap(
        _readMap(map['shape'], r'$.constructorParameter.shape'),
      ),
      kind: _enumByName(
        ParameterKind.values,
        map['kind'],
        r'$.constructorParameter.kind',
      ),
      defaultValueCode: _readNullableString(
        map,
        'defaultValueCode',
        r'$.constructorParameter',
      ),
      fieldName: _readNullableString(
        map,
        'fieldName',
        r'$.constructorParameter',
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ConstructorParameterSchema &&
            other.name == name &&
            other.shape == shape &&
            other.kind == kind &&
            other.defaultValueCode == defaultValueCode &&
            other.fieldName == fieldName;
  }

  @override
  int get hashCode =>
      Object.hash(name, shape, kind, defaultValueCode, fieldName);
}

final class ConstructorSchema {
  final String name;
  final ConstructorKind kind;
  final bool isConst;
  final List<ConstructorParameterSchema> parameters;

  ConstructorSchema({
    this.name = '',
    required this.kind,
    this.isConst = false,
    List<ConstructorParameterSchema> parameters = const [],
  }) : parameters = List<ConstructorParameterSchema>.unmodifiable(parameters);

  Map<String, Object?> toMap() => {
    'name': name,
    'kind': kind.name,
    'isConst': isConst,
    'parameters': parameters.map((parameter) => parameter.toMap()).toList(),
  };

  factory ConstructorSchema.fromMap(Map<String, Object?> map) {
    final parameters = _readList(
      map['parameters'],
      r'$.constructor.parameters',
    );
    return ConstructorSchema(
      name: _readString(map, 'name', r'$.constructor'),
      kind: _enumByName(
        ConstructorKind.values,
        map['kind'],
        r'$.constructor.kind',
      ),
      isConst: _readBool(map, 'isConst', r'$.constructor'),
      parameters: parameters.indexed.map((entry) {
        final (index, value) = entry;
        return ConstructorParameterSchema.fromMap(
          _readMap(value, r'$.constructor.parameters[' + '$index]'),
        );
      }).toList(),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ConstructorSchema &&
            other.name == name &&
            other.kind == kind &&
            other.isConst == isConst &&
            _deepEquality.equals(other.parameters, parameters);
  }

  @override
  int get hashCode =>
      Object.hash(name, kind, isConst, _deepEquality.hash(parameters));
}

final class FieldSchema {
  final String name;
  final TypeShape shape;
  final bool isFinal;
  final bool isRequired;
  final String jsonName;
  final List<String> alternateJsonNames;
  final String? defaultValueCode;
  final bool includeFromJson;
  final bool includeToJson;
  final bool? includeIfNull;

  FieldSchema({
    required this.name,
    required this.shape,
    this.isFinal = true,
    this.isRequired = false,
    String? jsonName,
    List<String> alternateJsonNames = const [],
    this.defaultValueCode,
    this.includeFromJson = true,
    this.includeToJson = true,
    this.includeIfNull,
  }) : jsonName = jsonName ?? name,
       alternateJsonNames = List<String>.unmodifiable(alternateJsonNames),
       assert(name != '');

  Map<String, Object?> toMap() => {
    'name': name,
    'shape': shape.toMap(),
    'isFinal': isFinal,
    'isRequired': isRequired,
    'jsonName': jsonName,
    'alternateJsonNames': alternateJsonNames,
    'defaultValueCode': defaultValueCode,
    'includeFromJson': includeFromJson,
    'includeToJson': includeToJson,
    'includeIfNull': includeIfNull,
  };

  factory FieldSchema.fromMap(Map<String, Object?> map) {
    final includeIfNullValue = map['includeIfNull'];
    if (includeIfNullValue != null && includeIfNullValue is! bool) {
      _formatError(r'$.field.includeIfNull', includeIfNullValue, 'bool?');
    }
    return FieldSchema(
      name: _readString(map, 'name', r'$.field'),
      shape: TypeShape.fromMap(_readMap(map['shape'], r'$.field.shape')),
      isFinal: _readBool(map, 'isFinal', r'$.field'),
      isRequired: _readBool(map, 'isRequired', r'$.field'),
      jsonName: _readString(map, 'jsonName', r'$.field'),
      alternateJsonNames: _readStringList(
        map['alternateJsonNames'],
        r'$.field.alternateJsonNames',
      ),
      defaultValueCode: _readNullableString(
        map,
        'defaultValueCode',
        r'$.field',
      ),
      includeFromJson: _readBool(map, 'includeFromJson', r'$.field'),
      includeToJson: _readBool(map, 'includeToJson', r'$.field'),
      includeIfNull: includeIfNullValue as bool?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FieldSchema &&
            other.name == name &&
            other.shape == shape &&
            other.isFinal == isFinal &&
            other.isRequired == isRequired &&
            other.jsonName == jsonName &&
            _deepEquality.equals(
              other.alternateJsonNames,
              alternateJsonNames,
            ) &&
            other.defaultValueCode == defaultValueCode &&
            other.includeFromJson == includeFromJson &&
            other.includeToJson == includeToJson &&
            other.includeIfNull == includeIfNull;
  }

  @override
  int get hashCode => Object.hashAll([
    name,
    shape,
    isFinal,
    isRequired,
    jsonName,
    _deepEquality.hash(alternateJsonNames),
    defaultValueCode,
    includeFromJson,
    includeToJson,
    includeIfNull,
  ]);
}

/// Complete versioned schema for one Dataforge v1 model.
final class ModelSchema {
  static const int currentFormatVersion = 1;

  final int formatVersion;
  final SchemaId id;
  final String implementationName;
  final List<TypeParameterSchema> typeParameters;
  final ConstructorSchema constructor;
  final List<FieldSchema> fields;
  final bool includeFromJson;
  final bool includeToJson;
  final bool generateCopyWith;
  final bool deepFreeze;

  ModelSchema({
    this.formatVersion = currentFormatVersion,
    required this.id,
    required this.implementationName,
    List<TypeParameterSchema> typeParameters = const [],
    required this.constructor,
    List<FieldSchema> fields = const [],
    this.includeFromJson = true,
    this.includeToJson = true,
    this.generateCopyWith = true,
    this.deepFreeze = true,
  }) : typeParameters = List<TypeParameterSchema>.unmodifiable(typeParameters),
       fields = List<FieldSchema>.unmodifiable(fields),
       assert(formatVersion == currentFormatVersion),
       assert(implementationName != '');

  Map<String, Object?> toMap() => {
    'formatVersion': formatVersion,
    'id': id.toMap(),
    'implementationName': implementationName,
    'typeParameters': typeParameters
        .map((parameter) => parameter.toMap())
        .toList(),
    'constructor': constructor.toMap(),
    'fields': fields.map((field) => field.toMap()).toList(),
    'includeFromJson': includeFromJson,
    'includeToJson': includeToJson,
    'generateCopyWith': generateCopyWith,
    'deepFreeze': deepFreeze,
  };

  factory ModelSchema.fromMap(Map<String, Object?> map) {
    final version = _readInt(map, 'formatVersion', r'$.modelSchema');
    if (version != currentFormatVersion) {
      throw FormatException(
        'Unsupported Dataforge schema format version $version; '
        'expected $currentFormatVersion.',
      );
    }

    final typeParameters = _readList(
      map['typeParameters'],
      r'$.modelSchema.typeParameters',
    );
    final fields = _readList(map['fields'], r'$.modelSchema.fields');
    return ModelSchema(
      formatVersion: version,
      id: SchemaId.fromMap(_readMap(map['id'], r'$.modelSchema.id')),
      implementationName: _readString(
        map,
        'implementationName',
        r'$.modelSchema',
      ),
      typeParameters: typeParameters.indexed.map((entry) {
        final (index, value) = entry;
        return TypeParameterSchema.fromMap(
          _readMap(value, r'$.modelSchema.typeParameters[' + '$index]'),
        );
      }).toList(),
      constructor: ConstructorSchema.fromMap(
        _readMap(map['constructor'], r'$.modelSchema.constructor'),
      ),
      fields: fields.indexed.map((entry) {
        final (index, value) = entry;
        return FieldSchema.fromMap(
          _readMap(value, r'$.modelSchema.fields[' + '$index]'),
        );
      }).toList(),
      includeFromJson: _readBool(map, 'includeFromJson', r'$.modelSchema'),
      includeToJson: _readBool(map, 'includeToJson', r'$.modelSchema'),
      generateCopyWith: _readBool(map, 'generateCopyWith', r'$.modelSchema'),
      deepFreeze: _readBool(map, 'deepFreeze', r'$.modelSchema'),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ModelSchema &&
            other.formatVersion == formatVersion &&
            other.id == id &&
            other.implementationName == implementationName &&
            _deepEquality.equals(other.typeParameters, typeParameters) &&
            other.constructor == constructor &&
            _deepEquality.equals(other.fields, fields) &&
            other.includeFromJson == includeFromJson &&
            other.includeToJson == includeToJson &&
            other.generateCopyWith == generateCopyWith &&
            other.deepFreeze == deepFreeze;
  }

  @override
  int get hashCode => Object.hashAll([
    formatVersion,
    id,
    implementationName,
    _deepEquality.hash(typeParameters),
    constructor,
    _deepEquality.hash(fields),
    includeFromJson,
    includeToJson,
    generateCopyWith,
    deepFreeze,
  ]);
}
