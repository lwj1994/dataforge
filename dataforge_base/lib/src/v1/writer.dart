import 'dart:convert';

import 'diagnostics.dart';
import 'schema.dart';

const _dartKeywords = <String>{
  'abstract',
  'as',
  'assert',
  'async',
  'await',
  'base',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'covariant',
  'default',
  'deferred',
  'do',
  'dynamic',
  'else',
  'enum',
  'export',
  'extends',
  'extension',
  'external',
  'factory',
  'false',
  'final',
  'finally',
  'for',
  'get',
  'hide',
  'if',
  'implements',
  'import',
  'in',
  'interface',
  'is',
  'late',
  'library',
  'mixin',
  'new',
  'null',
  'of',
  'on',
  'operator',
  'part',
  'required',
  'rethrow',
  'return',
  'sealed',
  'set',
  'show',
  'static',
  'super',
  'switch',
  'sync',
  'this',
  'throw',
  'true',
  'try',
  'typedef',
  'var',
  'void',
  'when',
  'while',
  'with',
  'yield',
};

/// Internal renderer that compiles a validated [ModelSchema] to Dart source.
///
/// This type lives under `src/` and is not exported publicly. CLI,
/// build_runner, and other frontends must use the resolved generation facade
/// instead of constructing schemas manually. The writer still validates one
/// schema defensively, but it is not a public generation entry point.
final class ModelSchemaWriter {
  const ModelSchemaWriter({
    required this.symbolNameResolver,
    this.runtimePrefix = '',
  });

  final SymbolNameResolver symbolNameResolver;

  /// Import prefix for the annotation runtime. `df` and `df.` are equivalent;
  /// an empty string means no prefix.
  final String runtimePrefix;

  String write(ModelSchema schema) {
    final compiler = _ModelCompiler(
      schema: schema,
      symbolNameResolver: symbolNameResolver,
      runtimePrefix: _normalizeRuntimePrefix(runtimePrefix),
    );
    return compiler.write();
  }
}

/// Structured failure for an unsafe or unsupported schema.
final class ModelSchemaWriterException implements Exception {
  const ModelSchemaWriterException(this.diagnostic);

  final GenerationDiagnostic diagnostic;

  @override
  String toString() =>
      'ModelSchemaWriterException(${diagnostic.code}): ${diagnostic.message}';
}

String _normalizeRuntimePrefix(String prefix) {
  if (prefix.isEmpty) return '';
  final normalized = prefix.endsWith('.')
      ? prefix.substring(0, prefix.length - 1)
      : prefix;
  if (!RegExp(r'^[A-Za-z_$][A-Za-z0-9_$]*$').hasMatch(normalized) ||
      _dartKeywords.contains(normalized)) {
    throw ArgumentError.value(
      prefix,
      'runtimePrefix',
      '必须是合法的 Dart import prefix，例如 df 或 df.。',
    );
  }
  return '$normalized.';
}

final class _ModelCompiler {
  _ModelCompiler({
    required this.schema,
    required this.symbolNameResolver,
    required this.runtimePrefix,
  });

  final ModelSchema schema;
  final SymbolNameResolver symbolNameResolver;
  final String runtimePrefix;

  late final List<_SemanticWitness> _semanticWitnesses;
  late final Map<String, ConstructorParameterSchema> _fieldParameters;
  late final List<RecordShape> _recordShapes;
  late final Map<RecordShape, int> _recordShapeIndexes;
  late final _DecodeNames _decodeNames;
  late final Set<String> _reservedExpressionNames;
  late final Set<String> _reservedValueNames;

  String get _modelName => schema.id.name;
  String get _modelDiagnosticId => '${schema.id.libraryUri}#$_modelName';
  String get _implementationName => schema.implementationName;
  String get _mixinName => r'_$' + _implementationName.substring(1);
  String get _publicTypeName => _modelName + _typeUse;
  String get _implementationTypeName => _implementationName + _typeUse;
  String get _erasedImplementationTypeName {
    if (schema.typeParameters.isEmpty) return _implementationName;
    return '$_implementationName<${List.filled(schema.typeParameters.length, 'dynamic').join(', ')}>';
  }

  String get _typeWitnessName => r'$' + _modelName + 'Type';
  String get _typeImplementationName => r'_$' + _modelName + 'DataforgeType';
  String get _decodeFunctionName => r'_$' + _modelName + 'FromJson';
  String get _copyWithSentinelType => r'_$' + _modelName + 'CopyWithSentinel';
  String get _copyWithSentinel => '$_copyWithSentinelType.value';

  String get _typeDeclaration {
    if (schema.typeParameters.isEmpty) return '';
    return '<${schema.typeParameters.map((parameter) => parameter.toDeclaration(resolveSymbol: symbolNameResolver)).join(', ')}>';
  }

  String get _typeUse {
    if (schema.typeParameters.isEmpty) return '';
    return '<${schema.typeParameters.map((parameter) => parameter.toUse()).join(', ')}>';
  }

  String get _erasedTypeUse {
    if (schema.typeParameters.isEmpty) return '';
    return '<${List.filled(schema.typeParameters.length, 'dynamic').join(', ')}>';
  }

  String _runtime(String name) => '$runtimePrefix$name';

  String write() {
    _validateAndIndexSchema();

    final sections = <String>[
      if (schema.generateCopyWith && schema.fields.isNotEmpty)
        _writeCopyWithSentinel(),
      _writeMixin(),
      _writeImplementation(),
      if (schema.includeFromJson) _writeDecodeFunction(),
      _writePublicTypeWitness(),
      _writeTypeImplementation(),
      for (final (index, shape) in _recordShapes.indexed)
        _writeRecordTypeImplementation(shape, index),
    ];
    return '${sections.join('\n\n')}\n';
  }

  String _writeCopyWithSentinel() =>
      'final class $_copyWithSentinelType {\n'
      '  const $_copyWithSentinelType._();\n\n'
      '  static const value = $_copyWithSentinelType._();\n'
      '}';

  void _validateAndIndexSchema() {
    _validateIdentifier(_modelName, target: 'model');
    _validateIdentifier(_implementationName, target: 'implementation');
    if (!_implementationName.startsWith('_')) {
      _fail(
        GenerationDiagnosticCode.invalidModel,
        '实现类必须是 library-private：$_implementationName。',
        target: _implementationName,
      );
    }
    if (!schema.deepFreeze) {
      _fail(
        GenerationDiagnosticCode.invalidModel,
        'v1 writer 只接受 deepFreeze=true 的 schema。',
        target: _modelName,
      );
    }
    if (schema.constructor.kind != ConstructorKind.redirectingFactory) {
      _fail(
        GenerationDiagnosticCode.constructorMismatch,
        '模型构造器必须是 redirecting factory。',
        target: schema.constructor.name,
      );
    }
    if (schema.constructor.isConst) {
      _fail(
        GenerationDiagnosticCode.constructorMismatch,
        '深冻结构造器不能是 const factory。',
        target: schema.constructor.name,
      );
    }
    if (schema.constructor.name == 'fromJson' ||
        schema.constructor.name == '_frozen') {
      _fail(
        GenerationDiagnosticCode.constructorMismatch,
        '构造器名 ${schema.constructor.name} 与生成成员冲突。',
        target: schema.constructor.name,
      );
    }

    _reservedExpressionNames = Set<String>.unmodifiable(
      _collectExpressionQualifierNames(),
    );
    _reservedValueNames = Set<String>.unmodifiable({
      ..._reservedExpressionNames,
      ..._collectDartTypeQualifierNames(),
      ...const <String>{
        'Object',
        'String',
        'bool',
        'int',
        'double',
        'num',
        'List',
        'Set',
        'Map',
        'DateTime',
        'Duration',
        'Never',
      },
      _modelName,
      _implementationName,
      _mixinName,
      _typeWitnessName,
      _typeImplementationName,
      _decodeFunctionName,
      _copyWithSentinelType,
    });
    const fixedGeneratedLocals = <String>{
      'other',
      'value',
      'left',
      'right',
      'json',
      'context',
    };
    final fixedCollision = fixedGeneratedLocals
        .where(_reservedExpressionNames.contains)
        .firstOrNull;
    if (fixedCollision != null) {
      _fail(
        GenerationDiagnosticCode.invalidModel,
        'import/type qualifier $fixedCollision 会被生成代码的固定局部变量遮蔽；'
        '请为对应 import 选择其他 prefix。',
        target: fixedCollision,
        details: {'qualifier': fixedCollision},
      );
    }

    final typeParameterNames = <String>{};
    for (final parameter in schema.typeParameters) {
      _validateIdentifier(parameter.name, target: parameter.name);
      _rejectExpressionQualifierShadow(parameter.name);
      if (!typeParameterNames.add(parameter.name)) {
        _fail(
          GenerationDiagnosticCode.invalidModel,
          '重复的类型参数 ${parameter.name}。',
          target: parameter.name,
        );
      }
    }

    for (final parameter in schema.typeParameters) {
      final bound = parameter.bound;
      if (bound != null) {
        _validateTypeShape(
          bound,
          declaredTypeParameters: typeParameterNames,
          target: parameter.name,
        );
      }
    }
    for (final field in schema.fields) {
      _validateTypeShape(
        field.shape,
        declaredTypeParameters: typeParameterNames,
        target: field.name,
      );
    }
    for (final parameter in schema.constructor.parameters) {
      _validateTypeShape(
        parameter.shape,
        declaredTypeParameters: typeParameterNames,
        target: parameter.name,
      );
    }

    final fieldsByName = <String, FieldSchema>{};
    final fromJsonNameOwners = <String, String>{};
    final toJsonNameOwners = <String, String>{};
    final generatedMemberNames = <String>{
      // Object members are part of the implementation namespace. Treating
      // either as value state would override Object's runtime semantics.
      'hashCode',
      'toString',
      'runtimeType',
      'noSuchMethod',
      // Generated constructors share the class member namespace.
      '_frozen',
      if (schema.constructor.name.isNotEmpty) schema.constructor.name,
      if (schema.includeFromJson) 'fromJson',
      if (schema.generateCopyWith) 'copyWith',
      if (schema.includeToJson) 'toJson',
    };
    for (final field in schema.fields) {
      _validateIdentifier(field.name, target: field.name);
      _rejectValueNameShadow(field.name);
      if (fieldsByName[field.name] != null) {
        _fail(
          GenerationDiagnosticCode.invalidModel,
          '重复的字段 ${field.name}。',
          target: field.name,
        );
      }
      fieldsByName[field.name] = field;
      if (generatedMemberNames.contains(field.name)) {
        _fail(
          GenerationDiagnosticCode.invalidModel,
          '字段 ${field.name} 与生成成员重名。',
          target: field.name,
        );
      }
      if (!field.isFinal) {
        _fail(
          GenerationDiagnosticCode.mutableField,
          '字段 ${field.name} 必须是 final。',
          target: field.name,
        );
      }
      if (schema.includeFromJson && field.includeFromJson) {
        for (final jsonName in <String>[
          field.jsonName,
          ...field.alternateJsonNames,
        ]) {
          final previous = fromJsonNameOwners[jsonName];
          if (previous != null) {
            _fail(
              GenerationDiagnosticCode.invalidJsonConfiguration,
              'JSON 名 $jsonName 同时映射到 $previous 与 ${field.name}。',
              target: field.name,
              details: {'jsonName': jsonName, 'otherField': previous},
            );
          }
          fromJsonNameOwners[jsonName] = field.name;
        }
      }
      if (schema.includeToJson && field.includeToJson) {
        final previous = toJsonNameOwners[field.jsonName];
        if (previous != null) {
          _fail(
            GenerationDiagnosticCode.invalidJsonConfiguration,
            'toJson 名 ${field.jsonName} 同时映射到 $previous 与 ${field.name}。',
            target: field.name,
            details: {'jsonName': field.jsonName, 'otherField': previous},
          );
        }
        toJsonNameOwners[field.jsonName] = field.name;
      }
    }

    final parameterNames = <String>{};
    final fieldParameters = <String, ConstructorParameterSchema>{};
    final witnesses = <_SemanticWitness>[];
    final witnessTargets = <TypeShape>{};
    final witnessStateNames = <String>{
      // These private members are generated in the two classes that retain
      // witness state.
      '_encode',
      '_frozen',
    };
    for (final parameter in schema.constructor.parameters) {
      _validateIdentifier(parameter.name, target: parameter.name);
      _rejectValueNameShadow(parameter.name);
      final isNamed =
          parameter.kind == ParameterKind.requiredNamed ||
          parameter.kind == ParameterKind.optionalNamed;
      if (isNamed && parameter.name.startsWith('_')) {
        _fail(
          GenerationDiagnosticCode.constructorMismatch,
          'Dart named parameter 不能以底线开头：${parameter.name}。',
          target: parameter.name,
        );
      }
      if (!parameterNames.add(parameter.name)) {
        _fail(
          GenerationDiagnosticCode.constructorMismatch,
          '重复的构造参数 ${parameter.name}。',
          target: parameter.name,
        );
      }
      if (parameter.fieldName == null) {
        final targetShape = _semanticWitnessTarget(parameter);
        if (targetShape == null) {
          _fail(
            GenerationDiagnosticCode.genericTypeWitnessRequired,
            '非字段构造参数 ${parameter.name} 必须是 DataforgeType<X> witness。',
            target: parameter.name,
          );
        }
        if (parameter.kind != ParameterKind.requiredNamed &&
            parameter.kind != ParameterKind.requiredPositional) {
          _fail(
            GenerationDiagnosticCode.genericTypeWitnessRequired,
            'DataforgeType witness ${parameter.name} 必须是 required 参数。',
            target: parameter.name,
          );
        }
        if (schema.includeFromJson && parameter.name.startsWith('_')) {
          _fail(
            GenerationDiagnosticCode.constructorMismatch,
            'fromJson 的 DataforgeType witness 会生成 required named '
            'parameter，名称不能以底线开头：${parameter.name}。',
            target: parameter.name,
          );
        }
        if (parameter.defaultValueCode != null) {
          _fail(
            GenerationDiagnosticCode.constructorMismatch,
            'required witness ${parameter.name} 不能声明默认值。',
            target: parameter.name,
          );
        }
        if (!witnessTargets.add(targetShape)) {
          _fail(
            GenerationDiagnosticCode.genericTypeWitnessRequired,
            'TypeShape ${targetShape.toDartType(resolveSymbol: symbolNameResolver)} 存在多个 witness。',
            target: parameter.name,
          );
        }
        final stateName = _privateWitnessName(parameter.name, <String>{
          ...fieldsByName.keys,
          ...witnessStateNames,
          ..._reservedValueNames,
        });
        witnessStateNames.add(stateName);
        witnesses.add(
          _SemanticWitness(
            parameter: parameter,
            targetShape: targetShape,
            stateName: stateName,
          ),
        );
        continue;
      }

      final field = fieldsByName[parameter.fieldName];
      if (field == null) {
        _fail(
          GenerationDiagnosticCode.constructorMismatch,
          '构造参数 ${parameter.name} 指向未知字段 ${parameter.fieldName}。',
          target: parameter.name,
        );
      }
      if (fieldParameters[field.name] != null) {
        _fail(
          GenerationDiagnosticCode.constructorMismatch,
          '字段 ${field.name} 被多个构造参数初始化。',
          target: field.name,
        );
      }
      if (parameter.shape != field.shape) {
        _fail(
          GenerationDiagnosticCode.constructorMismatch,
          '构造参数 ${parameter.name} 与字段 ${field.name} 的 TypeShape 不一致。',
          target: parameter.name,
        );
      }
      final parameterRequired =
          parameter.kind == ParameterKind.requiredNamed ||
          parameter.kind == ParameterKind.requiredPositional;
      if (parameterRequired &&
          (field.defaultValueCode != null ||
              parameter.defaultValueCode != null)) {
        _fail(
          GenerationDiagnosticCode.constructorMismatch,
          'required 参数 ${parameter.name} 不能声明默认值。',
          target: parameter.name,
        );
      }
      if (field.isRequired != parameterRequired) {
        _fail(
          GenerationDiagnosticCode.constructorMismatch,
          '字段 ${field.name} 的 isRequired 与构造参数不一致。',
          target: field.name,
        );
      }
      final fieldDefault = field.defaultValueCode;
      final parameterDefault = parameter.defaultValueCode;
      if (fieldDefault != null &&
          parameterDefault != null &&
          fieldDefault != parameterDefault) {
        _fail(
          GenerationDiagnosticCode.constructorMismatch,
          '字段 ${field.name} 与构造参数的默认值不一致。',
          target: field.name,
        );
      }
      if (!parameterRequired &&
          fieldDefault == null &&
          parameterDefault == null &&
          field.shape is! NullableShape) {
        _fail(
          GenerationDiagnosticCode.constructorMismatch,
          '非 nullable 可选字段 ${field.name} 必须有默认值。',
          target: field.name,
        );
      }
      fieldParameters[field.name] = parameter;
    }

    for (final field in schema.fields) {
      if (fieldParameters[field.name] == null) {
        _fail(
          GenerationDiagnosticCode.constructorMismatch,
          '字段 ${field.name} 缺少对应构造参数。',
          target: field.name,
        );
      }
    }

    final hasOptionalPositional = schema.constructor.parameters.any(
      (parameter) => parameter.kind == ParameterKind.optionalPositional,
    );
    final hasNamed = schema.constructor.parameters.any(
      (parameter) =>
          parameter.kind == ParameterKind.requiredNamed ||
          parameter.kind == ParameterKind.optionalNamed,
    );
    if (hasOptionalPositional && hasNamed) {
      _fail(
        GenerationDiagnosticCode.constructorMismatch,
        'Dart 构造器不能同时包含 optional positional 与 named 参数。',
        target: schema.constructor.name,
      );
    }

    _semanticWitnesses = List<_SemanticWitness>.unmodifiable(witnesses);
    _fieldParameters = Map<String, ConstructorParameterSchema>.unmodifiable(
      fieldParameters,
    );
    _decodeNames = _allocateDecodeNames();
    final semanticScope = _witnessScope(usePrivateState: true);

    final recordShapes = <RecordShape>[];
    final seenRecordShapes = <RecordShape>{};
    for (final field in schema.fields) {
      _collectRecordShapes(
        field.shape,
        recordShapes,
        seenRecordShapes,
        semanticScope,
      );
      if (schema.includeFromJson &&
          field.includeFromJson &&
          _containsRecord(field.shape, semanticScope)) {
        _fail(
          GenerationDiagnosticCode.invalidJsonConfiguration,
          'Record 字段 ${field.name} 暂不支持 fromJson；请关闭模型 fromJson 或忽略该字段。',
          target: field.name,
          details: {'direction': 'fromJson', 'shape': field.shape.toMap()},
        );
      }
      if (schema.includeToJson &&
          field.includeToJson &&
          _containsRecord(field.shape, semanticScope)) {
        _fail(
          GenerationDiagnosticCode.invalidJsonConfiguration,
          'Record 字段 ${field.name} 暂不支持 toJson；请关闭模型 toJson 或忽略该字段。',
          target: field.name,
          details: {'direction': 'toJson', 'shape': field.shape.toMap()},
        );
      }
      if (schema.includeFromJson && field.includeFromJson) {
        final unsupportedModel = _findModelWithoutJsonCapability(
          field.shape,
          fromJson: true,
          semanticScope: semanticScope,
        );
        if (unsupportedModel != null) {
          _fail(
            GenerationDiagnosticCode.invalidJsonConfiguration,
            '嵌套模型 ${unsupportedModel.modelId.name} 未启用 fromJson。',
            target: field.name,
            details: {
              'direction': 'fromJson',
              'model': unsupportedModel.modelId.toMap(),
            },
          );
        }
        final invalidKey = _findInvalidJsonMapKey(field.shape, semanticScope);
        if (invalidKey != null) {
          _fail(
            GenerationDiagnosticCode.invalidJsonConfiguration,
            'Map key ${invalidKey.toDartType(resolveSymbol: symbolNameResolver)} '
            '无法从 JSON String key 稳定解码。',
            target: field.name,
            details: {
              'direction': 'fromJson',
              'mapKeyShape': invalidKey.toMap(),
            },
          );
        }
      }
      if (schema.includeToJson && field.includeToJson) {
        final unsupportedModel = _findModelWithoutJsonCapability(
          field.shape,
          fromJson: false,
          semanticScope: semanticScope,
        );
        if (unsupportedModel != null) {
          _fail(
            GenerationDiagnosticCode.invalidJsonConfiguration,
            '嵌套模型 ${unsupportedModel.modelId.name} 未启用 toJson。',
            target: field.name,
            details: {
              'direction': 'toJson',
              'model': unsupportedModel.modelId.toMap(),
            },
          );
        }
        final invalidKey = _findInvalidJsonMapKey(field.shape, semanticScope);
        if (invalidKey != null) {
          _fail(
            GenerationDiagnosticCode.invalidJsonConfiguration,
            'Map key ${invalidKey.toDartType(resolveSymbol: symbolNameResolver)} '
            '无法稳定编码为 JSON String key。',
            target: field.name,
            details: {'direction': 'toJson', 'mapKeyShape': invalidKey.toMap()},
          );
        }
      }
    }
    _recordShapes = List<RecordShape>.unmodifiable(recordShapes);
    _recordShapeIndexes = Map<RecordShape, int>.unmodifiable({
      for (final (index, shape) in recordShapes.indexed) shape: index,
    });
    _validateGeneratedTopLevelNameUniqueness();

    final privateScope = _witnessScope(usePrivateState: true);
    for (final field in schema.fields) {
      _compileWitness(field.shape, privateScope, target: field.name);
      if (schema.includeFromJson &&
          !field.includeFromJson &&
          _effectiveDefault(field) == null &&
          field.shape is! NullableShape) {
        _fail(
          GenerationDiagnosticCode.invalidJsonConfiguration,
          '不参与 fromJson 的字段 ${field.name} 必须 nullable 或具有默认值。',
          target: field.name,
        );
      }
    }

    for (final typeParameter in schema.typeParameters) {
      final covered = _semanticWitnesses.any(
        (witness) =>
            _containsTypeParameter(witness.targetShape, typeParameter.name),
      );
      if (!covered) {
        _fail(
          GenerationDiagnosticCode.genericTypeWitnessRequired,
          '类型参数 ${typeParameter.name} 缺少 DataforgeType witness。',
          target: typeParameter.name,
        );
      }
    }
  }

  TypeShape? _semanticWitnessTarget(ConstructorParameterSchema parameter) {
    final shape = parameter.shape;
    if (shape is! CustomShape ||
        shape.symbol.name != 'DataforgeType' ||
        shape.typeArguments.length != 1) {
      return null;
    }
    return shape.typeArguments.single;
  }

  String _privateWitnessName(String publicName, Iterable<String> fieldNames) {
    var candidate = publicName.startsWith('_')
        ? '_df$publicName'
        : '_$publicName';
    while (fieldNames.contains(candidate) ||
        schema.constructor.parameters.any(
          (parameter) =>
              parameter.fieldName != null && parameter.name == candidate,
        )) {
      candidate = '_df$candidate';
    }
    return candidate;
  }

  _DecodeNames _allocateDecodeNames() {
    final used = <String>{
      ..._reservedValueNames,
      for (final witness in _semanticWitnesses) witness.parameter.name,
    };
    String allocate(String preferred) {
      var candidate = preferred;
      while (!used.add(candidate)) {
        candidate = '_df$candidate';
      }
      return candidate;
    }

    final json = allocate('json');
    final context = allocate('context');
    final modelContext = allocate('_modelContext');
    final normalizedJson = allocate('_normalizedJson');
    final acceptedJsonKeys = allocate('acceptedJsonKeys');
    final iterationKey = allocate('key');
    final fields = <String, _FieldDecodeNames>{};
    for (final field in schema.fields.where((field) => field.includeFromJson)) {
      fields[field.name] = _FieldDecodeNames(
        keys: allocate('_${field.name}JsonKeys'),
        key: allocate('_${field.name}JsonKey'),
        present: allocate('_${field.name}JsonPresent'),
      );
    }
    return _DecodeNames(
      json: json,
      context: context,
      modelContext: modelContext,
      normalizedJson: normalizedJson,
      acceptedJsonKeys: acceptedJsonKeys,
      iterationKey: iterationKey,
      fields: fields,
    );
  }

  void _validateIdentifier(String value, {required String target}) {
    if (!RegExp(r'^[A-Za-z_$][A-Za-z0-9_$]*$').hasMatch(value) ||
        _dartKeywords.contains(value)) {
      _fail(
        GenerationDiagnosticCode.invalidModel,
        '$value 不是合法的 Dart identifier。',
        target: target,
      );
    }
  }

  void _validateGeneratedTopLevelNameUniqueness() {
    final ownersByName = <String, List<String>>{};
    void add(String name, String role) {
      ownersByName.putIfAbsent(name, () => []).add(role);
    }

    add(_implementationName, 'implementation');
    add(_mixinName, 'mixin');
    add(_typeWitnessName, 'publicTypeWitness');
    add(_typeImplementationName, 'typeImplementation');
    if (schema.includeFromJson) add(_decodeFunctionName, 'decodeFunction');
    if (schema.generateCopyWith && schema.fields.isNotEmpty) {
      add(_copyWithSentinelType, 'copyWithSentinel');
    }
    for (var index = 0; index < _recordShapes.length; index++) {
      add(
        _recordTypeImplementationName(index),
        'recordTypeImplementation[$index]',
      );
    }

    final collisionNames =
        ownersByName.entries
            .where((entry) => entry.value.length > 1)
            .map((entry) => entry.key)
            .toList()
          ..sort();
    if (collisionNames.isEmpty) return;
    final name = collisionNames.first;
    _fail(
      GenerationDiagnosticCode.invalidModel,
      '生成 schema 的 top-level 符号 $name 发生自碰撞。',
      target: 'generatedSymbols.$name',
      details: {'symbol': name, 'roles': ownersByName[name]!},
    );
  }

  void _validateTypeShape(
    TypeShape shape, {
    required Set<String> declaredTypeParameters,
    required String target,
  }) {
    void visit(TypeShape child) => _validateTypeShape(
      child,
      declaredTypeParameters: declaredTypeParameters,
      target: target,
    );

    if (shape is TypeParameterShape) {
      if (!declaredTypeParameters.contains(shape.name)) {
        _fail(
          GenerationDiagnosticCode.genericTypeWitnessRequired,
          'TypeShape 引用了模型未声明的类型参数 ${shape.name}。',
          target: target,
          details: {'typeParameter': shape.name},
        );
      }
      return;
    }
    if (shape is NullableShape) {
      visit(shape.inner);
      return;
    }
    if (shape is ListShape || shape is SetShape) {
      visit(shape is ListShape ? shape.element : (shape as SetShape).element);
      return;
    }
    if (shape is MapShape) {
      visit(shape.key);
      visit(shape.value);
      return;
    }
    if (shape is ModelShape) {
      for (final argument in shape.typeArguments) {
        visit(argument);
      }
      for (final argument in shape.witnessArguments) {
        visit(argument);
      }
      return;
    }
    if (shape is RecordShape) {
      if (shape.positional.isEmpty && shape.named.isEmpty) {
        _fail(
          GenerationDiagnosticCode.invalidModel,
          'Record TypeShape 必须至少包含一个 positional 或 named 字段。',
          target: target,
        );
      }
      for (final entry in shape.named.entries) {
        _validateIdentifier(entry.key, target: target);
        visit(entry.value);
      }
      for (final child in shape.positional) {
        visit(child);
      }
      return;
    }
    if (shape is CustomShape) {
      for (final argument in shape.typeArguments) {
        visit(argument);
      }
    }
  }

  void _rejectExpressionQualifierShadow(String value) {
    if (!_reservedExpressionNames.contains(value)) return;
    _fail(
      GenerationDiagnosticCode.invalidModel,
      '$value 会遮蔽生成表达式使用的 import/type qualifier。',
      target: value,
      details: {'qualifier': value},
    );
  }

  void _rejectValueNameShadow(String value) {
    final recordHelperPrefix = r'_$' + '${_modelName}RecordDataforgeType';
    if (!_reservedValueNames.contains(value) &&
        !value.startsWith(recordHelperPrefix)) {
      return;
    }
    _fail(
      GenerationDiagnosticCode.invalidModel,
      '$value 会遮蔽生成代码使用的 Dart 类型或 import qualifier。',
      target: value,
      details: {'qualifier': value},
    );
  }

  Set<String> _collectExpressionQualifierNames() {
    final result = <String>{'Object'};
    if (runtimePrefix.isEmpty) {
      result.addAll(const <String>{
        'DataforgeType',
        'DataforgeTypeIdentity',
        'DataforgeTypeErasedEquality',
        'DataforgeTypes',
        'DataforgeJsonErrorCode',
        'JsonDecodeContext',
        'JsonEncodeContext',
        'dataforgeDecode',
        'dataforgeEncode',
        'dataforgeFreeze',
        'dataforgeNormalizeJsonObject',
        'dataforgeJsonActualType',
        'dataforgeTypeEquals',
        'dataforgeTypeHash',
        'dataforgeValueEquals',
      });
    } else {
      result.add(runtimePrefix.substring(0, runtimePrefix.length - 1));
    }

    void addResolved(SymbolId symbol) {
      final resolved = symbolNameResolver(symbol);
      final root = resolved.split('.').first;
      if (RegExp(r'^[A-Za-z_$][A-Za-z0-9_$]*$').hasMatch(root)) {
        result.add(root);
      }
    }

    void visit(TypeShape shape) {
      if (shape is NullableShape) {
        visit(shape.inner);
      } else if (shape is ListShape) {
        visit(shape.element);
      } else if (shape is SetShape) {
        visit(shape.element);
      } else if (shape is MapShape) {
        visit(shape.key);
        visit(shape.value);
      } else if (shape is EnumShape) {
        addResolved(shape.symbol);
      } else if (shape is ModelShape) {
        addResolved(shape.modelId.symbol);
        addResolved(
          SymbolId(
            libraryUri: shape.modelId.libraryUri,
            name: r'$' + shape.modelId.name + 'Type',
          ),
        );
        for (final argument in shape.typeArguments) {
          visit(argument);
        }
        for (final argument in shape.witnessArguments) {
          visit(argument);
        }
      } else if (shape is RecordShape) {
        for (final child in shape.positional) {
          visit(child);
        }
        for (final child in shape.named.values) {
          visit(child);
        }
      } else if (shape is CustomShape) {
        addResolved(shape.symbol);
        for (final argument in shape.typeArguments) {
          visit(argument);
        }
      }
    }

    for (final parameter in schema.typeParameters) {
      if (parameter.bound case final bound?) visit(bound);
    }
    for (final parameter in schema.constructor.parameters) {
      visit(parameter.shape);
    }
    for (final field in schema.fields) {
      visit(field.shape);
    }
    return result;
  }

  Set<String> _collectDartTypeQualifierNames() {
    final result = <String>{};

    void addResolved(SymbolId symbol) {
      final root = symbolNameResolver(symbol).split('.').first;
      if (RegExp(r'^[A-Za-z_$][A-Za-z0-9_$]*$').hasMatch(root)) {
        result.add(root);
      }
    }

    void visit(TypeShape shape) {
      if (shape is ScalarShape) {
        result.add(switch (shape.scalarKind) {
          ScalarKind.string => 'String',
          ScalarKind.boolean => 'bool',
          ScalarKind.integer => 'int',
          ScalarKind.doublePrecision => 'double',
          ScalarKind.number => 'num',
          ScalarKind.dynamicType => 'dynamic',
          ScalarKind.object => 'Object',
          ScalarKind.never => 'Never',
          ScalarKind.voidType => 'void',
        });
      } else if (shape is NullableShape) {
        visit(shape.inner);
      } else if (shape is ListShape) {
        result.add('List');
        visit(shape.element);
      } else if (shape is SetShape) {
        result.add('Set');
        visit(shape.element);
      } else if (shape is MapShape) {
        result.add('Map');
        visit(shape.key);
        visit(shape.value);
      } else if (shape is EnumShape) {
        addResolved(shape.symbol);
      } else if (shape is DateTimeShape) {
        result.add('DateTime');
      } else if (shape is DurationShape) {
        result.add('Duration');
      } else if (shape is ModelShape) {
        addResolved(shape.modelId.symbol);
        for (final argument in shape.typeArguments) {
          visit(argument);
        }
        for (final argument in shape.witnessArguments) {
          visit(argument);
        }
      } else if (shape is TypeParameterShape) {
        result.add(shape.name);
      } else if (shape is RecordShape) {
        for (final child in shape.positional) {
          visit(child);
        }
        for (final child in shape.named.values) {
          visit(child);
        }
      } else if (shape is CustomShape) {
        addResolved(shape.symbol);
        for (final argument in shape.typeArguments) {
          visit(argument);
        }
      }
    }

    for (final parameter in schema.typeParameters) {
      if (parameter.bound case final bound?) visit(bound);
    }
    for (final parameter in schema.constructor.parameters) {
      visit(parameter.shape);
    }
    for (final field in schema.fields) {
      visit(field.shape);
    }
    return result;
  }

  String _writeMixin() {
    final buffer = StringBuffer('mixin $_mixinName$_typeDeclaration {\n');
    for (final field in schema.fields) {
      buffer.writeln('  ${_dartType(field.shape)} get ${field.name};');
    }
    if (schema.generateCopyWith) {
      if (schema.fields.isNotEmpty) buffer.writeln();
      buffer.writeln('  $_publicTypeName copyWith({');
      for (final field in schema.fields) {
        buffer.writeln('    Object? ${field.name} = $_copyWithSentinel,');
      }
      buffer.writeln('  });');
    }
    if (schema.includeToJson) {
      if (schema.fields.isNotEmpty || schema.generateCopyWith) buffer.writeln();
      buffer.writeln('  Map<String, Object?> toJson();');
    }
    buffer.write('}');
    return buffer.toString();
  }

  String _writeImplementation() {
    final buffer = StringBuffer(
      'final class $_implementationName$_typeDeclaration '
      'extends $_publicTypeName {\n',
    );
    for (final witness in _semanticWitnesses) {
      buffer.writeln(
        '  final ${_dataforgeType(witness.targetShape)} ${witness.stateName};',
      );
    }
    for (final field in schema.fields) {
      buffer
        ..writeln('  @override')
        ..writeln('  final ${_dartType(field.shape)} ${field.name};');
    }

    if (_semanticWitnesses.isNotEmpty || schema.fields.isNotEmpty) {
      buffer.writeln();
    }
    _writePublicConstructor(buffer);
    buffer.writeln();
    _writeFrozenConstructor(buffer);

    if (schema.includeFromJson) {
      buffer
        ..writeln()
        ..write(_indent(_writeFromJsonFactory(), 2));
    }
    if (schema.generateCopyWith) {
      buffer
        ..writeln()
        ..write(_indent(_writeCopyWith(), 2));
    }
    if (schema.includeToJson) {
      buffer
        ..writeln()
        ..write(_indent(_writeToJsonMethod(), 2));
    }
    buffer
      ..writeln()
      ..write(_indent(_writeEqualityMembers(), 2))
      ..writeln()
      ..write(_indent(_writeToStringMember(), 2))
      ..write('\n}');
    return buffer.toString();
  }

  void _writePublicConstructor(StringBuffer buffer) {
    final suffix = schema.constructor.name.isEmpty
        ? ''
        : '.${schema.constructor.name}';
    buffer.writeln('  $_implementationName$suffix(');
    _writeConstructorParameters(
      buffer,
      schema.constructor.parameters,
      indent: '    ',
    );
    buffer.writeln('  )');

    final initializers = <String>[];
    for (final witness in _semanticWitnesses) {
      initializers.add('${witness.stateName} = ${witness.parameter.name}');
    }
    final publicScope = _witnessScope(usePrivateState: false);
    for (final field in schema.fields) {
      final parameter = _fieldParameters[field.name]!;
      final type = _compileWitness(
        field.shape,
        publicScope,
        target: field.name,
      );
      initializers.add('${field.name} = $type.freeze(${parameter.name})');
    }
    initializers.add('super._()');
    _writeInitializerList(buffer, initializers, indent: '      ');
    buffer.write(';');
  }

  void _writeFrozenConstructor(StringBuffer buffer) {
    buffer.writeln('  const $_implementationName._frozen({');
    for (final witness in _semanticWitnesses) {
      buffer.writeln(
        '    required ${_dataforgeType(witness.targetShape)} ${witness.parameter.name},',
      );
    }
    for (final field in schema.fields) {
      buffer.writeln('    required ${_dartType(field.shape)} ${field.name},');
    }
    buffer.writeln('  })');
    final initializers = <String>[
      for (final witness in _semanticWitnesses)
        '${witness.stateName} = ${witness.parameter.name}',
      for (final field in schema.fields) '${field.name} = ${field.name}',
      'super._()',
    ];
    _writeInitializerList(buffer, initializers, indent: '      ');
    buffer.write(';');
  }

  String _writeFromJsonFactory() {
    final json = _decodeNames.json;
    final buffer = StringBuffer(
      'factory $_implementationName.fromJson(Map<String, Object?> $json',
    );
    if (_semanticWitnesses.isNotEmpty) {
      buffer.writeln(', {');
      for (final witness in _semanticWitnesses) {
        buffer.writeln(
          '  required ${_dataforgeType(witness.targetShape)} ${witness.parameter.name},',
        );
      }
      buffer.write('})');
    } else {
      buffer.write(')');
    }
    buffer.write(
      ' =>\n    $_decodeFunctionName$_typeUse(\n'
      '      $json,\n'
      '      const ${_runtime('JsonDecodeContext')}(),',
    );
    if (_semanticWitnesses.isNotEmpty) {
      buffer.writeln();
      for (final witness in _semanticWitnesses) {
        buffer.writeln(
          '      ${witness.parameter.name}: ${witness.parameter.name},',
        );
      }
      buffer.write('    );');
    } else {
      buffer.write('\n    );');
    }
    return buffer.toString();
  }

  String _writeCopyWith() {
    final usedLocalNames = <String>{
      ..._reservedValueNames,
      ...schema.constructor.parameters.map((parameter) => parameter.name),
      ..._semanticWitnesses.map((witness) => witness.stateName),
    };
    final valueNames = <String, String>{};
    for (final (index, field) in schema.fields.indexed) {
      var candidate = '_dfCopyValue$index';
      while (!usedLocalNames.add(candidate)) {
        candidate = '_$candidate';
      }
      valueNames[field.name] = candidate;
    }

    final buffer = StringBuffer()
      ..writeln('@override')
      ..writeln('$_publicTypeName copyWith({');
    for (final field in schema.fields) {
      buffer.writeln('  Object? ${field.name} = $_copyWithSentinel,');
    }
    buffer.writeln('}) {');
    if (schema.fields.isEmpty) {
      buffer
        ..writeln('  return this;')
        ..write('}');
      return buffer.toString();
    }

    final privateScope = _witnessScope(usePrivateState: true);
    for (final field in schema.fields) {
      final type = _compileWitness(
        field.shape,
        privateScope,
        target: field.name,
      );
      final valueName = valueNames[field.name]!;
      buffer
        ..writeln('  final $valueName = identical(')
        ..writeln('        ${field.name},')
        ..writeln('        $_copyWithSentinel,')
        ..writeln('      ) ||')
        ..writeln('      identical(${field.name}, this.${field.name})')
        ..writeln('      ? this.${field.name}')
        ..writeln(
          '      : $type.freeze(${field.name} as ${_dartType(field.shape)});',
        );
    }
    final unchangedConditions = schema.fields
        .map((field) {
          final type = _compileWitness(
            field.shape,
            privateScope,
            target: field.name,
          );
          return '$type.equals(this.${field.name}, ${valueNames[field.name]})';
        })
        .join(' &&\n      ');
    buffer
      ..writeln('  if ($unchangedConditions) {')
      ..writeln('    return this;')
      ..writeln('  }')
      ..writeln('  return $_implementationTypeName._frozen(');
    for (final witness in _semanticWitnesses) {
      buffer.writeln('    ${witness.parameter.name}: ${witness.stateName},');
    }
    for (final field in schema.fields) {
      buffer.writeln('    ${field.name}: ${valueNames[field.name]},');
    }
    buffer
      ..writeln('  );')
      ..write('}');
    return buffer.toString();
  }

  String _writeToJsonMethod() {
    final constructorArguments = _semanticWitnesses
        .map((witness) => witness.stateName)
        .join(', ');
    return '@override\n'
        'Map<String, Object?> toJson() => '
        '$_typeImplementationName$_typeUse($constructorArguments)._encode(\n'
        '  this,\n'
        '  const ${_runtime('JsonEncodeContext')}(),\n'
        ');';
  }

  String _writeEqualityMembers() {
    final privateScope = _witnessScope(usePrivateState: true);
    final leftScope = _instanceWitnessScope('this');
    final rightScope = _instanceWitnessScope('other');
    final conditions = <String>[];
    for (final witness in _semanticWitnesses) {
      conditions.add(
        '${_runtime('dataforgeTypeEquals')}('
        '${witness.stateName}, other.${witness.stateName})',
      );
    }
    for (final field in schema.fields) {
      final leftType = _compileWitness(
        field.shape,
        leftScope,
        target: field.name,
        eraseTypeArguments: true,
      );
      final rightType = _compileWitness(
        field.shape,
        rightScope,
        target: field.name,
        eraseTypeArguments: true,
      );
      conditions.add(
        '${_runtime('dataforgeValueEquals')}('
        '$leftType, $rightType, this.${field.name}, other.${field.name})',
      );
    }

    // Dart generics are covariant. A directional `is _Model<T>` check would
    // make Model<int> / Model<num> equality asymmetric. The complete witness
    // tree below owns generic semantics, so this checks declaration identity
    // with erased type arguments.
    final otherType = _erasedImplementationTypeName;
    final buffer = StringBuffer()
      ..writeln('@override')
      ..writeln('bool operator ==(Object other) =>')
      ..writeln('    identical(this, other) ||')
      ..write('    other is $otherType');
    for (final condition in conditions) {
      buffer
        ..writeln(' &&')
        ..write('        $condition');
    }
    buffer
      ..writeln(';')
      ..writeln()
      ..writeln('@override')
      ..writeln('int get hashCode => Object.hashAll(<Object?>[');
    for (final witness in _semanticWitnesses) {
      buffer.writeln(
        '  ${_runtime('dataforgeTypeHash')}(${witness.stateName}),',
      );
    }
    for (final field in schema.fields) {
      final type = _compileWitness(
        field.shape,
        privateScope,
        target: field.name,
      );
      buffer.writeln('  $type.hash(this.${field.name}),');
    }
    buffer.write(']);');
    return buffer.toString();
  }

  String _writeToStringMember() {
    final parts = <String>[_quote('$_modelName(')];
    for (final (index, field) in schema.fields.indexed) {
      if (index > 0) parts.add(_quote(', '));
      parts
        ..add(_quote('${field.name}: '))
        ..add('this.${field.name}.toString()');
    }
    parts.add(_quote(')'));
    return '@override\nString toString() => ${parts.join(' + ')};';
  }

  String _writeDecodeFunction() {
    final json = _decodeNames.json;
    final contextParameter = _decodeNames.context;
    final context = _decodeNames.modelContext;
    final normalizedJson = _decodeNames.normalizedJson;
    final acceptedJsonKeys = _decodeNames.acceptedJsonKeys;
    final iterationKey = _decodeNames.iterationKey;
    final buffer = StringBuffer(
      '$_implementationTypeName $_decodeFunctionName$_typeDeclaration(\n'
      '  Map<String, Object?> $json,\n'
      '  ${_runtime('JsonDecodeContext')} $contextParameter,',
    );
    if (_semanticWitnesses.isNotEmpty) {
      buffer.writeln(' {');
      for (final witness in _semanticWitnesses) {
        buffer.writeln(
          '  required ${_dataforgeType(witness.targetShape)} ${witness.parameter.name},',
        );
      }
      buffer.write('}');
    }
    buffer.writeln('\n) {');
    buffer.writeln(
      '  final $context = '
      '$contextParameter.atModel(${_quote(_modelDiagnosticId)});',
    );
    buffer.writeln(
      '  final $normalizedJson = ${_runtime('dataforgeNormalizeJsonObject')}('
      '$json, $context);',
    );

    final acceptedJsonNames =
        schema.fields
            .where((field) => field.includeFromJson)
            .expand(
              (field) => <String>[field.jsonName, ...field.alternateJsonNames],
            )
            .toSet()
            .toList()
          ..sort();
    buffer.writeln('  const $acceptedJsonKeys = <String>{');
    for (final name in acceptedJsonNames) {
      buffer.writeln('    ${_quote(name)},');
    }
    buffer
      ..writeln('  };')
      ..writeln('  for (final $iterationKey in $normalizedJson.keys) {')
      ..writeln('    if (!$acceptedJsonKeys.contains($iterationKey)) {')
      ..writeln(
        '      $context.field($iterationKey).fail('
        '${_quote('未知 JSON 字段。')}, '
        'code: ${_runtime('DataforgeJsonErrorCode')}.unknownField, '
        'expectedType: ${_quote('known JSON field')}, '
        'actualType: ${_quote('String')});',
      )
      ..writeln('    }')
      ..writeln('  }');

    final publicScope = _witnessScope(usePrivateState: false);
    for (final field in schema.fields.where((field) => field.includeFromJson)) {
      final keyVariable = _jsonKeyVariable(field);
      final presentVariable = _jsonPresentVariable(field);
      final names = <String>[field.jsonName, ...field.alternateJsonNames];
      final keysVariable = _decodeNames.fields[field.name]!.keys;
      buffer.writeln('  final $keysVariable = <String>[');
      for (final name in names) {
        buffer.writeln(
          '    if ($normalizedJson.containsKey(${_quote(name)})) ${_quote(name)},',
        );
      }
      buffer
        ..writeln('  ];')
        ..writeln('  if ($keysVariable.length > 1) {')
        ..writeln(
          '    $context.field($keysVariable[1], '
          'schemaField: ${_quote(field.name)}).fail('
          '${_quote('同一字段不能同时使用主 JSON 名与 alternate name。')}, '
          'code: ${_runtime('DataforgeJsonErrorCode')}.conflictingFieldAliases, '
          'expectedType: ${_quote('exactly one JSON field alias')}, '
          'actualType: ${_quote('multiple String keys')});',
        )
        ..writeln('  }')
        ..writeln('  final $presentVariable = $keysVariable.isNotEmpty;')
        ..writeln(
          '  final $keyVariable = $presentVariable ? $keysVariable.single : ${_quote(field.jsonName)};',
        );
      if (field.isRequired && _effectiveDefault(field) == null) {
        buffer
          ..writeln('  if (!$presentVariable) {')
          ..writeln(
            '    $context.field(${_quote(field.jsonName)}, '
            'schemaField: ${_quote(field.name)}).fail('
            '${_quote('缺少必填字段 ${field.jsonName}。')}, '
            'code: ${_runtime('DataforgeJsonErrorCode')}.missingRequiredField, '
            'expectedType: ${_quote(_dartType(field.shape))}, '
            'actualType: ${_quote('missing')});',
          )
          ..writeln('  }');
      }
    }

    buffer.writeln('  return $_implementationTypeName._frozen(');
    for (final witness in _semanticWitnesses) {
      buffer.writeln(
        '    ${witness.parameter.name}: ${witness.parameter.name},',
      );
    }
    for (final field in schema.fields) {
      final type = _compileWitness(
        field.shape,
        publicScope,
        target: field.name,
      );
      final defaultValue = _effectiveDefault(field);
      final fieldContext =
          '$context.field(${_quote(field.jsonName)}, '
          'schemaField: ${_quote(field.name)})';
      buffer.write('    ${field.name}: ');
      if (!field.includeFromJson) {
        if (defaultValue != null) {
          buffer.writeln(
            '${_runtime('dataforgeFreeze')}('
            '$type, $defaultValue, $fieldContext),',
          );
        } else {
          buffer.writeln(
            '${_runtime('dataforgeFreeze')}($type, null, $fieldContext),',
          );
        }
        continue;
      }
      final decode =
          '${_runtime('dataforgeDecode')}('
          '$type, $normalizedJson[${_jsonKeyVariable(field)}], '
          '$context.field(${_jsonKeyVariable(field)}, '
          'schemaField: ${_quote(field.name)}))';
      if (defaultValue != null) {
        buffer.writeln(
          '${_jsonPresentVariable(field)} ? $decode : '
          '${_runtime('dataforgeFreeze')}('
          '$type, $defaultValue, $fieldContext),',
        );
      } else {
        buffer.writeln('$decode,');
      }
    }
    buffer
      ..writeln('  );')
      ..write('}');
    return buffer.toString();
  }

  String _writePublicTypeWitness() {
    final dataforgeType = _dataforgeType(
      ModelShape(
        schema.id,
        typeArguments: schema.typeParameters
            .map<TypeShape>((parameter) => TypeParameterShape(parameter.name))
            .toList(),
      ),
    );
    if (_semanticWitnesses.isEmpty) {
      return 'const $dataforgeType $_typeWitnessName = '
          '$_typeImplementationName();';
    }

    final buffer = StringBuffer(
      '$dataforgeType $_typeWitnessName$_typeDeclaration(\n',
    );
    for (final witness in _semanticWitnesses) {
      buffer.writeln(
        '  ${_dataforgeType(witness.targetShape)} ${witness.parameter.name},',
      );
    }
    buffer
      ..writeln(') =>')
      ..writeln('    $_typeImplementationName$_typeUse(');
    for (final witness in _semanticWitnesses) {
      buffer.writeln('      ${witness.parameter.name},');
    }
    buffer
      ..writeln('    );')
      ..write('');
    return buffer.toString();
  }

  String _writeTypeImplementation() {
    final buffer = StringBuffer(
      'final class $_typeImplementationName$_typeDeclaration '
      'implements ${_runtime('DataforgeType')}<$_publicTypeName>, '
      '${_runtime('DataforgeTypeIdentity')}, '
      '${_runtime('DataforgeTypeErasedEquality')} {\n',
    );
    if (_semanticWitnesses.isEmpty) {
      buffer.writeln('  const $_typeImplementationName();');
    } else {
      buffer.writeln('  const $_typeImplementationName(');
      for (final witness in _semanticWitnesses) {
        buffer.writeln('    this.${witness.stateName},');
      }
      buffer.writeln('  );');
      buffer.writeln();
      for (final witness in _semanticWitnesses) {
        buffer.writeln(
          '  final ${_dataforgeType(witness.targetShape)} ${witness.stateName};',
        );
      }
    }

    buffer
      ..writeln()
      ..writeln('  @override')
      ..writeln(
        '  Object get dataforgeTypeId => '
        '${_quote('${schema.id.libraryUri}#${schema.id.name}')};',
      )
      ..writeln()
      ..writeln('  @override')
      ..write(
        '  List<${_runtime('DataforgeType')}<dynamic>> '
        'get dataforgeTypeArguments => ',
      );
    if (_semanticWitnesses.isEmpty) {
      buffer.writeln('const <${_runtime('DataforgeType')}<dynamic>>[];');
    } else {
      buffer.writeln(
        'List<${_runtime('DataforgeType')}<dynamic>>.unmodifiable('
        '<${_runtime('DataforgeType')}<dynamic>>[',
      );
      for (final witness in _semanticWitnesses) {
        buffer.writeln('    ${witness.stateName},');
      }
      buffer.writeln('  ]);');
    }

    final privateScope = _witnessScope(usePrivateState: true);
    buffer
      ..writeln()
      ..writeln('  @override')
      ..writeln('  $_publicTypeName freeze($_publicTypeName value) {');
    if (_semanticWitnesses.isEmpty) {
      buffer.writeln(
        '    if (value is $_implementationTypeName) return value;',
      );
    } else {
      buffer
        ..writeln('    if (value is $_implementationTypeName &&')
        ..write('        ');
      for (var index = 0; index < _semanticWitnesses.length; index++) {
        final witness = _semanticWitnesses[index];
        if (index > 0) buffer.write(' &&\n        ');
        buffer.write(
          '${_runtime('dataforgeTypeEquals')}('
          '${witness.stateName}, value.${witness.stateName})',
        );
      }
      buffer.writeln(') {\n      return value;\n    }');
    }
    buffer.writeln('    return $_implementationTypeName._frozen(');
    for (final witness in _semanticWitnesses) {
      buffer.writeln('      ${witness.parameter.name}: ${witness.stateName},');
    }
    for (final field in schema.fields) {
      final type = _compileWitness(
        field.shape,
        privateScope,
        target: field.name,
      );
      buffer.writeln('      ${field.name}: $type.freeze(value.${field.name}),');
    }
    buffer
      ..writeln('    );')
      ..writeln('  }')
      ..writeln()
      ..writeln('  @override')
      ..writeln(
        '  bool equals($_publicTypeName left, $_publicTypeName right) => '
        'dataforgeEqualsErased(this, left, right);',
      )
      ..writeln()
      ..writeln('  @override')
      ..writeln(
        '  bool dataforgeEqualsErased('
        '${_runtime('DataforgeType')}<dynamic> other, '
        'Object? left, Object? right) {',
      );
    buffer.writeln(
      '    if (other is! $_typeImplementationName$_erasedTypeUse || '
      '!${_runtime('dataforgeTypeEquals')}(this, other) || '
      'left is! $_erasedImplementationTypeName || '
      'right is! $_erasedImplementationTypeName) {',
    );
    buffer.writeln('      return false;\n    }');
    if (_semanticWitnesses.isNotEmpty) {
      for (final witness in _semanticWitnesses) {
        buffer.writeln(
          '    if (!${_runtime('dataforgeTypeEquals')}('
          '${witness.stateName}, left.${witness.stateName}) || '
          '!${_runtime('dataforgeTypeEquals')}('
          'other.${witness.stateName}, right.${witness.stateName})) '
          'return false;',
        );
      }
    }
    buffer.writeln('    if (identical(left, right)) return true;');
    if (schema.fields.isEmpty) {
      buffer.writeln('    return true;');
    } else {
      final leftScope = _instanceWitnessScope('left');
      final rightScope = _instanceWitnessScope('right');
      buffer.write('    return ');
      for (var index = 0; index < schema.fields.length; index++) {
        final field = schema.fields[index];
        final leftType = _compileWitness(
          field.shape,
          leftScope,
          target: field.name,
          eraseTypeArguments: true,
        );
        final rightType = _compileWitness(
          field.shape,
          rightScope,
          target: field.name,
          eraseTypeArguments: true,
        );
        if (index > 0) buffer.write(' &&\n        ');
        buffer.write(
          '${_runtime('dataforgeValueEquals')}('
          '$leftType, $rightType, left.${field.name}, right.${field.name})',
        );
      }
      buffer.writeln(';');
    }
    buffer
      ..writeln('  }')
      ..writeln()
      ..writeln('  @override')
      ..writeln(
        '  int hash($_publicTypeName value) => Object.hashAll(<Object?>[',
      );
    for (final witness in _semanticWitnesses) {
      buffer.writeln(
        '    ${_runtime('dataforgeTypeHash')}(${witness.stateName}),',
      );
    }
    for (final field in schema.fields) {
      final type = _compileWitness(
        field.shape,
        privateScope,
        target: field.name,
      );
      buffer.writeln('    $type.hash(value.${field.name}),');
    }
    buffer.writeln('  ]);');

    buffer
      ..writeln()
      ..writeln('  @override')
      ..writeln(
        '  $_publicTypeName fromJson(Object? json, ${_runtime('JsonDecodeContext')} context) {',
      );
    if (!schema.includeFromJson) {
      buffer.writeln(
        '    return context.atModel(${_quote(_modelDiagnosticId)}).fail('
        '${_quote('$_modelName 未启用 fromJson。')}, '
        'code: ${_runtime('DataforgeJsonErrorCode')}.unsupportedDirection, '
        'expectedType: ${_quote('fromJson enabled model')}, '
        'actualType: ${_quote('fromJson disabled model')});',
      );
    } else {
      buffer
        ..writeln('    if (json is! Map<String, Object?>) {')
        ..writeln(
          '      return context.atModel(${_quote(_modelDiagnosticId)}).fail('
          '${_quote('$_modelName 必须从 JSON object 解码。')}, '
          'code: ${_runtime('DataforgeJsonErrorCode')}.typeMismatch, '
          'expectedType: ${_quote('Map<String, Object?>')}, '
          'actualType: ${_runtime('dataforgeJsonActualType')}(json));',
        )
        ..writeln('    }')
        ..writeln('    return $_decodeFunctionName$_typeUse(')
        ..writeln('      json,')
        ..write('      context,');
      if (_semanticWitnesses.isNotEmpty) {
        buffer.writeln();
        for (final witness in _semanticWitnesses) {
          buffer.writeln(
            '      ${witness.parameter.name}: ${witness.stateName},',
          );
        }
        buffer.writeln('    );');
      } else {
        buffer.writeln('\n    );');
      }
    }
    buffer
      ..writeln('  }')
      ..writeln()
      ..writeln('  @override')
      ..writeln(
        '  Object? toJson($_publicTypeName value, ${_runtime('JsonEncodeContext')} context) {',
      );
    if (!schema.includeToJson) {
      buffer.writeln(
        '    return context.atModel(${_quote(_modelDiagnosticId)}).fail('
        '${_quote('$_modelName 未启用 toJson。')}, '
        'code: ${_runtime('DataforgeJsonErrorCode')}.unsupportedDirection, '
        'expectedType: ${_quote('toJson enabled model')}, '
        'actualType: ${_quote('toJson disabled model')});',
      );
    } else {
      buffer.writeln('    return _encode(value, context);');
    }
    buffer
      ..writeln('  }')
      ..writeln();

    if (schema.includeToJson) {
      buffer.write(_indent(_writeEncodeHelper(), 2));
      buffer.writeln();
    }
    buffer.write('}');
    return buffer.toString();
  }

  String _writeEncodeHelper() {
    final privateScope = _witnessScope(usePrivateState: true);
    final modelContext = _decodeNames.modelContext;
    final buffer = StringBuffer(
      'Map<String, Object?> _encode(\n'
      '  $_publicTypeName value,\n'
      '  ${_runtime('JsonEncodeContext')} context,\n'
      ') {\n'
      '  final $modelContext = context.atModel(${_quote(_modelDiagnosticId)});\n'
      '  return $modelContext.snapshot(<String, Object?>{\n',
    );
    for (final field in schema.fields.where((field) => field.includeToJson)) {
      final type = _compileWitness(
        field.shape,
        privateScope,
        target: field.name,
      );
      final entry =
          '${_quote(field.jsonName)}: ${_runtime('dataforgeEncode')}('
          '$type, value.${field.name}, '
          '$modelContext.field(${_quote(field.jsonName)}, '
          'schemaField: ${_quote(field.name)})),';
      if (field.includeIfNull == false) {
        buffer.writeln('    if (value.${field.name} != null) $entry');
      } else {
        buffer.writeln('    $entry');
      }
    }
    buffer
      ..writeln('  }) as Map<String, Object?>;')
      ..write('}');
    return buffer.toString();
  }

  String _writeRecordTypeImplementation(RecordShape shape, int index) {
    final className = _recordTypeImplementationName(index);
    final recordType = _dartType(shape);
    final children = _recordChildren(shape);
    final buffer = StringBuffer(
      'final class $className$_typeDeclaration '
      'implements ${_runtime('DataforgeType')}<$recordType>, '
      '${_runtime('DataforgeTypeIdentity')}, '
      '${_runtime('DataforgeTypeErasedEquality')} {\n',
    )..writeln('  const $className(');
    for (final child in children) {
      buffer.writeln('    this.${child.stateName},');
    }
    buffer
      ..writeln('  );')
      ..writeln();
    for (final child in children) {
      buffer.writeln(
        '  final ${_dataforgeType(child.shape)} ${child.stateName};',
      );
    }

    buffer
      ..writeln()
      ..writeln('  @override')
      ..writeln(
        '  Object get dataforgeTypeId => ${_quote(_recordTypeId(shape))};',
      )
      ..writeln()
      ..writeln('  @override')
      ..writeln(
        '  List<${_runtime('DataforgeType')}<dynamic>> '
        'get dataforgeTypeArguments => '
        'List<${_runtime('DataforgeType')}<dynamic>>.unmodifiable('
        '<${_runtime('DataforgeType')}<dynamic>>[',
      );
    for (final child in children) {
      buffer.writeln('    ${child.stateName},');
    }
    buffer
      ..writeln('  ]);')
      ..writeln()
      ..writeln('  @override')
      ..writeln('  $recordType freeze($recordType value) => ')
      ..writeln(
        '      ${_recordExpression(shape, children, operation: 'freeze')};',
      )
      ..writeln()
      ..writeln('  @override')
      ..writeln(
        '  bool equals($recordType left, $recordType right) => '
        'dataforgeEqualsErased(this, left, right);',
      )
      ..writeln()
      ..writeln('  @override')
      ..writeln(
        '  bool dataforgeEqualsErased('
        '${_runtime('DataforgeType')}<dynamic> other, '
        'Object? left, Object? right) {',
      )
      ..writeln(
        '    if (other is! $className$_erasedTypeUse || '
        '!${_runtime('dataforgeTypeEquals')}(this, other) || '
        'left is! ${_erasedDartType(shape)} || '
        'right is! ${_erasedDartType(shape)}) return false;',
      )
      ..writeln('    if (identical(left, right)) return true;')
      ..write('    return ');
    for (var childIndex = 0; childIndex < children.length; childIndex++) {
      final child = children[childIndex];
      final suffix = childIndex == children.length - 1 ? ';' : ' &&';
      if (childIndex > 0) buffer.write('\n        ');
      buffer.write(
        '${_runtime('dataforgeValueEquals')}('
        '${child.stateName}, other.${child.stateName}, '
        'left.${child.accessor}, right.${child.accessor})$suffix',
      );
    }
    buffer
      ..writeln()
      ..writeln('  }')
      ..writeln()
      ..writeln('  @override')
      ..writeln('  int hash($recordType value) => Object.hashAll(<Object?>[');
    for (final child in children) {
      buffer.writeln('    ${child.stateName}.hash(value.${child.accessor}),');
    }
    buffer
      ..writeln('  ]);')
      ..writeln()
      ..writeln('  @override')
      ..writeln(
        '  $recordType fromJson(Object? json, '
        '${_runtime('JsonDecodeContext')} context) =>',
      )
      ..writeln(
        '      context.fail(${_quote('Record 暂不支持 JSON 解码。')}, '
        'code: ${_runtime('DataforgeJsonErrorCode')}.unsupportedDirection, '
        'expectedType: ${_quote('exact DataforgeType<Record> JSON codec')}, '
        'actualType: ${_quote('Record without JSON codec')});',
      )
      ..writeln()
      ..writeln('  @override')
      ..writeln(
        '  Object? toJson($recordType value, '
        '${_runtime('JsonEncodeContext')} context) =>',
      )
      ..writeln(
        '      context.fail(${_quote('Record 暂不支持 JSON 编码。')}, '
        'code: ${_runtime('DataforgeJsonErrorCode')}.unsupportedDirection, '
        'expectedType: ${_quote('exact DataforgeType<Record> JSON codec')}, '
        'actualType: ${_quote('Record without JSON codec')});',
      )
      ..write('}');
    return buffer.toString();
  }

  String _recordTypeImplementationName(int index) =>
      r'_$' + '${_modelName}RecordDataforgeType$index';

  String _recordTypeId(RecordShape shape) {
    final namedNames = shape.named.keys.toList()..sort();
    return 'dataforge:record('
        'positional:${shape.positional.length};'
        'named:${namedNames.join(',')})';
  }

  List<_RecordChild> _recordChildren(RecordShape shape) {
    String stateName(String preferred) {
      var candidate = preferred;
      while (_reservedValueNames.contains(candidate)) {
        candidate = '_df$candidate';
      }
      return candidate;
    }

    final children = <_RecordChild>[
      for (final (index, childShape) in shape.positional.indexed)
        _RecordChild(
          shape: childShape,
          stateName: stateName('_positional$index'),
          accessor: r'$' + '${index + 1}',
        ),
    ];
    final namedEntries = shape.named.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    for (final (index, entry) in namedEntries.indexed) {
      children.add(
        _RecordChild(
          shape: entry.value,
          stateName: stateName('_named$index'),
          accessor: entry.key,
          name: entry.key,
        ),
      );
    }
    return children;
  }

  String _recordExpression(
    RecordShape shape,
    List<_RecordChild> children, {
    required String operation,
  }) {
    final values = <String>[];
    for (final child in children.where((child) => child.name == null)) {
      values.add('${child.stateName}.$operation(value.${child.accessor})');
    }
    for (final child in children.where((child) => child.name != null)) {
      values.add(
        '${child.name}: '
        '${child.stateName}.$operation(value.${child.accessor})',
      );
    }
    if (shape.positional.length == 1 && shape.named.isEmpty) {
      return '(${values.single},)';
    }
    return '(${values.join(', ')})';
  }

  void _collectRecordShapes(
    TypeShape shape,
    List<RecordShape> output,
    Set<RecordShape> seen,
    Map<TypeShape, String> semanticScope,
  ) {
    if (semanticScope.containsKey(shape)) return;
    if (shape is NullableShape) {
      _collectRecordShapes(shape.inner, output, seen, semanticScope);
    } else if (shape is ListShape) {
      _collectRecordShapes(shape.element, output, seen, semanticScope);
    } else if (shape is SetShape) {
      _collectRecordShapes(shape.element, output, seen, semanticScope);
    } else if (shape is MapShape) {
      _collectRecordShapes(shape.key, output, seen, semanticScope);
      _collectRecordShapes(shape.value, output, seen, semanticScope);
    } else if (shape is ModelShape) {
      for (final argument in shape.witnessArguments) {
        _collectRecordShapes(argument, output, seen, semanticScope);
      }
    } else if (shape is RecordShape) {
      if (seen.add(shape)) output.add(shape);
      for (final child in shape.positional) {
        _collectRecordShapes(child, output, seen, semanticScope);
      }
      final namedEntries = shape.named.entries.toList()
        ..sort((left, right) => left.key.compareTo(right.key));
      for (final entry in namedEntries) {
        _collectRecordShapes(entry.value, output, seen, semanticScope);
      }
    }
  }

  bool _containsRecord(TypeShape shape, Map<TypeShape, String> semanticScope) {
    if (semanticScope.containsKey(shape)) return false;
    if (shape is RecordShape) return true;
    if (shape is NullableShape) {
      return _containsRecord(shape.inner, semanticScope);
    }
    if (shape is ListShape) {
      return _containsRecord(shape.element, semanticScope);
    }
    if (shape is SetShape) {
      return _containsRecord(shape.element, semanticScope);
    }
    if (shape is MapShape) {
      return _containsRecord(shape.key, semanticScope) ||
          _containsRecord(shape.value, semanticScope);
    }
    if (shape is ModelShape) {
      // typeArguments describe only instantiated Dart type identity. The
      // freeze/JSON/equality/hash tree is carried by witnessArguments. Walking
      // typeArguments would cross a whole-exact witness boundary and wrongly
      // treat an exact-witness Record as using built-in JSON semantics.
      return shape.witnessArguments.any(
        (child) => _containsRecord(child, semanticScope),
      );
    }
    if (shape is CustomShape) {
      return shape.typeArguments.any(
        (child) => _containsRecord(child, semanticScope),
      );
    }
    return false;
  }

  TypeShape? _findInvalidJsonMapKey(
    TypeShape shape,
    Map<TypeShape, String> semanticScope,
  ) {
    if (semanticScope.containsKey(shape)) return null;
    if (shape is NullableShape) {
      return _findInvalidJsonMapKey(shape.inner, semanticScope);
    }
    if (shape is ListShape) {
      return _findInvalidJsonMapKey(shape.element, semanticScope);
    }
    if (shape is SetShape) {
      return _findInvalidJsonMapKey(shape.element, semanticScope);
    }
    if (shape is MapShape) {
      if (!_canEncodeJsonMapKey(shape.key, semanticScope)) return shape.key;
      return _findInvalidJsonMapKey(shape.value, semanticScope);
    }
    if (shape is ModelShape) {
      for (final witnessArgument in shape.witnessArguments) {
        final invalid = _findInvalidJsonMapKey(witnessArgument, semanticScope);
        if (invalid != null) return invalid;
      }
    }
    return null;
  }

  ModelShape? _findModelWithoutJsonCapability(
    TypeShape shape, {
    required bool fromJson,
    required Map<TypeShape, String> semanticScope,
  }) {
    if (semanticScope.containsKey(shape)) return null;
    if (shape is NullableShape) {
      return _findModelWithoutJsonCapability(
        shape.inner,
        fromJson: fromJson,
        semanticScope: semanticScope,
      );
    }
    if (shape is ListShape) {
      return _findModelWithoutJsonCapability(
        shape.element,
        fromJson: fromJson,
        semanticScope: semanticScope,
      );
    }
    if (shape is SetShape) {
      return _findModelWithoutJsonCapability(
        shape.element,
        fromJson: fromJson,
        semanticScope: semanticScope,
      );
    }
    if (shape is MapShape) {
      return _findModelWithoutJsonCapability(
            shape.key,
            fromJson: fromJson,
            semanticScope: semanticScope,
          ) ??
          _findModelWithoutJsonCapability(
            shape.value,
            fromJson: fromJson,
            semanticScope: semanticScope,
          );
    }
    if (shape is RecordShape) {
      for (final child in shape.positional) {
        final unsupported = _findModelWithoutJsonCapability(
          child,
          fromJson: fromJson,
          semanticScope: semanticScope,
        );
        if (unsupported != null) return unsupported;
      }
      for (final child in shape.named.values) {
        final unsupported = _findModelWithoutJsonCapability(
          child,
          fromJson: fromJson,
          semanticScope: semanticScope,
        );
        if (unsupported != null) return unsupported;
      }
      return null;
    }
    if (shape is ModelShape) {
      if (fromJson ? !shape.includeFromJson : !shape.includeToJson) {
        return shape;
      }
      for (final witnessArgument in shape.witnessArguments) {
        final unsupported = _findModelWithoutJsonCapability(
          witnessArgument,
          fromJson: fromJson,
          semanticScope: semanticScope,
        );
        if (unsupported != null) return unsupported;
      }
    }
    return null;
  }

  bool _canEncodeJsonMapKey(
    TypeShape shape,
    Map<TypeShape, String> semanticScope,
  ) {
    if (semanticScope.containsKey(shape)) return true;
    return switch (shape) {
      ScalarShape(:final scalarKind) =>
        scalarKind == ScalarKind.string ||
            scalarKind == ScalarKind.boolean ||
            scalarKind == ScalarKind.integer ||
            scalarKind == ScalarKind.doublePrecision ||
            scalarKind == ScalarKind.number,
      EnumShape() || DateTimeShape() || DurationShape() => true,
      NullableShape() ||
      ListShape() ||
      SetShape() ||
      MapShape() ||
      RecordShape() ||
      ModelShape() ||
      TypeParameterShape() ||
      CustomShape() => false,
    };
  }

  void _writeConstructorParameters(
    StringBuffer buffer,
    List<ConstructorParameterSchema> parameters, {
    required String indent,
  }) {
    final requiredPositional = parameters
        .where(
          (parameter) => parameter.kind == ParameterKind.requiredPositional,
        )
        .toList();
    final optionalPositional = parameters
        .where(
          (parameter) => parameter.kind == ParameterKind.optionalPositional,
        )
        .toList();
    final named = parameters
        .where(
          (parameter) =>
              parameter.kind == ParameterKind.requiredNamed ||
              parameter.kind == ParameterKind.optionalNamed,
        )
        .toList();
    for (final parameter in requiredPositional) {
      buffer.writeln('$indent${_renderParameter(parameter)},');
    }
    if (optionalPositional.isNotEmpty) {
      buffer.writeln('$indent[');
      for (final parameter in optionalPositional) {
        buffer.writeln('$indent  ${_renderParameter(parameter)},');
      }
      buffer.writeln('$indent]');
    }
    if (named.isNotEmpty) {
      buffer.writeln('$indent{');
      for (final parameter in named) {
        buffer.writeln('$indent  ${_renderParameter(parameter)},');
      }
      buffer.writeln('$indent}');
    }
  }

  String _renderParameter(ConstructorParameterSchema parameter) {
    final witnessTarget = _semanticWitnessTarget(parameter);
    final type = witnessTarget == null
        ? _dartType(parameter.shape)
        : _dataforgeType(witnessTarget);
    final required = parameter.kind == ParameterKind.requiredNamed
        ? 'required '
        : '';
    final defaultValue =
        parameter.defaultValueCode ??
        (parameter.fieldName == null
            ? null
            : schema.fields
                  .firstWhere((field) => field.name == parameter.fieldName)
                  .defaultValueCode);
    final suffix = defaultValue == null ? '' : ' = $defaultValue';
    return '$required$type ${parameter.name}$suffix';
  }

  void _writeInitializerList(
    StringBuffer buffer,
    List<String> initializers, {
    required String indent,
  }) {
    for (var index = 0; index < initializers.length; index++) {
      buffer.write(index == 0 ? '$indent: ' : '$indent  ');
      buffer.write(initializers[index]);
      if (index != initializers.length - 1) buffer.writeln(',');
    }
  }

  String _compileWitness(
    TypeShape shape,
    Map<TypeShape, String> scope, {
    required String target,
    bool eraseTypeArguments = false,
  }) {
    final explicit = scope[shape];
    if (explicit != null) return explicit;

    if (shape is NullableShape) {
      return '${_runtime('DataforgeTypes')}.nullable('
          '${_compileWitness(shape.inner, scope, target: target, eraseTypeArguments: eraseTypeArguments)})';
    }
    if (shape is ScalarShape) {
      final member = switch (shape.scalarKind) {
        ScalarKind.string => 'string',
        ScalarKind.boolean => 'boolType',
        ScalarKind.integer => 'intType',
        ScalarKind.doublePrecision => 'doubleType',
        ScalarKind.number => 'numType',
        ScalarKind.dynamicType ||
        ScalarKind.object ||
        ScalarKind.never ||
        ScalarKind.voidType => null,
      };
      if (member != null) return '${_runtime('DataforgeTypes')}.$member';
    } else if (shape is EnumShape) {
      return '${_runtime('DataforgeTypes')}.enumeration('
          '${symbolNameResolver(shape.symbol)}.values)';
    } else if (shape is DateTimeShape) {
      return '${_runtime('DataforgeTypes')}.dateTime';
    } else if (shape is DurationShape) {
      return '${_runtime('DataforgeTypes')}.duration';
    } else if (shape is ListShape) {
      return '${_runtime('DataforgeTypes')}.list('
          '${_compileWitness(shape.element, scope, target: target, eraseTypeArguments: eraseTypeArguments)})';
    } else if (shape is SetShape) {
      return '${_runtime('DataforgeTypes')}.set('
          '${_compileWitness(shape.element, scope, target: target, eraseTypeArguments: eraseTypeArguments)})';
    } else if (shape is MapShape) {
      return '${_runtime('DataforgeTypes')}.map('
          '${_compileWitness(shape.key, scope, target: target, eraseTypeArguments: eraseTypeArguments)}, '
          '${_compileWitness(shape.value, scope, target: target, eraseTypeArguments: eraseTypeArguments)})';
    } else if (shape is RecordShape) {
      final index = _recordShapeIndexes[shape];
      if (index == null) {
        _fail(
          GenerationDiagnosticCode.unsupportedType,
          'RecordShape 缺少已编译的私有 witness。',
          target: target,
          details: {'shape': shape.toMap()},
        );
      }
      final children = _recordChildren(shape);
      final arguments = children
          .map(
            (child) => _compileWitness(
              child.shape,
              scope,
              target: target,
              eraseTypeArguments: eraseTypeArguments,
            ),
          )
          .join(', ');
      final typeUse = eraseTypeArguments ? _erasedTypeUse : _typeUse;
      return '${_recordTypeImplementationName(index)}$typeUse($arguments)';
    } else if (shape is ModelShape) {
      final witnessSymbol = SymbolId(
        libraryUri: shape.modelId.libraryUri,
        name: r'$' + shape.modelId.name + 'Type',
      );
      final witnessName = symbolNameResolver(witnessSymbol);
      if (shape.witnessArguments.isEmpty) {
        if (shape.typeArguments.isNotEmpty) {
          _fail(
            GenerationDiagnosticCode.genericTypeWitnessRequired,
            '泛型 ModelShape ${shape.modelId.name} 缺少 witnessArguments。',
            target: target,
            details: {'shape': shape.toMap()},
          );
        }
        return witnessName;
      }
      final typeArguments = shape.typeArguments.isEmpty
          ? ''
          : eraseTypeArguments
          ? '<${List.filled(shape.typeArguments.length, 'dynamic').join(', ')}>'
          : '<${shape.typeArguments.map((argument) => _dartType(argument)).join(', ')}>';
      final arguments = shape.witnessArguments
          .map(
            (argument) => _compileWitness(
              argument,
              scope,
              target: target,
              eraseTypeArguments: eraseTypeArguments,
            ),
          )
          .join(', ');
      return '$witnessName$typeArguments($arguments)';
    }

    _fail(
      shape is TypeParameterShape
          ? GenerationDiagnosticCode.genericTypeWitnessRequired
          : GenerationDiagnosticCode.unsupportedType,
      'TypeShape ${shape.toDartType(resolveSymbol: symbolNameResolver)} '
      '缺少可用的 DataforgeType witness。',
      target: target,
      details: {'shape': shape.toMap()},
    );
  }

  Map<TypeShape, String> _witnessScope({required bool usePrivateState}) {
    return <TypeShape, String>{
      for (final witness in _semanticWitnesses)
        witness.targetShape: usePrivateState
            ? witness.stateName
            : witness.parameter.name,
    };
  }

  Map<TypeShape, String> _instanceWitnessScope(String instance) {
    return <TypeShape, String>{
      for (final witness in _semanticWitnesses)
        witness.targetShape: '$instance.${witness.stateName}',
    };
  }

  String _dartType(TypeShape shape) =>
      shape.toDartType(resolveSymbol: symbolNameResolver);

  String _erasedDartType(TypeShape shape) {
    if (shape is TypeParameterShape) return 'dynamic';
    if (shape is NullableShape) {
      return '${_erasedDartType(shape.inner)}?';
    }
    if (shape is ListShape) {
      return 'List<${_erasedDartType(shape.element)}>';
    }
    if (shape is SetShape) {
      return 'Set<${_erasedDartType(shape.element)}>';
    }
    if (shape is MapShape) {
      return 'Map<${_erasedDartType(shape.key)}, '
          '${_erasedDartType(shape.value)}>';
    }
    if (shape is ModelShape) {
      return _renderErasedParameterizedType(
        symbolNameResolver(shape.modelId.symbol),
        shape.typeArguments,
      );
    }
    if (shape is CustomShape) {
      return _renderErasedParameterizedType(
        symbolNameResolver(shape.symbol),
        shape.typeArguments,
      );
    }
    if (shape is RecordShape) {
      final pieces = shape.positional.map(_erasedDartType).toList();
      if (shape.named.isNotEmpty) {
        pieces.add(
          '{${shape.named.entries.map((entry) => '${_erasedDartType(entry.value)} ${entry.key}').join(', ')}}',
        );
      }
      if (shape.positional.length == 1 && shape.named.isEmpty) {
        return '(${pieces.single},)';
      }
      return '(${pieces.join(', ')})';
    }
    return _dartType(shape);
  }

  String _renderErasedParameterizedType(
    String name,
    List<TypeShape> arguments,
  ) {
    if (arguments.isEmpty) return name;
    return '$name<${arguments.map(_erasedDartType).join(', ')}>';
  }

  String _dataforgeType(TypeShape shape) =>
      '${_runtime('DataforgeType')}<${_dartType(shape)}>';

  String? _effectiveDefault(FieldSchema field) {
    return field.defaultValueCode ??
        _fieldParameters[field.name]?.defaultValueCode;
  }

  bool _containsTypeParameter(TypeShape shape, String name) {
    if (shape is TypeParameterShape) return shape.name == name;
    if (shape is NullableShape) {
      return _containsTypeParameter(shape.inner, name);
    }
    if (shape is ListShape) return _containsTypeParameter(shape.element, name);
    if (shape is SetShape) return _containsTypeParameter(shape.element, name);
    if (shape is MapShape) {
      return _containsTypeParameter(shape.key, name) ||
          _containsTypeParameter(shape.value, name);
    }
    if (shape is ModelShape) {
      return shape.typeArguments.any(
            (argument) => _containsTypeParameter(argument, name),
          ) ||
          shape.witnessArguments.any(
            (argument) => _containsTypeParameter(argument, name),
          );
    }
    if (shape is CustomShape) {
      return shape.typeArguments.any(
        (argument) => _containsTypeParameter(argument, name),
      );
    }
    if (shape is RecordShape) {
      return shape.positional.any(
            (item) => _containsTypeParameter(item, name),
          ) ||
          shape.named.values.any((item) => _containsTypeParameter(item, name));
    }
    return false;
  }

  String _jsonKeyVariable(FieldSchema field) =>
      _decodeNames.fields[field.name]!.key;
  String _jsonPresentVariable(FieldSchema field) =>
      _decodeNames.fields[field.name]!.present;

  String _quote(String value) => jsonEncode(value).replaceAll(r'$', r'\$');

  Never _fail(
    GenerationDiagnosticCode code,
    String message, {
    required String target,
    Map<String, Object?> details = const {},
  }) {
    throw ModelSchemaWriterException(
      GenerationDiagnostic(
        code: code,
        severity: GenerationDiagnosticSeverity.error,
        message: message,
        schemaId: schema.id,
        target: target,
        details: details,
      ),
    );
  }
}

final class _SemanticWitness {
  const _SemanticWitness({
    required this.parameter,
    required this.targetShape,
    required this.stateName,
  });

  final ConstructorParameterSchema parameter;
  final TypeShape targetShape;
  final String stateName;
}

final class _RecordChild {
  const _RecordChild({
    required this.shape,
    required this.stateName,
    required this.accessor,
    this.name,
  });

  final TypeShape shape;
  final String stateName;
  final String accessor;
  final String? name;
}

final class _DecodeNames {
  _DecodeNames({
    required this.json,
    required this.context,
    required this.modelContext,
    required this.normalizedJson,
    required this.acceptedJsonKeys,
    required this.iterationKey,
    required Map<String, _FieldDecodeNames> fields,
  }) : fields = Map<String, _FieldDecodeNames>.unmodifiable(fields);

  final String json;
  final String context;
  final String modelContext;
  final String normalizedJson;
  final String acceptedJsonKeys;
  final String iterationKey;
  final Map<String, _FieldDecodeNames> fields;
}

final class _FieldDecodeNames {
  const _FieldDecodeNames({
    required this.keys,
    required this.key,
    required this.present,
  });

  final String keys;
  final String key;
  final String present;
}

String _indent(String source, int spaces) {
  final prefix = ' ' * spaces;
  return source
      .split('\n')
      .map((line) => line.isEmpty ? '' : '$prefix$line')
      .join('\n');
}
