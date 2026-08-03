import 'package:analyzer/dart/constant/value.dart';
import 'dart:convert';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

import 'diagnostics.dart';
import 'schema.dart';

/// Stable result of building a v1 schema from resolved Analyzer elements.
///
/// Every input class is handled by the v1 contract. When validation reports an
/// error, [schema] is `null` and [diagnostics] contains the stable explanation.
final class BuildResult {
  final ModelSchema? schema;
  final List<GenerationDiagnostic> diagnostics;
  final String? annotationPrefix;
  final Map<SymbolId, String> symbolNames;

  BuildResult._({
    required this.schema,
    List<GenerationDiagnostic> diagnostics = const [],
    this.annotationPrefix,
    Map<SymbolId, String> symbolNames = const {},
  }) : diagnostics = List<GenerationDiagnostic>.unmodifiable(
         [...diagnostics]..sort(),
       ),
       symbolNames = Map<SymbolId, String>.unmodifiable(symbolNames);

  bool get hasErrors => diagnostics.any(
    (diagnostic) => diagnostic.severity == GenerationDiagnosticSeverity.error,
  );

  /// Returns a legal source reference for code generation in this library.
  String resolveSymbol(SymbolId symbol) {
    final exact = symbolNames[symbol];
    if (exact != null) return exact;
    return symbol.name;
  }
}

/// Builds a [ModelSchema] from resolved Analyzer elements.
///
/// Annotations, witnesses, and types are identified by canonical library URI,
/// never by import spelling, display strings, or project-wide simple names.
final class V1ModelSchemaBuilder {
  static const SymbolId defaultDataforgeAnnotation = SymbolId(
    libraryUri: 'package:dataforge_annotation/src/annotation.dart',
    name: 'Dataforge',
  );
  static const SymbolId defaultJsonKeyAnnotation = SymbolId(
    libraryUri: 'package:dataforge_annotation/src/annotation.dart',
    name: 'JsonKey',
  );
  static const SymbolId defaultDataforgeType = SymbolId(
    libraryUri: 'package:dataforge_annotation/src/runtime.dart',
    name: 'DataforgeType',
  );
  static const SymbolId defaultDataforgeDefaultAnnotation = SymbolId(
    libraryUri: 'package:dataforge_annotation/src/annotation.dart',
    name: 'DataforgeDefault',
  );

  final SymbolId dataforgeAnnotation;
  final SymbolId jsonKeyAnnotation;
  final SymbolId dataforgeType;
  final SymbolId dataforgeDefaultAnnotation;

  const V1ModelSchemaBuilder({
    this.dataforgeAnnotation = defaultDataforgeAnnotation,
    this.jsonKeyAnnotation = defaultJsonKeyAnnotation,
    this.dataforgeType = defaultDataforgeType,
    this.dataforgeDefaultAnnotation = defaultDataforgeDefaultAnnotation,
  });

  /// Builds one resolved class under the exclusive v1 contract.
  BuildResult build(ClassElement classElement) {
    final modelId = SchemaId(
      libraryUri: classElement.library.uri.toString(),
      name: classElement.name ?? '',
    );
    final annotations = _findAnnotations(classElement, dataforgeAnnotation);
    if (annotations.isEmpty) {
      return BuildResult._(
        schema: null,
        diagnostics: [
          _diagnostic(
            code: GenerationDiagnosticCode.invalidModel,
            message:
                'A v1 model must declare the canonical @Dataforge annotation.',
            schemaId: modelId,
            target: 'annotations.dataforge',
            element: classElement,
            details: const {'expected': '@Dataforge'},
          ),
        ],
      );
    }
    final annotation = annotations.first;

    final factory = _unnamedRedirectingFactory(classElement);
    if (factory == null) {
      final diagnostics = <GenerationDiagnostic>[];
      _validateDataforgeAnnotationMultiplicity(
        classElement,
        modelId,
        annotations,
        diagnostics,
      );
      if (!classElement.isAbstract || !classElement.isFinal) {
        diagnostics.add(
          _diagnostic(
            code: GenerationDiagnosticCode.invalidModel,
            message: 'A Dataforge model must be declared as abstract final.',
            schemaId: modelId,
            target: 'model.modifier',
            element: classElement,
            details: const {'expected': 'abstract final class'},
          ),
        );
      }
      _validateLibraryGeneratedSymbolCollisions(
        classElement,
        modelId,
        diagnostics,
      );
      diagnostics.add(
        _diagnostic(
          code: GenerationDiagnosticCode.invalidModel,
          message:
              'A Dataforge model must declare an unnamed factory that redirects '
              'to its generated implementation.',
          schemaId: modelId,
          target: 'constructors.new',
          element: classElement,
          details: const {'expected': 'redirecting unnamed factory'},
        ),
      );
      return BuildResult._(schema: null, diagnostics: diagnostics);
    }

    final diagnostics = <GenerationDiagnostic>[];
    _validateDataforgeAnnotationMultiplicity(
      classElement,
      modelId,
      annotations,
      diagnostics,
    );
    _validateLibraryGeneratedSymbolCollisions(
      classElement,
      modelId,
      diagnostics,
    );
    final renderContext = _SymbolRenderContext(
      classElement,
      reservedQualifiers: {
        'other',
        'value',
        'left',
        'right',
        'json',
        'context',
        for (final parameter in classElement.typeParameters)
          parameter.name ?? '',
        for (final parameter in factory.formalParameters) parameter.name ?? '',
      }..remove(''),
    );
    final annotationType = annotation.type;
    if (annotationType is InterfaceType) {
      renderContext.remember(annotationType.element);
    }
    final runtimePrefix = renderContext.findPrefixFor({
      'DataforgeType': dataforgeType,
      'DataforgeTypes': SymbolId(
        libraryUri: dataforgeType.libraryUri,
        name: 'DataforgeTypes',
      ),
      'DataforgeTypeIdentity': SymbolId(
        libraryUri: dataforgeType.libraryUri,
        name: 'DataforgeTypeIdentity',
      ),
      'DataforgeTypeErasedEquality': SymbolId(
        libraryUri: dataforgeType.libraryUri,
        name: 'DataforgeTypeErasedEquality',
      ),
      'DataforgeJsonErrorCode': SymbolId(
        libraryUri: dataforgeType.libraryUri,
        name: 'DataforgeJsonErrorCode',
      ),
      'JsonDecodeContext': SymbolId(
        libraryUri: dataforgeType.libraryUri,
        name: 'JsonDecodeContext',
      ),
      'JsonEncodeContext': SymbolId(
        libraryUri: dataforgeType.libraryUri,
        name: 'JsonEncodeContext',
      ),
      'dataforgeDecode': SymbolId(
        libraryUri: dataforgeType.libraryUri,
        name: 'dataforgeDecode',
      ),
      'dataforgeFreeze': SymbolId(
        libraryUri: dataforgeType.libraryUri,
        name: 'dataforgeFreeze',
      ),
      'dataforgeNormalizeJsonObject': SymbolId(
        libraryUri: dataforgeType.libraryUri,
        name: 'dataforgeNormalizeJsonObject',
      ),
      'dataforgeJsonActualType': SymbolId(
        libraryUri: dataforgeType.libraryUri,
        name: 'dataforgeJsonActualType',
      ),
      'dataforgeEncode': SymbolId(
        libraryUri: dataforgeType.libraryUri,
        name: 'dataforgeEncode',
      ),
      'dataforgeTypeEquals': SymbolId(
        libraryUri: dataforgeType.libraryUri,
        name: 'dataforgeTypeEquals',
      ),
      'dataforgeTypeHash': SymbolId(
        libraryUri: dataforgeType.libraryUri,
        name: 'dataforgeTypeHash',
      ),
      'dataforgeValueEquals': SymbolId(
        libraryUri: dataforgeType.libraryUri,
        name: 'dataforgeValueEquals',
      ),
    });
    if (runtimePrefix == null) {
      diagnostics.add(
        _diagnostic(
          code: GenerationDiagnosticCode.invalidModel,
          message:
              'Dataforge v1 模型必须通过同一个 import prefix 暴露完整 runtime API；'
              '请使用 `import '
              "'package:dataforge_annotation/dataforge_annotation.dart' as df;`。",
          schemaId: modelId,
          target: 'imports.dataforgeRuntime',
          element: classElement,
          details: const {
            'required': [
              'DataforgeType',
              'DataforgeTypes',
              'DataforgeTypeIdentity',
              'DataforgeTypeErasedEquality',
              'DataforgeJsonErrorCode',
              'JsonDecodeContext',
              'JsonEncodeContext',
              'dataforgeDecode',
              'dataforgeFreeze',
              'dataforgeNormalizeJsonObject',
              'dataforgeJsonActualType',
              'dataforgeEncode',
              'dataforgeTypeEquals',
              'dataforgeTypeHash',
              'dataforgeValueEquals',
            ],
          },
        ),
      );
    }
    final configuredName = annotation.getField('name')?.toStringValue();
    final implementationBase = configuredName == null || configuredName.isEmpty
        ? modelId.name
        : configuredName;
    final expectedImplementation = '_$implementationBase';
    final expectedMixin = '_\$$implementationBase';
    final includeFromJson = _includeFromJson(annotation);
    final includeToJson = _includeToJson(annotation);

    if (!classElement.isAbstract || !classElement.isFinal) {
      diagnostics.add(
        _diagnostic(
          code: GenerationDiagnosticCode.invalidModel,
          message: 'Dataforge v1 模型必须声明为 abstract final class。',
          schemaId: modelId,
          target: 'model.modifier',
          element: classElement,
          details: const {'expected': 'abstract final class'},
        ),
      );
    }
    _validateClassHierarchy(classElement, modelId, diagnostics);
    _validateGeneratedMixin(classElement, modelId, expectedMixin, diagnostics);

    final redirectTarget = _redirectTarget(factory);
    final redirectedTypeName = redirectTarget.$1;
    final redirectedConstructorName = redirectTarget.$2;
    if (redirectedTypeName != expectedImplementation ||
        redirectedConstructorName != 'new') {
      diagnostics.add(
        _diagnostic(
          code: GenerationDiagnosticCode.constructorMismatch,
          message:
              'Unnamed factory 必须重定向到 '
              '$expectedImplementation 的 unnamed constructor。',
          schemaId: modelId,
          target: 'constructors.new.redirect',
          element: factory,
          details: {
            'expectedImplementation': expectedImplementation,
            'actualImplementation': redirectedTypeName,
            'actualConstructor': redirectedConstructorName,
          },
        ),
      );
    }

    if (factory.isConst) {
      diagnostics.add(
        _diagnostic(
          code: GenerationDiagnosticCode.constructorMismatch,
          message: 'Dataforge v1 的公共 factory 不能是 const。',
          schemaId: modelId,
          target: 'constructors.new.const',
          element: factory,
          details: const {'expected': 'non-const factory'},
        ),
      );
    }

    _validateMutableDeclarations(classElement, modelId, diagnostics);
    _validateConstructorSet(
      classElement,
      modelId,
      includeFromJson,
      diagnostics,
    );
    _validateGeneratedMemberDeclarations(
      classElement,
      factory,
      modelId,
      includeToJson,
      diagnostics,
    );
    _validateBaseConstructor(classElement, modelId, diagnostics);
    _validateImplementationBoundary(
      classElement,
      modelId,
      expectedImplementation,
      diagnostics,
    );
    _validateGeneratedImplementationReferences(
      classElement,
      modelId,
      expectedImplementation,
      includeFromJson,
      diagnostics,
    );

    final exactWitnessTypes = <DartType>{
      for (final parameter in factory.formalParameters)
        if (parameter.type case final InterfaceType type
            when _isDataforgeType(type) && type.typeArguments.length == 1)
          type.typeArguments.single,
    };
    final context = _TypeParsingContext(
      builder: this,
      modelId: modelId,
      diagnostics: diagnostics,
      renderContext: renderContext,
      exactWitnessTypes: exactWitnessTypes,
    );
    final typeParameters = <TypeParameterSchema>[];
    for (final parameter in classElement.typeParameters) {
      final bound = parameter.bound;
      final boundShape = bound == null
          ? null
          : context.parse(
              bound,
              target: 'typeParameters.${parameter.name}.bound',
              element: parameter,
              allowUnsafeTopType: true,
              // A bound contributes only to generated Dart declaration
              // identity, not field freeze/JSON/equality/hash semantics. Those
              // come from DataforgeType<T>. Keep the bound shallow so it does
              // not require unrelated model companions or expand witness
              // cycles in target signatures.
              exactSemanticBoundary: true,
              collectTypeParameterUse: false,
            );
      typeParameters.add(
        TypeParameterSchema(name: parameter.name ?? '', bound: boundShape),
      );
    }

    final constructorParameters = <ConstructorParameterSchema>[];
    final fields = <FieldSchema>[];
    final fieldParameters = <String, FormalParameterElement>{};
    final witnesses = <TypeShape, List<FormalParameterElement>>{};
    final malformedWitnesses = <FormalParameterElement>[];
    for (final parameter in factory.formalParameters) {
      final name = parameter.name ?? '';
      if (!parameter.isNamed) {
        diagnostics.add(
          _diagnostic(
            code: GenerationDiagnosticCode.constructorMismatch,
            message: 'Dataforge v1 的模型 factory 只允许 named 参数。',
            schemaId: modelId,
            target: 'constructors.new.parameters.$name',
            element: parameter,
            details: {'parameter': name, 'expected': 'named'},
          ),
        );
      }

      final isWitnessType = _isDataforgeType(parameter.type);
      final shape = context.parse(
        parameter.type,
        target: 'constructors.new.parameters.$name.type',
        element: parameter,
        // Object, Object?, and dynamic enter a schema only when an exact witness
        // covers the complete field type. The witness itself must first resolve
        // so the later pairing pass can match it.
        allowUnsafeTopType:
            isWitnessType || exactWitnessTypes.contains(parameter.type),
        collectTypeParameterUse: !isWitnessType,
      );
      final defaultValueCode = _readDefaultValue(
        parameter,
        modelId,
        diagnostics,
        renderContext,
      );
      if (shape == null) {
        if (isWitnessType) malformedWitnesses.add(parameter);
        continue;
      }

      if (isWitnessType) {
        final witness = _witnessTarget(shape);
        if (witness == null) {
          malformedWitnesses.add(parameter);
        } else {
          witnesses.putIfAbsent(witness, () => []).add(parameter);
        }
      }

      final parameterKind = _parameterKind(parameter);
      constructorParameters.add(
        ConstructorParameterSchema(
          name: name,
          shape: shape,
          kind: parameterKind,
          defaultValueCode: defaultValueCode,
          fieldName: isWitnessType ? null : name,
        ),
      );

      if (!isWitnessType) {
        fields.add(
          _buildField(
            parameter,
            shape,
            modelId,
            diagnostics,
            includeFromJson,
            defaultValueCode,
          ),
        );
        fieldParameters[name] = parameter;
      }
    }

    _validateWitnesses(
      fields,
      fieldParameters,
      witnesses,
      malformedWitnesses,
      modelId,
      diagnostics,
    );
    _validateFromJsonConstructor(
      classElement,
      factory,
      modelId,
      expectedImplementation,
      includeFromJson,
      diagnostics,
    );
    _validateJsonNames(
      fields,
      factory,
      modelId,
      includeFromJson,
      includeToJson,
      diagnostics,
    );
    _validateGeneratedTopLevelBoundaries(classElement, modelId, {
      expectedImplementation,
      expectedMixin,
      r'$' + modelId.name + 'Type',
      r'_$' + modelId.name + 'DataforgeType',
      if (includeFromJson) r'_$' + modelId.name + 'FromJson',
      if (fields.isNotEmpty) r'_$' + modelId.name + 'CopyWithSentinel',
      for (var index = 0; index < _recordHelperCount(factory); index++)
        r'_$' + modelId.name + 'RecordDataforgeType$index',
    }, diagnostics);

    final hasErrors = diagnostics.any(
      (diagnostic) => diagnostic.severity == GenerationDiagnosticSeverity.error,
    );
    final schema = hasErrors
        ? null
        : ModelSchema(
            id: modelId,
            implementationName: expectedImplementation,
            typeParameters: typeParameters,
            constructor: ConstructorSchema(
              kind: ConstructorKind.redirectingFactory,
              isConst: factory.isConst,
              parameters: constructorParameters,
            ),
            fields: fields,
            includeFromJson: includeFromJson,
            includeToJson: includeToJson,
            generateCopyWith: true,
          );

    return BuildResult._(
      schema: schema,
      diagnostics: diagnostics,
      annotationPrefix: runtimePrefix,
      symbolNames: renderContext.names,
    );
  }

  void _validateLibraryGeneratedSymbolCollisions(
    ClassElement classElement,
    SchemaId modelId,
    List<GenerationDiagnostic> diagnostics,
  ) {
    final ownersBySymbol =
        <String, List<({ClassElement model, String role})>>{};
    for (final element
        in classElement.library.children.whereType<ClassElement>()) {
      final annotation = _findAnnotation(element, dataforgeAnnotation);
      if (annotation == null) continue;
      final factory = _unnamedRedirectingFactory(element);
      if (factory == null && (!element.isAbstract || !element.isFinal)) {
        continue;
      }

      final configuredName = annotation.getField('name')?.toStringValue();
      final modelName = element.name ?? '';
      final implementationBase =
          configuredName == null || configuredName.isEmpty
          ? modelName
          : configuredName;

      void add(String symbol, String role) {
        ownersBySymbol.putIfAbsent(symbol, () => []).add((
          model: element,
          role: role,
        ));
      }

      add('_$implementationBase', 'implementation');
      add('_\$$implementationBase', 'mixin');
      add(r'$' + modelName + 'Type', 'publicTypeWitness');
      add(r'_$' + modelName + 'DataforgeType', 'typeImplementation');
      if (_includeFromJson(annotation)) {
        add(r'_$' + modelName + 'FromJson', 'decodeFunction');
      }
      final hasValueFields =
          factory?.formalParameters.any(
            (parameter) => !_isDataforgeType(parameter.type),
          ) ??
          false;
      if (hasValueFields) {
        add(r'_$' + modelName + 'CopyWithSentinel', 'copyWithSentinel');
      }
      final recordHelperCount = _recordHelperCount(factory);
      for (var index = 0; index < recordHelperCount; index++) {
        add(
          r'_$' + modelName + 'RecordDataforgeType$index',
          'recordTypeImplementation[$index]',
        );
      }
    }

    final collisions = <String, List<({ClassElement model, String role})>>{
      for (final MapEntry(:key, :value) in ownersBySymbol.entries)
        if (value.length > 1 &&
            value.any((owner) => owner.model == classElement))
          key: value,
    };
    if (collisions.isEmpty) return;

    final symbols = collisions.keys.toList()..sort();
    final owners =
        collisions.values
            .expand((occurrences) => occurrences)
            .map(
              (owner) => SchemaId(
                libraryUri: owner.model.library.uri.toString(),
                name: owner.model.name ?? '',
              ).canonicalName,
            )
            .toSet()
            .toList()
          ..sort();
    diagnostics.add(
      _diagnostic(
        code: GenerationDiagnosticCode.invalidModel,
        message: '同一 library 中的 Dataforge 模型会生成重复的 top-level 符号。',
        schemaId: modelId,
        target: 'library.generatedSymbols',
        element: classElement,
        details: {
          'symbols': symbols,
          'models': owners,
          'occurrences': {
            for (final symbol in symbols)
              symbol: [
                for (final owner in collisions[symbol]!)
                  {
                    'model': SchemaId(
                      libraryUri: owner.model.library.uri.toString(),
                      name: owner.model.name ?? '',
                    ).canonicalName,
                    'role': owner.role,
                  },
              ],
          },
        },
      ),
    );
  }

  int _recordHelperCount(ConstructorElement? factory) {
    if (factory == null) return 0;
    final semanticWitnessTypes = <DartType>{};
    for (final parameter in factory.formalParameters) {
      final type = parameter.type;
      if (_isDataforgeType(type) &&
          type is InterfaceType &&
          type.typeArguments.length == 1) {
        semanticWitnessTypes.add(type.typeArguments.single);
      }
    }

    final records = <RecordType>[];
    // Match the schema parser's cycle identity. Guarding by InterfaceType
    // instances would never repeat for A<T> -> B<List<T>> ->
    // A<List<List<T>>>.
    final resolvingModels = <ClassElement>{};
    void visit(DartType type) {
      if (semanticWitnessTypes.contains(type)) return;
      if (type is RecordType) {
        if (!records.contains(type)) records.add(type);
        for (final field in type.positionalFields) {
          visit(field.type);
        }
        final namedFields = type.namedFields.toList()
          ..sort((left, right) => left.name.compareTo(right.name));
        for (final field in namedFields) {
          visit(field.type);
        }
        return;
      }
      if (type is! InterfaceType) return;
      final element = type.element;
      if (element is ClassElement && _isV1ModelElement(element)) {
        // The writer discovers Record helpers through
        // ModelShape.witnessArguments. InterfaceType.constructors has already
        // substituted the current type arguments, so traverse the instantiated
        // witness instead of stopping at the model boundary.
        if (!resolvingModels.add(element)) return;
        try {
          final instantiatedFactory = type.constructors
              .where(
                (constructor) =>
                    _isUnnamedConstructor(constructor) && constructor.isFactory,
              )
              .firstOrNull;
          if (instantiatedFactory == null) return;
          for (final parameter in instantiatedFactory.formalParameters) {
            final witnessType = parameter.type;
            if (_isDataforgeType(witnessType) &&
                witnessType is InterfaceType &&
                witnessType.typeArguments.length == 1) {
              visit(witnessType.typeArguments.single);
            }
          }
        } finally {
          resolvingModels.remove(element);
        }
        return;
      }
      for (final argument in type.typeArguments) {
        visit(argument);
      }
    }

    for (final parameter in factory.formalParameters) {
      if (_isDataforgeType(parameter.type)) continue;
      visit(parameter.type);
    }
    return records.length;
  }

  void _validateDataforgeAnnotationMultiplicity(
    ClassElement classElement,
    SchemaId modelId,
    List<DartObject> annotations,
    List<GenerationDiagnostic> diagnostics,
  ) {
    if (annotations.length < 2) return;
    diagnostics.add(
      _diagnostic(
        code: GenerationDiagnosticCode.invalidModel,
        message: '同一个 class 只能声明一个 canonical @Dataforge。',
        schemaId: modelId,
        target: 'annotations.dataforge',
        element: classElement,
        details: {'annotationCount': annotations.length},
      ),
    );
  }

  String? _readDefaultValue(
    FormalParameterElement parameter,
    SchemaId modelId,
    List<GenerationDiagnostic> diagnostics,
    _SymbolRenderContext renderContext,
  ) {
    final name = parameter.name ?? '';
    if (_hasSourceDefault(parameter)) {
      diagnostics.add(
        _diagnostic(
          code: GenerationDiagnosticCode.constructorMismatch,
          message:
              'Redirecting factory 参数不能直接声明默认表达式；请使用 '
              '@DataforgeDefault。',
          schemaId: modelId,
          target: 'constructors.new.parameters.$name.default',
          element: parameter,
          details: const {'expected': '@DataforgeDefault(value)'},
        ),
      );
    }

    final annotations = parameter.metadata.annotations
        .map((metadata) => metadata.computeConstantValue())
        .whereType<DartObject>()
        .where((value) => _isAnnotation(value, dataforgeDefaultAnnotation))
        .toList();
    if (annotations.isEmpty) return null;
    if (annotations.length > 1) {
      diagnostics.add(
        _diagnostic(
          code: GenerationDiagnosticCode.constructorMismatch,
          message: '同一个参数只能声明一个 @DataforgeDefault。',
          schemaId: modelId,
          target: 'constructors.new.parameters.$name.default',
          element: parameter,
          details: {'annotationCount': annotations.length},
        ),
      );
    }
    if (parameter.isRequired) {
      diagnostics.add(
        _diagnostic(
          code: GenerationDiagnosticCode.constructorMismatch,
          message: '@DataforgeDefault 只能用于 optional named 参数。',
          schemaId: modelId,
          target: 'constructors.new.parameters.$name.default',
          element: parameter,
          details: const {'expected': 'optional named parameter'},
        ),
      );
    }

    final annotation = annotations.first;
    final annotationType = annotation.type;
    if (annotationType is InterfaceType) {
      renderContext.remember(annotationType.element);
    }
    final value = annotation.getField('value');
    if (value == null) {
      diagnostics.add(
        _diagnostic(
          code: GenerationDiagnosticCode.constructorMismatch,
          message: '@DataforgeDefault is missing its resolved value.',
          schemaId: modelId,
          target: 'constructors.new.parameters.$name.default',
          element: parameter,
        ),
      );
      return null;
    }

    final parameterLibrary = parameter.library!;
    final actualType = value.type;
    final assignable =
        actualType != null &&
        (parameterLibrary.typeSystem.isAssignableTo(
              actualType,
              parameter.type,
              strictCasts: true,
            ) ||
            _isIntegerLiteralAssignableToDouble(value, parameter.type));
    if (!assignable) {
      diagnostics.add(
        _diagnostic(
          code: GenerationDiagnosticCode.constructorMismatch,
          message: '@DataforgeDefault 的 resolved 常量不能赋值给 factory 参数类型。',
          schemaId: modelId,
          target: 'constructors.new.parameters.$name.default',
          element: parameter,
          details: {
            'expectedType': parameter.type.getDisplayString(),
            'actualType': actualType?.getDisplayString() ?? '<unknown>',
          },
        ),
      );
      return null;
    }

    try {
      return _encodeDefaultValue(value, renderContext);
    } on _UnsupportedDefaultValue {
      diagnostics.add(
        _diagnostic(
          code: GenerationDiagnosticCode.constructorMismatch,
          message:
              '@DataforgeDefault 只支持 null、标量、resolved enum 常量和递归 const 集合。',
          schemaId: modelId,
          target: 'constructors.new.parameters.$name.default',
          element: parameter,
          details: {'actualType': value.type?.getDisplayString()},
        ),
      );
      return null;
    }
  }

  static String _encodeDefaultValue(
    DartObject? value,
    _SymbolRenderContext renderContext,
  ) {
    if (value == null || value.isNull) return 'null';
    final boolValue = value.toBoolValue();
    if (boolValue != null) return boolValue ? 'true' : 'false';
    final intValue = value.toIntValue();
    if (intValue != null) return '$intValue';
    final doubleValue = value.toDoubleValue();
    if (doubleValue != null) {
      if (!doubleValue.isFinite) throw const _UnsupportedDefaultValue();
      return '$doubleValue';
    }
    final stringValue = value.toStringValue();
    if (stringValue != null) {
      return jsonEncode(stringValue).replaceAll(r'$', r'\$');
    }
    final valueType = value.type;
    if (valueType is InterfaceType && valueType.element is EnumElement) {
      final enumReference = renderContext.rememberTypeReference(valueType);
      final variable = value.variable;
      final valueName = variable?.enclosingElement == valueType.element
          ? variable?.name
          : value.getField('name')?.toStringValue();
      if (enumReference == null || valueName == null || valueName.isEmpty) {
        throw const _UnsupportedDefaultValue();
      }
      return '$enumReference.$valueName';
    }
    final listValue = value.toListValue();
    if (listValue != null) {
      if (listValue.isEmpty) return 'const <Never>[]';
      return 'const [${listValue.map((item) => _encodeDefaultValue(item, renderContext)).join(', ')}]';
    }
    final setValue = value.toSetValue();
    if (setValue != null) {
      if (setValue.isEmpty) return 'const <Never>{}';
      return 'const {${setValue.map((item) => _encodeDefaultValue(item, renderContext)).join(', ')}}';
    }
    final mapValue = value.toMapValue();
    if (mapValue != null) {
      if (mapValue.isEmpty) return 'const <Never, Never>{}';
      final entries = mapValue.entries.map(
        (entry) =>
            '${_encodeDefaultValue(entry.key, renderContext)}: '
            '${_encodeDefaultValue(entry.value, renderContext)}',
      );
      return 'const {${entries.join(', ')}}';
    }
    throw const _UnsupportedDefaultValue();
  }

  static bool _isIntegerLiteralAssignableToDouble(
    DartObject value,
    DartType targetType,
  ) {
    final integer = value.toIntValue();
    if (integer == null || !targetType.isDartCoreDouble) return false;
    final converted = integer.toDouble();
    return converted.isFinite && converted.toInt() == integer;
  }

  static bool _hasSourceDefault(FormalParameterElement parameter) {
    final enclosing = parameter.enclosingElement;
    if (enclosing is! ConstructorElement) return false;
    final declaration = _constructorDeclaration(enclosing);
    if (declaration == null) return false;
    for (final syntaxParameter in declaration.parameters.parameters) {
      if (syntaxParameter.declaredFragment?.element != parameter) continue;
      return syntaxParameter is DefaultFormalParameter &&
          syntaxParameter.defaultValue != null;
    }
    return false;
  }

  FieldSchema _buildField(
    FormalParameterElement parameter,
    TypeShape shape,
    SchemaId modelId,
    List<GenerationDiagnostic> diagnostics,
    bool modelIncludesFromJson,
    String? defaultValueCode,
  ) {
    final name = parameter.name ?? '';
    final annotations = parameter.metadata.annotations
        .map((metadata) => metadata.computeConstantValue())
        .whereType<DartObject>()
        .where((value) => _isAnnotation(value, jsonKeyAnnotation))
        .toList();

    if (annotations.length > 1) {
      diagnostics.add(
        _diagnostic(
          code: GenerationDiagnosticCode.invalidJsonConfiguration,
          message: '同一个 factory 参数只能声明一个 @JsonKey。',
          schemaId: modelId,
          target: 'fields.$name.json',
          element: parameter,
          details: {'annotationCount': annotations.length},
        ),
      );
    }

    final jsonKey = annotations.firstOrNull;
    final configuredJsonName = jsonKey?.getField('name')?.toStringValue();
    final jsonName = configuredJsonName == null || configuredJsonName.isEmpty
        ? name
        : configuredJsonName;
    final alternateJsonNames = _readStringList(
      jsonKey?.getField('alternateNames'),
    );
    final ignored = jsonKey?.getField('ignore')?.toBoolValue() ?? false;
    final includeIfNull = jsonKey?.getField('includeIfNull')?.toBoolValue();
    if (ignored && modelIncludesFromJson && defaultValueCode == null) {
      diagnostics.add(
        _diagnostic(
          code: GenerationDiagnosticCode.invalidJsonConfiguration,
          message: '被 @JsonKey(ignore: true) 排除的参数必须声明 factory default。',
          schemaId: modelId,
          target: 'fields.$name.json.ignore',
          element: parameter,
          details: const {'expected': 'factory default value'},
        ),
      );
    }
    return FieldSchema(
      name: name,
      shape: shape,
      isFinal: true,
      isRequired: parameter.isRequiredNamed,
      jsonName: jsonName,
      alternateJsonNames: alternateJsonNames,
      defaultValueCode: defaultValueCode,
      includeFromJson: !ignored,
      includeToJson: !ignored,
      includeIfNull: includeIfNull,
    );
  }

  void _validateMutableDeclarations(
    ClassElement classElement,
    SchemaId modelId,
    List<GenerationDiagnostic> diagnostics,
  ) {
    for (final field in classElement.fields) {
      if (field.isStatic || field.isSynthetic) continue;
      diagnostics.add(
        _diagnostic(
          code: GenerationDiagnosticCode.mutableField,
          message: 'Dataforge v1 的 factory-only 基类不能声明实例字段。',
          schemaId: modelId,
          target: 'fields.${field.name}',
          element: field,
          details: {'field': field.name},
        ),
      );
    }
    for (final setter in classElement.setters) {
      if (setter.isStatic || setter.isSynthetic) continue;
      diagnostics.add(
        _diagnostic(
          code: GenerationDiagnosticCode.mutableField,
          message: 'Dataforge v1 模型不能声明实例 setter。',
          schemaId: modelId,
          target: 'fields.${setter.name}',
          element: setter,
          details: {'setter': setter.name},
        ),
      );
    }
  }

  void _validateConstructorSet(
    ClassElement classElement,
    SchemaId modelId,
    bool includeFromJson,
    List<GenerationDiagnostic> diagnostics,
  ) {
    final allowedNames = <String>{'new', '_', if (includeFromJson) 'fromJson'};
    for (final constructor in classElement.constructors) {
      if (allowedNames.contains(constructor.name)) continue;
      diagnostics.add(
        _diagnostic(
          code: GenerationDiagnosticCode.invalidModel,
          message:
              'Dataforge v1 factory-only 模型不能声明额外 constructor '
              '${constructor.name}。',
          schemaId: modelId,
          target: 'constructors.${constructor.name}',
          element: constructor,
          details: {
            'constructor': constructor.name,
            'allowed': allowedNames.toList()..sort(),
          },
        ),
      );
    }
  }

  void _validateGeneratedMemberDeclarations(
    ClassElement classElement,
    ConstructorElement factory,
    SchemaId modelId,
    bool includeToJson,
    List<GenerationDiagnostic> diagnostics,
  ) {
    final generatedMethodNames = <String>{
      'copyWith',
      '==',
      'toString',
      if (includeToJson) 'toJson',
    };
    for (final method in classElement.methods) {
      if (method.isStatic || !generatedMethodNames.contains(method.name)) {
        continue;
      }
      diagnostics.add(
        _diagnostic(
          code: GenerationDiagnosticCode.invalidModel,
          message: '${method.name} 由 Dataforge 生成，factory-only 基类不能自行声明。',
          schemaId: modelId,
          target: 'members.${method.name}',
          element: method,
          details: {'member': method.name},
        ),
      );
    }

    final generatedGetterNames = <String>{
      'hashCode',
      for (final parameter in factory.formalParameters)
        if (!_isDataforgeType(parameter.type)) parameter.name ?? '',
    }..remove('');
    for (final getter in classElement.getters) {
      if (getter.isStatic ||
          getter.isSynthetic ||
          !generatedGetterNames.contains(getter.name)) {
        continue;
      }
      diagnostics.add(
        _diagnostic(
          code: GenerationDiagnosticCode.invalidModel,
          message: '${getter.name} 由 factory 参数唯一派生，基类不能重复声明 getter。',
          schemaId: modelId,
          target: 'members.${getter.name}',
          element: getter,
          details: {'member': getter.name},
        ),
      );
    }
  }

  void _validateGeneratedMixin(
    ClassElement classElement,
    SchemaId modelId,
    String expectedMixin,
    List<GenerationDiagnostic> diagnostics,
  ) {
    final declaration = _classDeclaration(classElement);
    final mixins = declaration?.withClause?.mixinTypes ?? const <NamedType>[];
    final expectedArguments = classElement.typeParameters
        .map((parameter) => parameter.name ?? '')
        .toList();
    final expectedSourceUri = _generatedPartUri(
      classElement.library.firstFragment.source.uri,
    );
    final resolvedMixinDeclarations = classElement.library.children
        .where((element) => element.name == expectedMixin)
        .toList();
    final resolvedSourceUris = resolvedMixinDeclarations
        .map((element) => element.firstFragment.libraryFragment?.source.uri)
        .whereType<Uri>()
        .toSet();
    final resolvedBoundaryValid =
        resolvedMixinDeclarations.isEmpty ||
        (resolvedSourceUris.length == 1 &&
            resolvedSourceUris.single == expectedSourceUri);
    final valid =
        mixins.length == 1 &&
        mixins.single.name.lexeme == expectedMixin &&
        _namedTypeArguments(mixins.single).join(',') ==
            expectedArguments.join(',') &&
        resolvedBoundaryValid;
    if (valid) return;

    diagnostics.add(
      _diagnostic(
        code: GenerationDiagnosticCode.invalidModel,
        message:
            'Dataforge v1 模型必须且只能 mix in 预期 .data.dart 生成的 '
            '$expectedMixin${expectedArguments.isEmpty ? '' : '<${expectedArguments.join(', ')}>'}。',
        schemaId: modelId,
        target: 'model.mixin',
        element: classElement,
        details: {
          'expected': expectedMixin,
          'expectedTypeArguments': expectedArguments,
          'expectedSourceUri': expectedSourceUri.toString(),
          if (resolvedSourceUris.isNotEmpty)
            'actualSourceUri': resolvedSourceUris.first.toString(),
          'actual': mixins.map((type) => type.toSource()).toList(),
        },
      ),
    );
  }

  void _validateClassHierarchy(
    ClassElement classElement,
    SchemaId modelId,
    List<GenerationDiagnostic> diagnostics,
  ) {
    final declaration = _classDeclaration(classElement);
    final superclass = classElement.supertype;
    if (superclass == null || !superclass.isDartCoreObject) {
      diagnostics.add(
        _diagnostic(
          code: GenerationDiagnosticCode.invalidModel,
          message:
              'Dataforge v1 模型必须直接继承 Object；'
              '父类状态不会进入 factory schema、相等性或 hashCode。',
          schemaId: modelId,
          target: 'model.superclass',
          element: classElement,
          details: {
            'actual':
                declaration?.extendsClause?.superclass.toSource() ??
                superclass?.getDisplayString() ??
                '<unresolved>',
            if (superclass != null)
              'libraryUri': superclass.element.library.uri.toString(),
            'expected': 'dart:core Object',
          },
        ),
      );
    }

    final interfaceSyntax =
        declaration?.implementsClause?.interfaces ?? const <NamedType>[];
    if (classElement.interfaces.isNotEmpty || interfaceSyntax.isNotEmpty) {
      final actual = interfaceSyntax.isNotEmpty
          ? interfaceSyntax.map((type) => type.toSource()).toList()
          : classElement.interfaces
                .map((type) => type.getDisplayString())
                .toList();
      diagnostics.add(
        _diagnostic(
          code: GenerationDiagnosticCode.invalidModel,
          message:
              'Dataforge v1 模型不能声明 implements；'
              '额外契约不会由 factory schema 的唯一生成实现安全满足。',
          schemaId: modelId,
          target: 'model.interfaces',
          element: classElement,
          details: {'actual': actual, 'expected': const <String>[]},
        ),
      );
    }
  }

  void _validateFromJsonConstructor(
    ClassElement classElement,
    ConstructorElement valueFactory,
    SchemaId modelId,
    String expectedImplementation,
    bool includeFromJson,
    List<GenerationDiagnostic> diagnostics,
  ) {
    if (!includeFromJson) return;

    final fromJson = classElement.constructors
        .where((constructor) => constructor.name == 'fromJson')
        .firstOrNull;
    if (fromJson == null) {
      diagnostics.add(
        _diagnostic(
          code: GenerationDiagnosticCode.constructorMismatch,
          message:
              '启用 fromJson 的 v1 模型必须声明 redirecting '
              '`factory ${modelId.name}.fromJson(...) = '
              '$expectedImplementation.fromJson;`。',
          schemaId: modelId,
          target: 'constructors.fromJson',
          element: classElement,
          details: {'expectedImplementation': expectedImplementation},
        ),
      );
      return;
    }

    final redirectTarget = _redirectTarget(fromJson);
    final redirectedTypeName = redirectTarget.$1;
    final redirectedConstructorName = redirectTarget.$2;
    final parameters = fromJson.formalParameters;
    final jsonParameterValid =
        parameters.isNotEmpty &&
        parameters.first.isRequiredPositional &&
        _isStrictJsonMap(parameters.first.type);
    final expectedWitnesses = valueFactory.formalParameters
        .where((parameter) => _isDataforgeType(parameter.type))
        .toList();
    final actualWitnesses = parameters.skip(1).toList();
    final witnessSignatureValid =
        actualWitnesses.length == expectedWitnesses.length &&
        expectedWitnesses.every((expected) {
          final actual = actualWitnesses
              .where((candidate) => candidate.name == expected.name)
              .firstOrNull;
          return actual != null &&
              actual.isRequiredNamed &&
              actual.type == expected.type;
        });
    final valid =
        fromJson.isFactory &&
        _hasRedirectSyntax(fromJson) &&
        redirectedTypeName == expectedImplementation &&
        redirectedConstructorName == 'fromJson' &&
        jsonParameterValid &&
        witnessSignatureValid;
    if (valid) return;

    diagnostics.add(
      _diagnostic(
        code: GenerationDiagnosticCode.constructorMismatch,
        message:
            'fromJson 必须重定向到 $expectedImplementation.fromJson，'
            '首参数为 Map<String, Object?>，并原样接收全部 required witness。',
        schemaId: modelId,
        target: 'constructors.fromJson',
        element: fromJson,
        details: {
          'expectedImplementation': expectedImplementation,
          'actualImplementation': redirectedTypeName,
          'actualConstructor': redirectedConstructorName,
          'jsonParameterValid': jsonParameterValid,
          'expectedWitnesses': expectedWitnesses
              .map((parameter) => parameter.name ?? '')
              .toList(),
          'actualWitnesses': actualWitnesses
              .map((parameter) => parameter.name ?? '')
              .toList(),
        },
      ),
    );
  }

  static bool _isStrictJsonMap(DartType type) {
    if (type is! InterfaceType ||
        !type.isDartCoreMap ||
        type.typeArguments.length != 2) {
      return false;
    }
    final key = type.typeArguments[0];
    final value = type.typeArguments[1];
    return key.isDartCoreString &&
        key.nullabilitySuffix == NullabilitySuffix.none &&
        value.isDartCoreObject &&
        value.nullabilitySuffix == NullabilitySuffix.question;
  }

  static List<String> _namedTypeArguments(NamedType type) =>
      type.typeArguments?.arguments
          .map((argument) => argument.toSource())
          .toList() ??
      const <String>[];

  void _validateBaseConstructor(
    ClassElement classElement,
    SchemaId modelId,
    List<GenerationDiagnostic> diagnostics,
  ) {
    final baseConstructor = classElement.constructors
        .where((constructor) => constructor.name == '_')
        .firstOrNull;
    final valid =
        baseConstructor != null &&
        !baseConstructor.isFactory &&
        baseConstructor.isConst &&
        baseConstructor.formalParameters.isEmpty;
    if (valid) return;

    diagnostics.add(
      _diagnostic(
        code: GenerationDiagnosticCode.constructorMismatch,
        message:
            'Dataforge v1 模型必须声明无参数的 private const generative '
            'constructor `const ${modelId.name}._();`。',
        schemaId: modelId,
        target: 'constructors._',
        element: baseConstructor ?? classElement,
        details: {
          'expected': 'const ${modelId.name}._();',
          if (baseConstructor != null) ...{
            'isFactory': baseConstructor.isFactory,
            'isConst': baseConstructor.isConst,
            'parameterCount': baseConstructor.formalParameters.length,
          },
        },
      ),
    );
  }

  void _validateImplementationBoundary(
    ClassElement classElement,
    SchemaId modelId,
    String expectedImplementation,
    List<GenerationDiagnostic> diagnostics,
  ) {
    // `final` blocks subtypes only in other libraries. Enums, mixins, and
    // extension types in the same library can still implement the model. Scan
    // every InterfaceElement, not just classes, to preserve the single
    // generated implementation boundary.
    for (final candidate
        in classElement.library.children.whereType<InterfaceElement>()) {
      if (candidate == classElement) continue;
      final isModelSubtype = candidate.allSupertypes.any(
        (supertype) => supertype.element == classElement,
      );

      if (candidate.name == expectedImplementation) {
        final implementationClass = candidate is ClassElement
            ? candidate
            : null;
        final actualSourceUri =
            candidate.firstFragment.libraryFragment.source.uri;
        final expectedSourceUri = _generatedPartUri(
          classElement.library.firstFragment.source.uri,
        );
        if (implementationClass?.isFinal == true &&
            isModelSubtype &&
            actualSourceUri == expectedSourceUri) {
          continue;
        }
        diagnostics.add(
          _diagnostic(
            code: GenerationDiagnosticCode.invalidModel,
            message:
                '实现 $expectedImplementation 只能由当前 library 的预期 '
                '.data.dart part 生成，并且必须是 final class。',
            schemaId: modelId,
            target: 'implementation.boundary',
            element: candidate,
            details: {
              'expected': 'generated final class',
              'expectedSourceUri': expectedSourceUri.toString(),
              'actualSourceUri': actualSourceUri.toString(),
              'isClass': implementationClass != null,
              'isFinal': implementationClass?.isFinal ?? false,
              'isModelSubtype': isModelSubtype,
            },
          ),
        );
        continue;
      }

      if (!isModelSubtype) continue;

      diagnostics.add(
        _diagnostic(
          code: GenerationDiagnosticCode.invalidModel,
          message:
              'Dataforge v1 模型只允许生成的 final implementation；'
              '发现额外 subtype ${candidate.name}。',
          schemaId: modelId,
          target: 'subtypes.${candidate.name}',
          element: candidate,
          details: {
            'subtype': candidate.name ?? '',
            'expectedImplementation': expectedImplementation,
          },
        ),
      );
    }
  }

  static Uri _generatedPartUri(Uri libraryUri) {
    final path = libraryUri.path;
    final generatedPath = path.endsWith('.dart')
        ? '${path.substring(0, path.length - '.dart'.length)}.data.dart'
        : '$path.data.dart';
    return libraryUri.replace(path: generatedPath);
  }

  void _validateGeneratedImplementationReferences(
    ClassElement classElement,
    SchemaId modelId,
    String expectedImplementation,
    bool includeFromJson,
    List<GenerationDiagnostic> diagnostics,
  ) {
    final parsed = classElement.library.session.getParsedLibraryByElement(
      classElement.library,
    );
    if (parsed is! ParsedLibraryResult) return;
    final generatedUri = _generatedPartUri(
      classElement.library.firstFragment.source.uri,
    );
    for (final unit in parsed.units) {
      if (unit.uri == generatedUri) continue;
      final visitor = _GeneratedImplementationReferenceVisitor(
        modelName: modelId.name,
        implementationName: expectedImplementation,
        allowFromJson: includeFromJson,
      );
      unit.unit.accept(visitor);
      for (final reference in visitor.references) {
        final characterLocation = unit.lineInfo.getLocation(reference.offset);
        diagnostics.add(
          GenerationDiagnostic(
            code: GenerationDiagnosticCode.invalidModel,
            severity: GenerationDiagnosticSeverity.error,
            message:
                '$expectedImplementation 是生成实现，用户源码不能直接引用；'
                '只能作为模型 redirecting factory 的目标。',
            schemaId: modelId,
            target: 'implementation.references',
            location: GenerationSourceLocation(
              uri: unit.uri.toString(),
              offset: reference.offset,
              length: reference.length,
              line: characterLocation.lineNumber,
              column: characterLocation.columnNumber,
            ),
            details: {
              'implementation': expectedImplementation,
              'reference': reference.toSource(),
            },
          ),
        );
      }
    }
  }

  void _validateGeneratedTopLevelBoundaries(
    ClassElement classElement,
    SchemaId modelId,
    Set<String> generatedNames,
    List<GenerationDiagnostic> diagnostics,
  ) {
    final expectedSourceUri = _generatedPartUri(
      classElement.library.firstFragment.source.uri,
    );
    final collisions =
        classElement.library.children
            .where((element) => generatedNames.contains(element.name))
            .where(
              (element) =>
                  element.firstFragment.libraryFragment?.source.uri !=
                  expectedSourceUri,
            )
            .toList()
          ..sort((left, right) {
            final nameOrder = (left.name ?? '').compareTo(right.name ?? '');
            if (nameOrder != 0) return nameOrder;
            return left.firstFragment.offset.compareTo(
              right.firstFragment.offset,
            );
          });
    final reportedNames = <String>{};
    for (final collision in collisions) {
      final name = collision.name ?? '';
      if (!reportedNames.add(name)) continue;
      diagnostics.add(
        _diagnostic(
          code: GenerationDiagnosticCode.invalidModel,
          message: '$name 是 Dataforge 生成器保留的 top-level 符号。',
          schemaId: modelId,
          target: 'generatedSymbols.$name',
          element: collision,
          details: {
            'symbol': name,
            'expectedSourceUri': expectedSourceUri.toString(),
            'actualSourceUri': collision
                .firstFragment
                .libraryFragment
                ?.source
                .uri
                .toString(),
          },
        ),
      );
    }
  }

  void _validateWitnesses(
    List<FieldSchema> fields,
    Map<String, FormalParameterElement> fieldParameters,
    Map<TypeShape, List<FormalParameterElement>> witnesses,
    List<FormalParameterElement> malformed,
    SchemaId modelId,
    List<GenerationDiagnostic> diagnostics,
  ) {
    for (final parameter in malformed) {
      diagnostics.add(
        _diagnostic(
          code: GenerationDiagnosticCode.genericTypeWitnessRequired,
          message: 'DataforgeType<X> 必须是非空且可解析的 exact semantic witness。',
          schemaId: modelId,
          target: 'constructors.new.parameters.${parameter.name}.witness',
          element: parameter,
          details: {
            'parameter': parameter.name,
            'actualType': parameter.type.getDisplayString(),
          },
        ),
      );
    }

    for (final entry in witnesses.entries) {
      if (entry.value.length > 1) {
        diagnostics.add(
          _diagnostic(
            code: GenerationDiagnosticCode.genericTypeWitnessRequired,
            message: '同一个 exact type 只能声明一个 DataforgeType witness。',
            schemaId: modelId,
            target: 'witnesses.${entry.key.kind}.duplicate',
            element: entry.value.first,
            details: {
              'shape': entry.key.toMap(),
              'expectedCount': 1,
              'actualCount': entry.value.length,
            },
          ),
        );
      }
    }

    final usedWitnesses = <TypeShape>{};
    for (final field in fields) {
      final missing = <TypeShape>{};
      _collectMissingWitnesses(
        field.shape,
        witnesses.keys.toSet(),
        usedWitnesses,
        missing,
      );
      for (final shape in missing) {
        diagnostics.add(
          _diagnostic(
            code: GenerationDiagnosticCode.genericTypeWitnessRequired,
            message:
                '字段 ${field.name} 的 ${shape.toDartType()} 需要 '
                'DataforgeType<${shape.toDartType()}> witness。',
            schemaId: modelId,
            target: 'fields.${field.name}.witness.${shape.kind}',
            element: fieldParameters[field.name]!,
            details: {'field': field.name, 'shape': shape.toMap()},
          ),
        );
      }
    }

    for (final entry in witnesses.entries) {
      if (usedWitnesses.contains(entry.key)) continue;
      diagnostics.add(
        _diagnostic(
          code: GenerationDiagnosticCode.genericTypeWitnessRequired,
          message: 'DataforgeType<${entry.key.toDartType()}> 未匹配任何业务字段。',
          schemaId: modelId,
          target: 'witnesses.${entry.key.kind}.extra',
          element: entry.value.first,
          details: {'shape': entry.key.toMap()},
        ),
      );
    }
  }

  void _collectMissingWitnesses(
    TypeShape shape,
    Set<TypeShape> declared,
    Set<TypeShape> used,
    Set<TypeShape> missing,
  ) {
    if (declared.contains(shape)) {
      used.add(shape);
      return;
    }
    switch (shape) {
      case TypeParameterShape() || CustomShape():
        missing.add(shape);
      case NullableShape(:final inner):
        _collectMissingWitnesses(inner, declared, used, missing);
      case ListShape(:final element) || SetShape(:final element):
        _collectMissingWitnesses(element, declared, used, missing);
      case MapShape(:final key, :final value):
        _collectMissingWitnesses(key, declared, used, missing);
        _collectMissingWitnesses(value, declared, used, missing);
      case RecordShape(:final positional, :final named):
        for (final field in positional) {
          _collectMissingWitnesses(field, declared, used, missing);
        }
        for (final field in named.values) {
          _collectMissingWitnesses(field, declared, used, missing);
        }
      case ScalarShape(:final scalarKind):
        if (scalarKind == ScalarKind.object ||
            scalarKind == ScalarKind.dynamicType) {
          missing.add(shape);
        }
      case EnumShape() || DateTimeShape() || DurationShape():
        break;
      case ModelShape(:final witnessArguments):
        for (final argument in witnessArguments) {
          _collectMissingWitnesses(argument, declared, used, missing);
        }
    }
  }

  void _validateJsonNames(
    List<FieldSchema> fields,
    ConstructorElement factory,
    SchemaId modelId,
    bool modelIncludesFromJson,
    bool modelIncludesToJson,
    List<GenerationDiagnostic> diagnostics,
  ) {
    final fromJsonOwnerByName = <String, String>{};
    final toJsonOwnerByName = <String, String>{};
    final parameterByName = <String, FormalParameterElement>{
      for (final parameter in factory.formalParameters)
        if (parameter.name case final name?) name: parameter,
    };

    for (final field in fields) {
      if (modelIncludesFromJson && field.includeFromJson) {
        final localNames = <String>{};
        for (final name in [field.jsonName, ...field.alternateJsonNames]) {
          final duplicateInField = name.isEmpty || !localNames.add(name);
          final previousOwner = fromJsonOwnerByName[name];
          if (duplicateInField || previousOwner != null) {
            diagnostics.add(
              _diagnostic(
                code: GenerationDiagnosticCode.invalidJsonConfiguration,
                message: 'fromJson 名称必须非空且在输入方向唯一。',
                schemaId: modelId,
                target: 'fields.${field.name}.json',
                element: (parameterByName[field.name] ?? factory) as Element,
                details: {
                  'direction': 'fromJson',
                  'jsonName': name,
                  if (previousOwner != null) 'previousField': previousOwner,
                },
              ),
            );
          } else {
            fromJsonOwnerByName[name] = field.name;
          }
        }
      }
      if (modelIncludesToJson && field.includeToJson) {
        final name = field.jsonName;
        final previousOwner = toJsonOwnerByName[name];
        if (name.isEmpty || previousOwner != null) {
          diagnostics.add(
            _diagnostic(
              code: GenerationDiagnosticCode.invalidJsonConfiguration,
              message: 'toJson 名称必须非空且在输出方向唯一。',
              schemaId: modelId,
              target: 'fields.${field.name}.json',
              element: (parameterByName[field.name] ?? factory) as Element,
              details: {
                'direction': 'toJson',
                'jsonName': name,
                if (previousOwner != null) 'previousField': previousOwner,
              },
            ),
          );
        } else {
          toJsonOwnerByName[name] = field.name;
        }
      }
    }
  }

  TypeShape? _witnessTarget(TypeShape shape) {
    if (shape is! CustomShape ||
        shape.symbol != dataforgeType ||
        shape.typeArguments.length != 1) {
      return null;
    }
    return shape.typeArguments.single;
  }

  bool _isDataforgeType(DartType type) {
    return type is InterfaceType &&
        _matchesElement(type.element, dataforgeType);
  }

  DartObject? _findAnnotation(Element element, SymbolId annotationId) {
    return _findAnnotations(element, annotationId).firstOrNull;
  }

  List<DartObject> _findAnnotations(Element element, SymbolId annotationId) {
    return element.metadata.annotations
        .map((metadata) => metadata.computeConstantValue())
        .whereType<DartObject>()
        .where((value) => _isAnnotation(value, annotationId))
        .toList(growable: false);
  }

  bool _includeFromJson(DartObject annotation) =>
      annotation.getField('includeFromJson')?.toBoolValue() ?? true;

  bool _includeToJson(DartObject annotation) =>
      annotation.getField('includeToJson')?.toBoolValue() ?? true;

  bool _isAnnotation(DartObject value, SymbolId annotationId) {
    final type = value.type;
    return type is InterfaceType && _matchesElement(type.element, annotationId);
  }

  bool _matchesElement(InterfaceElement element, SymbolId id) {
    return element.name == id.name &&
        element.library.uri.toString() == id.libraryUri;
  }

  ConstructorElement? _unnamedRedirectingFactory(ClassElement element) {
    for (final constructor in element.constructors) {
      if (_isUnnamedConstructor(constructor) &&
          constructor.isFactory &&
          _hasRedirectSyntax(constructor)) {
        return constructor;
      }
    }
    return null;
  }

  bool _isV1ModelElement(ClassElement element) {
    return _findAnnotation(element, dataforgeAnnotation) != null &&
        _unnamedRedirectingFactory(element) != null;
  }

  static bool _isUnnamedConstructor(ConstructorElement constructor) {
    return constructor.name == 'new';
  }

  static bool _hasRedirectSyntax(ConstructorElement constructor) {
    return constructor.redirectedConstructor != null ||
        _constructorDeclaration(constructor)?.redirectedConstructor != null;
  }

  static (String?, String?) _redirectTarget(ConstructorElement constructor) {
    final redirected = constructor.redirectedConstructor;
    if (redirected != null) {
      return (redirected.enclosingElement.name, redirected.name);
    }
    final syntax = _constructorDeclaration(constructor)?.redirectedConstructor;
    if (syntax == null) return (null, null);

    // Before a generated target exists, Analyzer may temporarily resolve
    // `_Model.fromJson` as import prefix `_Model` plus type `fromJson`. Recover
    // the real redirect target from tokens so first generation and regeneration
    // have identical semantics.
    final apparentPrefix = syntax.type.importPrefix;
    if (syntax.name == null && apparentPrefix != null) {
      return (apparentPrefix.name.lexeme, syntax.type.name.lexeme);
    }
    return (
      syntax.type.name.lexeme,
      syntax.name == null ? 'new' : syntax.name!.name,
    );
  }

  static ConstructorDeclaration? _constructorDeclaration(
    ConstructorElement constructor,
  ) {
    final parsed = constructor.library.session.getParsedLibraryByElement(
      constructor.library,
    );
    if (parsed is! ParsedLibraryResult) return null;
    final declaration = parsed.getFragmentDeclaration(
      constructor.firstFragment,
    );
    final node = declaration?.node;
    return node is ConstructorDeclaration ? node : null;
  }

  static ClassDeclaration? _classDeclaration(ClassElement element) {
    final parsed = element.library.session.getParsedLibraryByElement(
      element.library,
    );
    if (parsed is! ParsedLibraryResult) return null;
    final declaration = parsed.getFragmentDeclaration(element.firstFragment);
    final node = declaration?.node;
    return node is ClassDeclaration ? node : null;
  }

  static ParameterKind _parameterKind(FormalParameterElement parameter) {
    if (parameter.isRequiredNamed) return ParameterKind.requiredNamed;
    if (parameter.isOptionalNamed) return ParameterKind.optionalNamed;
    if (parameter.isRequiredPositional) {
      return ParameterKind.requiredPositional;
    }
    return ParameterKind.optionalPositional;
  }

  static List<String> _readStringList(DartObject? value) {
    final values = value?.toListValue();
    if (values == null) return const [];
    return List<String>.unmodifiable(
      values.map((item) => item.toStringValue()).whereType<String>(),
    );
  }

  static GenerationDiagnostic _diagnostic({
    required GenerationDiagnosticCode code,
    required String message,
    required SchemaId schemaId,
    required String target,
    required Element element,
    Map<String, Object?> details = const {},
  }) {
    return GenerationDiagnostic(
      code: code,
      severity: GenerationDiagnosticSeverity.error,
      message: message,
      schemaId: schemaId,
      target: target,
      location: _location(element),
      details: details,
    );
  }

  static GenerationSourceLocation _location(Element element) {
    final fragment = element.firstFragment;
    final libraryFragment =
        fragment.libraryFragment ?? element.library!.firstFragment;
    final offset = fragment.offset;
    final characterLocation = libraryFragment.lineInfo.getLocation(offset);
    return GenerationSourceLocation(
      uri: libraryFragment.source.uri.toString(),
      offset: offset,
      length: element.name?.length ?? 0,
      line: characterLocation.lineNumber,
      column: characterLocation.columnNumber,
    );
  }
}

final class _SymbolRenderContext {
  final ClassElement modelElement;
  final Set<String> reservedQualifiers;
  final Map<SymbolId, String> _names = {};

  _SymbolRenderContext(
    this.modelElement, {
    Set<String> reservedQualifiers = const {},
  }) : reservedQualifiers = Set<String>.unmodifiable(reservedQualifiers);

  Map<SymbolId, String> get names => _names;

  String remember(InterfaceElement element) {
    final name = element.name ?? '';
    final symbol = SymbolId(
      libraryUri: element.library.uri.toString(),
      name: name,
    );
    return _names.putIfAbsent(
      symbol,
      () => _visibleReferenceFor(element, name) ?? name,
    );
  }

  /// Records the source-level type reference while retaining canonical schema
  /// identity.
  ///
  /// An import exposing only `typedef PublicMoney = Money` can therefore render
  /// `PublicMoney` instead of falling back to an inaccessible `Money`.
  bool rememberType(InterfaceType type) {
    final element = type.element;
    final name = element.name ?? '';
    final reference = _referenceForType(type);
    if (reference == null) return false;
    final symbol = SymbolId(
      libraryUri: element.library.uri.toString(),
      name: name,
    );
    final existing = _names[symbol];
    if (existing != null) return existing == reference;
    _names[symbol] = reference;
    return true;
  }

  String? rememberTypeReference(InterfaceType type) {
    final element = type.element;
    final symbol = SymbolId(
      libraryUri: element.library.uri.toString(),
      name: element.name ?? '',
    );
    final existing = _names[symbol];
    if (existing != null) return existing;
    if (!rememberType(type)) return null;
    return _names[symbol];
  }

  /// Records both a cross-library model type and its generated `$ModelType`
  /// companion.
  ///
  /// The companion is absent from the Analyzer namespace before first
  /// generation, so resolved model elements and import combinators determine
  /// whether the future name is reachable through the same reference. Returns
  /// `false` when `show` or `hide` explicitly masks the companion.
  bool rememberModel(InterfaceType type) {
    final element = type.element;
    final name = element.name ?? '';
    final companionName =
        '\$$name'
        'Type';
    final modelSymbol = SymbolId(
      libraryUri: element.library.uri.toString(),
      name: name,
    );
    final companionSymbol = SymbolId(
      libraryUri: element.library.uri.toString(),
      name: companionName,
    );
    if (element.library == modelElement.library) {
      _names[modelSymbol] = _referenceForType(type) ?? name;
      _names[companionSymbol] = companionName;
      return true;
    }

    final modelReference = _referenceForType(type);
    if (modelReference == null) return false;
    final candidates = <String>{};
    final pairedCandidates = <String>{};
    for (final fragment in modelElement.library.fragments) {
      for (final import in fragment.libraryImports) {
        final importedLibrary = import.importedLibrary;
        if (importedLibrary == null ||
            !_combinatorsAllow(import.combinators, companionName) ||
            !_exportsNameFrom(
              importedLibrary,
              element.library,
              companionName,
              <LibraryElement>{},
            )) {
          continue;
        }
        final prefix = import.prefix?.element.name;
        if (prefix != null && reservedQualifiers.contains(prefix)) continue;
        candidates.add(prefix ?? '');
        final visibleModel = prefix == null
            ? import.namespace.get2(name)
            : import.namespace.getPrefixed2(prefix, name);
        if (visibleModel == element) pairedCandidates.add(prefix ?? '');
      }
    }
    if (candidates.isEmpty) return false;
    final sorted =
        (pairedCandidates.isEmpty ? candidates : pairedCandidates).toList()
          ..sort((left, right) {
            if (left.isEmpty != right.isEmpty) return left.isEmpty ? -1 : 1;
            return left.compareTo(right);
          });
    final prefix = sorted.first;
    _names[modelSymbol] = pairedCandidates.isEmpty
        ? modelReference
        : (prefix.isEmpty ? name : '$prefix.$name');
    _names[companionSymbol] = prefix.isEmpty
        ? companionName
        : '$prefix.$companionName';
    return true;
  }

  /// Finds an import prefix that resolves every required v1 runtime symbol.
  ///
  /// Part files cannot add imports, so a declaration with `show` or `hide` is
  /// usable only when one namespace still exposes the complete runtime API. An
  /// empty string means an unprefixed import; `null` means no usable namespace.
  String? findPrefixFor(Map<String, SymbolId> symbols) {
    final candidates = <String>{};
    for (final fragment in modelElement.library.fragments) {
      for (final import in fragment.libraryImports) {
        final prefix = import.prefix?.element.name;
        if (prefix != null && reservedQualifiers.contains(prefix)) continue;
        final allVisible = symbols.entries.every((entry) {
          final visible = prefix == null
              ? import.namespace.get2(entry.key)
              : import.prefix!.element.scope.lookup(entry.key).getter;
          if (visible == null) return false;
          return visible.name == entry.value.name &&
              visible.library?.uri.toString() == entry.value.libraryUri;
        });
        if (allVisible) candidates.add(prefix ?? '');
      }
    }
    if (candidates.isEmpty) return null;
    final sorted = candidates.toList()
      ..sort((left, right) {
        if (left.isEmpty != right.isEmpty) return left.isEmpty ? -1 : 1;
        return left.compareTo(right);
      });
    return sorted.first;
  }

  String? _referenceForType(InterfaceType type) {
    final alias = type.alias;
    if (alias != null && _aliasPreservesTypeArguments(type, alias)) {
      final aliasElement = alias.element;
      final aliasName = aliasElement.name ?? '';
      final aliasReference = _visibleReferenceFor(aliasElement, aliasName);
      if (aliasReference != null) return aliasReference;
    }

    final element = type.element;
    return _visibleReferenceFor(element, element.name ?? '');
  }

  String? _visibleReferenceFor(Element element, String name) {
    final library = element.library;
    if (library == modelElement.library || library?.isDartCore == true) {
      return name;
    }

    final candidates = <String>{};
    for (final fragment in modelElement.library.fragments) {
      for (final import in fragment.libraryImports) {
        final prefix = import.prefix?.element.name;
        if (prefix != null && reservedQualifiers.contains(prefix)) continue;
        final visibleElement = prefix == null
            ? import.namespace.get2(name)
            : import.namespace.getPrefixed2(prefix, name);
        if (visibleElement != element) continue;
        candidates.add(prefix == null ? name : '$prefix.$name');
      }
    }
    if (candidates.isEmpty) return null;
    final sorted = candidates.toList()
      ..sort((left, right) {
        final leftPrefixed = left.contains('.') ? 1 : 0;
        final rightPrefixed = right.contains('.') ? 1 : 0;
        final prefixOrder = leftPrefixed.compareTo(rightPrefixed);
        return prefixOrder != 0 ? prefixOrder : left.compareTo(right);
      });
    return sorted.first;
  }

  static bool _aliasPreservesTypeArguments(
    InterfaceType type,
    InstantiatedTypeAliasElement alias,
  ) {
    if (type.typeArguments.length != alias.typeArguments.length) return false;
    for (final (index, argument) in type.typeArguments.indexed) {
      if (argument != alias.typeArguments[index]) return false;
    }
    return true;
  }

  static bool _exportsNameFrom(
    LibraryElement library,
    LibraryElement targetLibrary,
    String name,
    Set<LibraryElement> visited,
  ) {
    if (library == targetLibrary) return true;
    if (!visited.add(library)) return false;
    for (final fragment in library.fragments) {
      for (final export in fragment.libraryExports) {
        final exportedLibrary = export.exportedLibrary;
        if (exportedLibrary == null ||
            !_combinatorsAllow(export.combinators, name)) {
          continue;
        }
        if (_exportsNameFrom(exportedLibrary, targetLibrary, name, visited)) {
          return true;
        }
      }
    }
    return false;
  }

  static bool _combinatorsAllow(
    List<NamespaceCombinator> combinators,
    String name,
  ) {
    var visible = true;
    for (final combinator in combinators) {
      if (combinator is ShowElementCombinator) {
        visible = visible && combinator.shownNames.contains(name);
      } else if (combinator is HideElementCombinator &&
          combinator.hiddenNames.contains(name)) {
        visible = false;
      }
    }
    return visible;
  }
}

final class _GeneratedImplementationReferenceVisitor
    extends RecursiveAstVisitor<void> {
  _GeneratedImplementationReferenceVisitor({
    required this.modelName,
    required this.implementationName,
    required this.allowFromJson,
  });

  final String modelName;
  final String implementationName;
  final bool allowFromJson;
  final List<AstNode> references = [];

  @override
  void visitNamedType(NamedType node) {
    if (_referencesImplementation(node) && !_isAllowedRedirectTarget(node)) {
      references.add(node);
    }
    super.visitNamedType(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == implementationName && !node.inDeclarationContext()) {
      references.add(node);
    }
    super.visitSimpleIdentifier(node);
  }

  bool _referencesImplementation(NamedType node) {
    if (node.name.lexeme == implementationName) return true;
    final constructor = node.thisOrAncestorOfType<ConstructorDeclaration>();
    final redirectedConstructor = constructor?.redirectedConstructor;
    return identical(redirectedConstructor?.type, node) &&
        redirectedConstructor?.name == null &&
        node.importPrefix?.name.lexeme == implementationName;
  }

  bool _isAllowedRedirectTarget(NamedType node) {
    final constructor = node.thisOrAncestorOfType<ConstructorDeclaration>();
    final declaration = constructor?.thisOrAncestorOfType<ClassDeclaration>();
    final redirectedConstructor = constructor?.redirectedConstructor;
    if (declaration?.name.lexeme != modelName ||
        constructor?.factoryKeyword == null ||
        redirectedConstructor == null ||
        !identical(redirectedConstructor.type, node)) {
      return false;
    }

    final apparentPrefix = redirectedConstructor.type.importPrefix;
    final (
      redirectedType,
      redirectedName,
    ) = redirectedConstructor.name == null && apparentPrefix != null
        ? (apparentPrefix.name.lexeme, redirectedConstructor.type.name.lexeme)
        : (
            redirectedConstructor.type.name.lexeme,
            redirectedConstructor.name?.name ?? 'new',
          );
    if (redirectedType != implementationName) return false;

    final constructorName = constructor?.name?.lexeme;
    if (constructorName == null) return redirectedName == 'new';
    return allowFromJson &&
        constructorName == 'fromJson' &&
        redirectedName == 'fromJson';
  }
}

final class _UnsupportedDefaultValue implements Exception {
  const _UnsupportedDefaultValue();
}

final class _TypeParsingContext {
  final V1ModelSchemaBuilder builder;
  final SchemaId modelId;
  final List<GenerationDiagnostic> diagnostics;
  final _SymbolRenderContext renderContext;
  final Set<DartType> exactWitnessTypes;
  final Set<SchemaId> _resolvingModelWitnesses = <SchemaId>{};

  _TypeParsingContext({
    required this.builder,
    required this.modelId,
    required this.diagnostics,
    required this.renderContext,
    Set<DartType> exactWitnessTypes = const {},
  }) : exactWitnessTypes = Set<DartType>.unmodifiable(exactWitnessTypes);

  TypeShape? parse(
    DartType type, {
    required String target,
    required Element element,
    bool allowUnsafeTopType = false,
    bool exactSemanticBoundary = false,
    bool collectTypeParameterUse = true,
  }) {
    exactSemanticBoundary =
        exactSemanticBoundary || exactWitnessTypes.contains(type);
    allowUnsafeTopType = allowUnsafeTopType || exactSemanticBoundary;
    if (type.nullabilitySuffix == NullabilitySuffix.star) {
      return _unsupported(
        type,
        target,
        element,
        'Star nullability is not supported.',
      );
    }
    final shape = _parseNonNullable(
      type,
      target: target,
      element: element,
      allowUnsafeTopType: allowUnsafeTopType,
      exactSemanticBoundary: exactSemanticBoundary,
      collectTypeParameterUse: collectTypeParameterUse,
    );
    if (shape == null) return null;
    return type.nullabilitySuffix == NullabilitySuffix.question
        ? NullableShape(shape)
        : shape;
  }

  TypeShape? _parseNonNullable(
    DartType type, {
    required String target,
    required Element element,
    required bool allowUnsafeTopType,
    required bool exactSemanticBoundary,
    required bool collectTypeParameterUse,
  }) {
    if (type is DynamicType) {
      if (allowUnsafeTopType) {
        return const ScalarShape(ScalarKind.dynamicType);
      }
      return _unsupported(type, target, element, 'dynamic 无法证明冻结和值语义');
    }
    if (type is VoidType) {
      return _unsupported(type, target, element, 'void 不能作为模型值字段');
    }
    if (type is FunctionType || type.isDartCoreFunction) {
      return _unsupported(type, target, element, 'Function 不具备稳定冻结和 JSON 语义');
    }
    if (type is InvalidType) {
      return _unsupported(type, target, element, '类型未能被 analyzer resolve');
    }
    if (type is NeverType) {
      return const ScalarShape(ScalarKind.never);
    }
    if (type is TypeParameterType) {
      final parameter = type.element;
      return TypeParameterShape(parameter.name ?? '');
    }
    if (type is RecordType) {
      final positional = <TypeShape>[];
      final named = <String, TypeShape>{};
      var valid = true;
      for (final (index, field) in type.positionalFields.indexed) {
        final fieldShape = parse(
          field.type,
          target: '$target.positional[$index]',
          element: element,
          allowUnsafeTopType: allowUnsafeTopType,
          exactSemanticBoundary: exactSemanticBoundary,
          collectTypeParameterUse: collectTypeParameterUse,
        );
        if (fieldShape == null) {
          valid = false;
        } else {
          positional.add(fieldShape);
        }
      }
      final namedFields = [...type.namedFields]
        ..sort((left, right) => left.name.compareTo(right.name));
      for (final field in namedFields) {
        final fieldShape = parse(
          field.type,
          target: '$target.named.${field.name}',
          element: element,
          allowUnsafeTopType: allowUnsafeTopType,
          exactSemanticBoundary: exactSemanticBoundary,
          collectTypeParameterUse: collectTypeParameterUse,
        );
        if (fieldShape == null) {
          valid = false;
        } else {
          named[field.name] = fieldShape;
        }
      }
      return valid ? RecordShape(positional: positional, named: named) : null;
    }
    if (type is! InterfaceType) {
      return _unsupported(type, target, element, '不支持的 analyzer DartType');
    }

    if (type.isDartCoreObject) {
      if (allowUnsafeTopType) {
        return const ScalarShape(ScalarKind.object);
      }
      return _unsupported(type, target, element, 'Object 无法证明具体冻结和值语义');
    }
    if (type.isDartCoreNull) {
      return _unsupported(type, target, element, 'Null 不能单独作为模型字段类型');
    }
    if (type.isDartCoreString) {
      return const ScalarShape(ScalarKind.string);
    }
    if (type.isDartCoreBool) {
      return const ScalarShape(ScalarKind.boolean);
    }
    if (type.isDartCoreInt) {
      return const ScalarShape(ScalarKind.integer);
    }
    if (type.isDartCoreDouble) {
      return const ScalarShape(ScalarKind.doublePrecision);
    }
    if (type.isDartCoreNum) {
      return const ScalarShape(ScalarKind.number);
    }

    final interfaceElement = type.element;
    final symbol = SymbolId(
      libraryUri: interfaceElement.library.uri.toString(),
      name: interfaceElement.name ?? '',
    );
    if (interfaceElement.library.isDartCore && symbol.name == 'DateTime') {
      return const DateTimeShape();
    }
    if (interfaceElement.library.isDartCore && symbol.name == 'Duration') {
      return const DurationShape();
    }

    if (type.isDartCoreList || type.isDartCoreSet) {
      final elementShape = _parseTypeArgument(
        type,
        0,
        target: '$target.element',
        element: element,
        allowUnsafeTopType: allowUnsafeTopType,
        exactSemanticBoundary: exactSemanticBoundary,
        collectTypeParameterUse: collectTypeParameterUse,
      );
      if (elementShape == null) return null;
      return type.isDartCoreList
          ? ListShape(elementShape)
          : SetShape(elementShape);
    }
    if (type.isDartCoreMap) {
      final key = _parseTypeArgument(
        type,
        0,
        target: '$target.key',
        element: element,
        allowUnsafeTopType: allowUnsafeTopType,
        exactSemanticBoundary: exactSemanticBoundary,
        collectTypeParameterUse: collectTypeParameterUse,
      );
      final value = _parseTypeArgument(
        type,
        1,
        target: '$target.value',
        element: element,
        allowUnsafeTopType: allowUnsafeTopType,
        exactSemanticBoundary: exactSemanticBoundary,
        collectTypeParameterUse: collectTypeParameterUse,
      );
      return key == null || value == null
          ? null
          : MapShape(key: key, value: value);
    }
    if (type.isDartAsyncFuture ||
        type.isDartAsyncFutureOr ||
        type.isDartAsyncStream) {
      return _unsupported(
        type,
        target,
        element,
        'Future、FutureOr 与 Stream 不支持稳定冻结和值语义',
      );
    }

    final ClassElement? modelElement =
        interfaceElement is ClassElement &&
            builder._isV1ModelElement(interfaceElement)
        ? interfaceElement
        : null;
    final typeArguments = <TypeShape>[];
    var argumentsValid = true;
    for (final (index, argument) in type.typeArguments.indexed) {
      final argumentShape = parse(
        argument,
        target: '$target.typeArguments[$index]',
        element: element,
        // Model typeArguments describe instantiated Dart identity only. Actual
        // freeze/JSON/equality dependencies come from the instantiated
        // witnessArguments parsed below. Allow unsafe type arguments here and
        // keep nested models shallow until the target signature is known.
        allowUnsafeTopType: allowUnsafeTopType || modelElement != null,
        exactSemanticBoundary: exactSemanticBoundary || modelElement != null,
        collectTypeParameterUse: collectTypeParameterUse,
      );
      if (argumentShape == null) {
        argumentsValid = false;
      } else {
        typeArguments.add(argumentShape);
      }
    }
    if (!argumentsValid) return null;

    if (interfaceElement is EnumElement) {
      if (!renderContext.rememberType(type)) {
        return _unsupported(
          type,
          target,
          element,
          'enum 的 resolved import/typedef 引用在当前 library 中不可见',
        );
      }
      return EnumShape(symbol);
    }
    if (modelElement != null) {
      final modelAnnotation = builder._findAnnotation(
        modelElement,
        builder.dataforgeAnnotation,
      )!;
      if (exactSemanticBoundary) {
        if (!renderContext.rememberType(type)) {
          return _unsupported(
            type,
            target,
            element,
            'exact witness 覆盖的模型类型在当前 library 中不可见',
          );
        }
        return ModelShape(
          SchemaId(libraryUri: symbol.libraryUri, name: symbol.name),
          typeArguments: typeArguments,
          includeFromJson: builder._includeFromJson(modelAnnotation),
          includeToJson: builder._includeToJson(modelAnnotation),
        );
      }
      if (!renderContext.rememberModel(type)) {
        return _unsupported(
          type,
          target,
          element,
          'import show/hide 隐藏了生成 companion \$${symbol.name}Type',
        );
      }
      final witnessArguments = _parseModelWitnessArguments(
        modelElement,
        type,
        target: target,
        element: element,
        collectTypeParameterUse: collectTypeParameterUse,
      );
      if (witnessArguments == null) return null;
      return ModelShape(
        SchemaId(libraryUri: symbol.libraryUri, name: symbol.name),
        typeArguments: typeArguments,
        witnessArguments: witnessArguments,
        includeFromJson: builder._includeFromJson(modelAnnotation),
        includeToJson: builder._includeToJson(modelAnnotation),
      );
    }
    if (!renderContext.rememberType(type)) {
      return _unsupported(
        type,
        target,
        element,
        'resolved import/typedef 引用在当前 library 中不可见',
      );
    }
    return CustomShape(symbol, typeArguments: typeArguments);
  }

  List<TypeShape>? _parseModelWitnessArguments(
    ClassElement targetModel,
    InterfaceType targetType, {
    required String target,
    required Element element,
    required bool collectTypeParameterUse,
  }) {
    final targetId = SchemaId(
      libraryUri: targetModel.library.uri.toString(),
      name: targetModel.name ?? '',
    );
    if (!_resolvingModelWitnesses.add(targetId)) {
      diagnostics.add(
        V1ModelSchemaBuilder._diagnostic(
          code: GenerationDiagnosticCode.genericTypeWitnessRequired,
          message: '模型 ${targetId.name} 的 DataforgeType witness 签名形成循环依赖。',
          schemaId: modelId,
          target: '$target.witnessArguments.cycle',
          element: element,
          details: {
            'model': targetId.toMap(),
            'resolvingModels': _resolvingModelWitnesses
                .map((model) => model.toMap())
                .toList(),
          },
        ),
      );
      return null;
    }

    try {
      // InterfaceType.constructors has substituted the target model's type
      // parameters with this instantiation. Parse that signature directly so
      // outer exactWitnessTypes can match types such as Inner<int>.
      final factory = targetType.constructors
          .where(
            (constructor) =>
                V1ModelSchemaBuilder._isUnnamedConstructor(constructor) &&
                constructor.isFactory,
          )
          .firstOrNull;
      if (factory == null) return const <TypeShape>[];

      final result = <TypeShape>[];
      var valid = true;
      for (final parameter in factory.formalParameters) {
        if (!builder._isDataforgeType(parameter.type)) continue;
        final witnessType = parameter.type as InterfaceType;
        if (witnessType.typeArguments.length != 1) {
          valid = false;
          diagnostics.add(
            V1ModelSchemaBuilder._diagnostic(
              code: GenerationDiagnosticCode.genericTypeWitnessRequired,
              message:
                  '模型 ${targetId.name} 的 DataforgeType witness 必须有且仅有一个类型参数。',
              schemaId: modelId,
              target: '$target.witnessArguments[${result.length}]',
              element: element,
              details: {
                'model': targetId.toMap(),
                'parameter': parameter.name,
                'actualType': parameter.type.getDisplayString(),
              },
            ),
          );
          continue;
        }

        final declaredShape = parse(
          witnessType.typeArguments.single,
          target: '$target.witnessArguments[${result.length}]',
          element: element,
          // A target signature may declare unsafe types, but it cannot assume
          // an outer whole-exact witness. Only an actual exactWitnessTypes match
          // cuts off this subtree.
          allowUnsafeTopType: true,
          collectTypeParameterUse: collectTypeParameterUse,
        );
        if (declaredShape == null) {
          valid = false;
          continue;
        }
        result.add(declaredShape);
      }
      return valid ? result : null;
    } finally {
      _resolvingModelWitnesses.remove(targetId);
    }
  }

  TypeShape? _parseTypeArgument(
    InterfaceType type,
    int index, {
    required String target,
    required Element element,
    required bool allowUnsafeTopType,
    required bool exactSemanticBoundary,
    required bool collectTypeParameterUse,
  }) {
    if (index >= type.typeArguments.length) {
      return _unsupported(type, target, element, '集合类型参数数量不完整');
    }
    return parse(
      type.typeArguments[index],
      target: target,
      element: element,
      allowUnsafeTopType: allowUnsafeTopType,
      exactSemanticBoundary: exactSemanticBoundary,
      collectTypeParameterUse: collectTypeParameterUse,
    );
  }

  TypeShape? _unsupported(
    DartType type,
    String target,
    Element element,
    String reason,
  ) {
    diagnostics.add(
      V1ModelSchemaBuilder._diagnostic(
        code: GenerationDiagnosticCode.unsupportedType,
        message: '不支持类型 ${type.getDisplayString()}：$reason。',
        schemaId: modelId,
        target: target,
        element: element,
        details: {'actualType': type.getDisplayString(), 'reason': reason},
      ),
    );
    return null;
  }
}
