import 'dart:io';

import 'package:dataforge_base/src/v1/diagnostics.dart';
import 'package:dataforge_base/src/v1/schema.dart';
import 'package:dataforge_base/src/v1/writer.dart';
import 'package:test/test.dart';

const _modelsUri = 'package:writer_fixture/models.dart';
const _runtimeUri = 'package:dataforge_annotation/dataforge_annotation.dart';

void main() {
  group('ModelSchemaWriter golden', () {
    test('递归 TypeShape 只编译为组合式 witness，并贯穿所有行为', () {
      final source = _writer().write(_userSchema());
      final golden = File(
        'test/v1/goldens/user_writer.golden.txt',
      ).readAsStringSync();
      const recursiveWitness =
          'df.DataforgeTypes.list(df.DataforgeTypes.list(df.DataforgeTypes.intType))';

      expect(source, contains('mixin _\$User'));
      expect(source, golden);
      expect(source, contains('final class _User extends User'));
      expect(source, contains('final List<List<int>> xs;'));
      expect(source, contains('$recursiveWitness.freeze(xs)'));
      expect(
        source,
        contains(
          'df.dataforgeValueEquals('
          '$recursiveWitness, $recursiveWitness, this.xs, other.xs)',
        ),
      );
      expect(source, contains('$recursiveWitness.hash(this.xs)'));
      expect(source, contains('df.dataforgeDecode($recursiveWitness,'));
      expect(source, contains('df.dataforgeEncode($recursiveWitness,'));
      expect(source, contains('const df.DataforgeType<User> \$UserType ='));
      expect(source, contains('_modelContext.snapshot(<String, Object?>{'));
      expect(source, isNot(contains('dynamic xs')));
    });

    test('runtimePrefix 支持带点或不带点，symbol resolver 处理 enum/model', () {
      final schema = ModelSchema(
        id: const SchemaId(libraryUri: _modelsUri, name: 'Event'),
        implementationName: '_Event',
        constructor: ConstructorSchema(
          kind: ConstructorKind.redirectingFactory,
          parameters: [
            const ConstructorParameterSchema(
              name: 'states',
              shape: MapShape(
                key: ScalarShape(ScalarKind.string),
                value: NullableShape(
                  EnumShape(
                    SymbolId(
                      libraryUri: 'package:types/types.dart',
                      name: 'State',
                    ),
                  ),
                ),
              ),
              kind: ParameterKind.requiredNamed,
              fieldName: 'states',
            ),
            ConstructorParameterSchema(
              name: 'owner',
              shape: ModelShape(
                const SchemaId(
                  libraryUri: 'package:domain/user.dart',
                  name: 'User',
                ),
              ),
              kind: ParameterKind.requiredNamed,
              fieldName: 'owner',
            ),
            const ConstructorParameterSchema(
              name: 'dates',
              shape: SetShape(DateTimeShape()),
              kind: ParameterKind.requiredNamed,
              fieldName: 'dates',
            ),
          ],
        ),
        fields: [
          FieldSchema(
            name: 'states',
            shape: const MapShape(
              key: ScalarShape(ScalarKind.string),
              value: NullableShape(
                EnumShape(
                  SymbolId(
                    libraryUri: 'package:types/types.dart',
                    name: 'State',
                  ),
                ),
              ),
            ),
            isRequired: true,
          ),
          FieldSchema(
            name: 'owner',
            shape: ModelShape(
              const SchemaId(
                libraryUri: 'package:domain/user.dart',
                name: 'User',
              ),
            ),
            isRequired: true,
          ),
          FieldSchema(
            name: 'dates',
            shape: const SetShape(DateTimeShape()),
            isRequired: true,
          ),
        ],
      );
      String resolve(SymbolId symbol) => switch (symbol.libraryUri) {
        'package:types/types.dart' => 'types.${symbol.name}',
        'package:domain/user.dart' => 'domain.${symbol.name}',
        _ => symbol.name,
      };

      final withoutDot = ModelSchemaWriter(
        symbolNameResolver: resolve,
        runtimePrefix: 'df',
      ).write(schema);
      final withDot = ModelSchemaWriter(
        symbolNameResolver: resolve,
        runtimePrefix: 'df.',
      ).write(schema);

      expect(withDot, withoutDot);
      expect(
        withDot,
        contains('df.DataforgeTypes.enumeration(types.State.values)'),
      );
      expect(withDot, contains(r'domain.$UserType'));
      expect(withDot, contains('domain.User'));
      expect(
        withDot,
        contains('df.DataforgeTypes.set(df.DataforgeTypes.dateTime)'),
      );
    });

    test('泛型沿用 schema semantic witness，copyWith 不暴露 witness', () {
      final source = _writer().write(_boxSchema());

      expect(source, contains('required df.DataforgeType<T> type'));
      expect(source, contains('final df.DataforgeType<T> _type;'));
      expect(source, contains('df.dataforgeTypeEquals(_type, other._type)'));
      expect(source, contains('df.dataforgeTypeHash(_type)'));
      expect(source, contains('df.DataforgeType<Box<T>> \$BoxType<T>('));
      expect(source, contains('implements df.DataforgeType<Box<T>>, '));
      expect(source, contains('df.DataforgeTypeIdentity'));
      expect(
        source,
        contains(
          'get dataforgeTypeArguments => '
          'List<df.DataforgeType<dynamic>>.unmodifiable(',
        ),
      );
      expect(
        source,
        contains(
          'dataforgeTypeId => '
          '"package:writer_fixture/models.dart#Box"',
        ),
      );
      final copyWithStart = source.indexOf('Box<T> copyWith({');
      final copyWithEnd = source.indexOf('  });', copyWithStart);
      expect(copyWithStart, greaterThanOrEqualTo(0));
      expect(
        source.substring(copyWithStart, copyWithEnd),
        isNot(contains('type')),
      );
    });

    test('mixin 名从 implementationName 推导', () {
      final source = _writer().write(
        _userSchemaWithImplementation('_StoredUser'),
      );

      expect(source, contains(r'mixin _$StoredUser'));
      expect(source, contains('final class _StoredUser extends User'));
      expect(source, isNot(contains(r'mixin _$User')));
    });

    test('DurationShape 映射 runtime duration witness', () {
      final source = _writer().write(_timerSchema());

      expect(source, contains('final Duration elapsed;'));
      expect(source, contains('df.DataforgeTypes.duration.freeze(elapsed)'));
      expect(
        source,
        contains('df.dataforgeDecode(df.DataforgeTypes.duration,'),
      );
      expect(
        source,
        contains('df.dataforgeEncode(df.DataforgeTypes.duration,'),
      );
    });

    test('ModelShape 按 witnessArguments 递归实例化目标 \$ModelType', () {
      final money = CustomShape(
        const SymbolId(libraryUri: 'package:domain/money.dart', name: 'Money'),
      );
      final box = ModelShape(
        const SchemaId(libraryUri: 'package:domain/box.dart', name: 'Box'),
        typeArguments: [money],
        witnessArguments: [ListShape(money)],
      );
      final schema = ModelSchema(
        id: const SchemaId(libraryUri: _modelsUri, name: 'Holder'),
        implementationName: '_Holder',
        constructor: ConstructorSchema(
          kind: ConstructorKind.redirectingFactory,
          parameters: [
            ConstructorParameterSchema(
              name: 'moneyType',
              shape: _dataforgeTypeShape(money),
              kind: ParameterKind.requiredNamed,
            ),
            ConstructorParameterSchema(
              name: 'box',
              shape: box,
              kind: ParameterKind.requiredNamed,
              fieldName: 'box',
            ),
          ],
        ),
        fields: [FieldSchema(name: 'box', shape: box, isRequired: true)],
      );
      String resolve(SymbolId symbol) => switch (symbol.libraryUri) {
        'package:domain/money.dart' => 'domain.${symbol.name}',
        'package:domain/box.dart' => 'domain.${symbol.name}',
        _ => symbol.name,
      };

      final source = ModelSchemaWriter(
        symbolNameResolver: resolve,
        runtimePrefix: 'df',
      ).write(schema);

      expect(
        source,
        contains(
          r'domain.$BoxType<domain.Money>('
          'df.DataforgeTypes.list(moneyType))',
        ),
      );
      expect(
        source,
        contains(
          r'domain.$BoxType<domain.Money>('
          'df.DataforgeTypes.list(_moneyType))',
        ),
      );
    });

    test('RecordShape 生成完整布局与子 witness 的私有值语义 helper', () {
      final source = _writer().write(_recordBoxSchema());

      expect(
        source,
        contains(
          r'final class _$RecordBoxRecordDataforgeType0<T> '
          'implements df.DataforgeType<(List<List<int>>, {T payload})>, '
          'df.DataforgeTypeIdentity',
        ),
      );
      expect(
        source,
        contains(
          r'dataforgeTypeId => '
          '"dataforge:record('
          'positional:1;named:payload)"',
        ),
      );
      expect(
        source,
        contains(
          'df.DataforgeTypes.list(df.DataforgeTypes.list('
          'df.DataforgeTypes.intType))',
        ),
      );
      expect(source, contains('_payloadType'));
      expect(source, contains(r'value.$1'));
      expect(source, contains('value.payload'));
      expect(
        source,
        contains(
          'get dataforgeTypeArguments => '
          'List<df.DataforgeType<dynamic>>.unmodifiable(',
        ),
      );
    });
  });

  group('ModelSchemaWriter diagnostics', () {
    test('所有生成 top-level 符号在 raw writer 内也必须互异', () {
      final schema = _userSchemaWithImplementation(r'_$UserDataforgeType');

      expect(
        () => _writer().write(schema),
        throwsA(
          _diagnostic(
            GenerationDiagnosticCode.invalidModel,
            r'generatedSymbols._$UserDataforgeType',
          ),
        ),
      );
    });

    test('mutable field 返回 DF1002', () {
      final schema = _singleFieldSchema(
        const ScalarShape(ScalarKind.string),
        isFinal: false,
      );
      expect(
        () => _writer().write(schema),
        throwsA(_diagnostic(GenerationDiagnosticCode.mutableField, 'value')),
      );
    });

    test('未声明的 TypeParameterShape 返回 DF1005', () {
      const valueShape = TypeParameterShape('T');
      final witnessShape = CustomShape(
        const SymbolId(libraryUri: _runtimeUri, name: 'DataforgeType'),
        typeArguments: const [valueShape],
      );
      final schema = ModelSchema(
        id: const SchemaId(libraryUri: _modelsUri, name: 'UnknownGeneric'),
        implementationName: '_UnknownGeneric',
        constructor: ConstructorSchema(
          kind: ConstructorKind.redirectingFactory,
          parameters: [
            ConstructorParameterSchema(
              name: 'type',
              shape: witnessShape,
              kind: ParameterKind.requiredNamed,
            ),
            const ConstructorParameterSchema(
              name: 'value',
              shape: valueShape,
              kind: ParameterKind.requiredNamed,
              fieldName: 'value',
            ),
          ],
        ),
        fields: [
          FieldSchema(name: 'value', shape: valueShape, isRequired: true),
        ],
      );

      expect(
        () => _writer().write(schema),
        throwsA(
          _diagnostic(
            GenerationDiagnosticCode.genericTypeWitnessRequired,
            'value',
          ),
        ),
      );
    });

    test('非法或空 RecordShape 返回 DF1001', () {
      ModelSchema withoutJson(TypeShape shape) {
        final base = _singleFieldSchema(shape);
        return ModelSchema(
          id: base.id,
          implementationName: base.implementationName,
          constructor: base.constructor,
          fields: base.fields,
          includeFromJson: false,
          includeToJson: false,
        );
      }

      expect(
        () => _writer().write(
          withoutJson(
            RecordShape(
              named: const {'bad-name': ScalarShape(ScalarKind.string)},
            ),
          ),
        ),
        throwsA(_diagnostic(GenerationDiagnosticCode.invalidModel, 'value')),
      );
      expect(
        () => _writer().write(withoutJson(RecordShape())),
        throwsA(_diagnostic(GenerationDiagnosticCode.invalidModel, 'value')),
      );
    });

    test('RecordShape 参与 JSON 时返回 DF1006', () {
      final schema = _singleFieldSchema(
        RecordShape(positional: const [ScalarShape(ScalarKind.string)]),
      );
      expect(
        () => _writer().write(schema),
        throwsA(
          _diagnostic(
            GenerationDiagnosticCode.invalidJsonConfiguration,
            'value',
          ),
        ),
      );

      final jsonDisabled = _recordBoxSchema();
      final toJsonOnly = ModelSchema(
        id: jsonDisabled.id,
        implementationName: jsonDisabled.implementationName,
        typeParameters: jsonDisabled.typeParameters,
        constructor: jsonDisabled.constructor,
        fields: jsonDisabled.fields,
        includeFromJson: false,
        includeToJson: true,
      );
      expect(
        () => _writer().write(toJsonOnly),
        throwsA(
          _diagnostic(
            GenerationDiagnosticCode.invalidJsonConfiguration,
            'value',
          ),
        ),
      );
    });

    test('ModelShape 的 Record 检查只沿语义 witness 树并尊重 exact 边界', () {
      final record = RecordShape(
        positional: const [ScalarShape(ScalarKind.integer)],
      );
      final values = ListShape(record);
      final box = ModelShape(
        const SchemaId(libraryUri: 'package:domain/box.dart', name: 'Box'),
        typeArguments: [record],
        witnessArguments: [values],
      );

      expect(
        () => _writer().write(_singleFieldSchema(box)),
        throwsA(
          _diagnostic(
            GenerationDiagnosticCode.invalidJsonConfiguration,
            'value',
          ),
        ),
      );

      final covered = _singleFieldSchema(
        box,
        semanticWitness: ConstructorParameterSchema(
          name: 'valuesType',
          shape: CustomShape(
            const SymbolId(libraryUri: _runtimeUri, name: 'DataforgeType'),
            typeArguments: [values],
          ),
          kind: ParameterKind.requiredNamed,
        ),
      );
      expect(() => _writer().write(covered), returnsNormally);
    });

    test('RecordShape 的字段双向忽略 JSON 时仍生成值语义', () {
      final shape = RecordShape(
        positional: const [ScalarShape(ScalarKind.string)],
      );
      final schema = ModelSchema(
        id: const SchemaId(libraryUri: _modelsUri, name: 'IgnoredRecord'),
        implementationName: '_IgnoredRecord',
        constructor: ConstructorSchema(
          kind: ConstructorKind.redirectingFactory,
          parameters: [
            ConstructorParameterSchema(
              name: 'value',
              shape: shape,
              kind: ParameterKind.optionalNamed,
              defaultValueCode: "('fallback',)",
              fieldName: 'value',
            ),
          ],
        ),
        fields: [
          FieldSchema(
            name: 'value',
            shape: shape,
            defaultValueCode: "('fallback',)",
            includeFromJson: false,
            includeToJson: false,
          ),
        ],
      );

      final source = _writer().write(schema);
      expect(source, contains(r'_$IgnoredRecordRecordDataforgeType0'));
      expect(source, contains('df.dataforgeFreeze('));
      expect(source, contains("('fallback',)"));
    });

    test('模型整体关闭 fromJson 时，字段无需 decode fallback', () {
      final base = _singleFieldSchema(const ScalarShape(ScalarKind.string));
      final valueOnlyInput = ModelSchema(
        id: base.id,
        implementationName: base.implementationName,
        constructor: base.constructor,
        fields: [
          FieldSchema(
            name: 'value',
            shape: const ScalarShape(ScalarKind.string),
            isRequired: true,
            includeFromJson: false,
          ),
        ],
        includeFromJson: false,
      );

      expect(() => _writer().write(valueOnlyInput), returnsNormally);
    });

    test('JSON 方向在生成期拒绝不可编码为 String 的 Map key', () {
      const shape = MapShape(
        key: ListShape(ScalarShape(ScalarKind.integer)),
        value: ScalarShape(ScalarKind.string),
      );
      final schema = _singleFieldSchema(shape);

      expect(
        () => _writer().write(schema),
        throwsA(
          _diagnostic(
            GenerationDiagnosticCode.invalidJsonConfiguration,
            'value',
          ),
        ),
      );

      final valueOnly = ModelSchema(
        id: schema.id,
        implementationName: schema.implementationName,
        constructor: schema.constructor,
        fields: schema.fields,
        includeFromJson: false,
        includeToJson: false,
      );
      expect(() => _writer().write(valueOnly), returnsNormally);
    });

    test('exact composite witness 是完整语义边界', () {
      const mapShape = MapShape(
        key: ListShape(ScalarShape(ScalarKind.integer)),
        value: ScalarShape(ScalarKind.string),
      );
      final mapSchema = _singleFieldSchema(
        mapShape,
        semanticWitness: ConstructorParameterSchema(
          name: 'mapType',
          shape: _dataforgeTypeShape(mapShape),
          kind: ParameterKind.requiredNamed,
        ),
      );

      final mapSource = _writer().write(mapSchema);
      expect(mapSource, contains('mapType.freeze(value)'));
      expect(
        mapSource,
        contains('final df.DataforgeType<Map<List<int>, String>> _mapType;'),
      );

      final opaqueModel = ModelShape(
        const SchemaId(libraryUri: 'package:domain/inner.dart', name: 'Inner'),
        includeFromJson: false,
        includeToJson: false,
      );
      final modelSchema = _singleFieldSchema(
        opaqueModel,
        semanticWitness: ConstructorParameterSchema(
          name: 'innerType',
          shape: _dataforgeTypeShape(opaqueModel),
          kind: ParameterKind.requiredNamed,
        ),
      );

      final modelSource = _writer().write(modelSchema);
      expect(modelSource, contains('innerType.freeze(value)'));
      expect(modelSource, isNot(contains(r'domain.$InnerType')));
    });

    test('JSON 方向在生成期拒绝关闭该 capability 的嵌套模型', () {
      final inner = ModelShape(
        const SchemaId(libraryUri: 'package:domain/inner.dart', name: 'Inner'),
        includeFromJson: false,
        includeToJson: false,
      );
      final schema = _singleFieldSchema(inner);

      expect(
        () => _writer().write(schema),
        throwsA(
          _diagnostic(
            GenerationDiagnosticCode.invalidJsonConfiguration,
            'value',
          ),
        ),
      );

      final valueOnly = ModelSchema(
        id: schema.id,
        implementationName: schema.implementationName,
        constructor: schema.constructor,
        fields: schema.fields,
        includeFromJson: false,
        includeToJson: false,
      );
      expect(() => _writer().write(valueOnly), returnsNormally);
    });

    test('custom leaf 有 exact witness 时支持，缺失时 DF1004', () {
      final money = CustomShape(
        const SymbolId(libraryUri: 'package:money/money.dart', name: 'Money'),
      );
      final withoutWitness = _singleFieldSchema(money);
      expect(
        () => _writer().write(withoutWitness),
        throwsA(_diagnostic(GenerationDiagnosticCode.unsupportedType, 'value')),
      );

      final withWitness = _singleFieldSchema(
        money,
        semanticWitness: ConstructorParameterSchema(
          name: 'moneyType',
          shape: _dataforgeTypeShape(money),
          kind: ParameterKind.requiredNamed,
        ),
      );
      final source = _writer().write(withWitness);
      expect(source, contains('moneyType.freeze(value)'));
      expect(source, contains('final df.DataforgeType<Money> _moneyType;'));
    });

    test('泛型缺少 witness 返回 DF1005', () {
      final schema = ModelSchema(
        id: const SchemaId(libraryUri: _modelsUri, name: 'Box'),
        implementationName: '_Box',
        typeParameters: const [TypeParameterSchema(name: 'T')],
        constructor: ConstructorSchema(
          kind: ConstructorKind.redirectingFactory,
          parameters: const [
            ConstructorParameterSchema(
              name: 'value',
              shape: TypeParameterShape('T'),
              kind: ParameterKind.requiredNamed,
              fieldName: 'value',
            ),
          ],
        ),
        fields: [
          FieldSchema(
            name: 'value',
            shape: const TypeParameterShape('T'),
            isRequired: true,
          ),
        ],
      );
      expect(
        () => _writer().write(schema),
        throwsA(
          _diagnostic(
            GenerationDiagnosticCode.genericTypeWitnessRequired,
            'value',
          ),
        ),
      );
    });

    test('非法 runtime prefix 立即拒绝', () {
      expect(
        () => const ModelSchemaWriter(
          symbolNameResolver: _resolve,
          runtimePrefix: 'bad-prefix',
        ).write(_userSchema()),
        throwsArgumentError,
      );
      expect(
        () => const ModelSchemaWriter(
          symbolNameResolver: _resolve,
          runtimePrefix: 'class',
        ).write(_userSchema()),
        throwsArgumentError,
      );
    });

    test('字段、witness 与固定局部不得遮蔽生成表达式 qualifier', () {
      expect(
        () => _writer().write(
          _singleFieldSchema(
            const ScalarShape(ScalarKind.string),
            fieldName: 'df',
          ),
        ),
        throwsA(_diagnostic(GenerationDiagnosticCode.invalidModel, 'df')),
      );
      expect(
        () => _writer().write(
          _singleFieldSchema(
            const ScalarShape(ScalarKind.string),
            fieldName: 'String',
          ),
        ),
        throwsA(_diagnostic(GenerationDiagnosticCode.invalidModel, 'String')),
      );

      final typeParameterShadow = ModelSchema(
        id: const SchemaId(libraryUri: _modelsUri, name: 'ShadowBox'),
        implementationName: '_ShadowBox',
        typeParameters: const [TypeParameterSchema(name: 'T')],
        constructor: ConstructorSchema(
          kind: ConstructorKind.redirectingFactory,
          parameters: [
            ConstructorParameterSchema(
              name: 'type',
              shape: _dataforgeTypeShape(const TypeParameterShape('T')),
              kind: ParameterKind.requiredNamed,
            ),
            const ConstructorParameterSchema(
              name: 'T',
              shape: TypeParameterShape('T'),
              kind: ParameterKind.requiredNamed,
              fieldName: 'T',
            ),
          ],
        ),
        fields: [
          FieldSchema(
            name: 'T',
            shape: const TypeParameterShape('T'),
            isRequired: true,
          ),
        ],
      );
      expect(
        () => _writer().write(typeParameterShadow),
        throwsA(_diagnostic(GenerationDiagnosticCode.invalidModel, 'T')),
      );

      final money = CustomShape(
        const SymbolId(libraryUri: 'package:money/money.dart', name: 'Money'),
      );
      expect(
        () => _writer().write(
          _singleFieldSchema(
            money,
            semanticWitness: ConstructorParameterSchema(
              name: 'df',
              shape: _dataforgeTypeShape(money),
              kind: ParameterKind.requiredNamed,
            ),
          ),
        ),
        throwsA(_diagnostic(GenerationDiagnosticCode.invalidModel, 'df')),
      );

      expect(
        () => const ModelSchemaWriter(symbolNameResolver: _resolve).write(
          _singleFieldSchema(
            const ScalarShape(ScalarKind.string),
            fieldName: 'DataforgeTypes',
          ),
        ),
        throwsA(
          _diagnostic(GenerationDiagnosticCode.invalidModel, 'DataforgeTypes'),
        ),
      );

      const state = EnumShape(
        SymbolId(libraryUri: 'package:types/types.dart', name: 'State'),
      );
      expect(
        () => const ModelSchemaWriter(
          symbolNameResolver: _otherPrefixedResolve,
          runtimePrefix: 'df',
        ).write(_singleFieldSchema(state, fieldName: 'state')),
        throwsA(_diagnostic(GenerationDiagnosticCode.invalidModel, 'other')),
      );
      expect(
        () => const ModelSchemaWriter(
          symbolNameResolver: _typesPrefixedResolve,
          runtimePrefix: 'df',
        ).write(_singleFieldSchema(state, fieldName: 'types')),
        throwsA(_diagnostic(GenerationDiagnosticCode.invalidModel, 'types')),
      );
    });

    test('required 参数带 default 返回 DF1003', () {
      final base = _singleFieldSchema(const ScalarShape(ScalarKind.integer));
      final schema = ModelSchema(
        id: base.id,
        implementationName: base.implementationName,
        constructor: ConstructorSchema(
          kind: ConstructorKind.redirectingFactory,
          parameters: const [
            ConstructorParameterSchema(
              name: 'value',
              shape: ScalarShape(ScalarKind.integer),
              kind: ParameterKind.requiredNamed,
              defaultValueCode: '0',
              fieldName: 'value',
            ),
          ],
        ),
        fields: [
          FieldSchema(
            name: 'value',
            shape: const ScalarShape(ScalarKind.integer),
            isRequired: true,
            defaultValueCode: '0',
          ),
        ],
      );

      expect(
        () => _writer().write(schema),
        throwsA(
          _diagnostic(GenerationDiagnosticCode.constructorMismatch, 'value'),
        ),
      );
    });

    test('字段与生成成员重名返回 DF1001，other 字段正确限定 this', () {
      for (final name in const <String>{
        'copyWith',
        'hashCode',
        'toString',
        'runtimeType',
        'noSuchMethod',
        'fromJson',
        '_frozen',
      }) {
        final conflicting = _singleFieldSchema(
          const ScalarShape(ScalarKind.string),
          fieldName: name,
        );
        expect(
          () => _writer().write(conflicting),
          throwsA(_diagnostic(GenerationDiagnosticCode.invalidModel, name)),
          reason: '应拒绝生成成员或 Object 成员 $name',
        );
      }

      final namedBase = _singleFieldSchema(
        const ScalarShape(ScalarKind.string),
        fieldName: 'create',
      );
      final namedConstructorCollision = ModelSchema(
        id: namedBase.id,
        implementationName: namedBase.implementationName,
        constructor: ConstructorSchema(
          name: 'create',
          kind: namedBase.constructor.kind,
          parameters: namedBase.constructor.parameters,
        ),
        fields: namedBase.fields,
      );
      expect(
        () => _writer().write(namedConstructorCollision),
        throwsA(_diagnostic(GenerationDiagnosticCode.invalidModel, 'create')),
      );

      final money = CustomShape(
        const SymbolId(libraryUri: 'package:money/money.dart', name: 'Money'),
      );
      final witnessSource = _writer().write(
        _singleFieldSchema(
          money,
          semanticWitness: ConstructorParameterSchema(
            name: 'frozen',
            shape: _dataforgeTypeShape(money),
            kind: ParameterKind.requiredNamed,
          ),
        ),
      );
      expect(
        witnessSource,
        contains('final df.DataforgeType<Money> _df_frozen;'),
      );

      final source = _writer().write(
        _singleFieldSchema(
          const ScalarShape(ScalarKind.string),
          fieldName: 'other',
        ),
      );
      expect(source, contains('this.other, other.other)'));
    });

    test('重复 JSON 主名/alternate name 返回 DF1006', () {
      final schema = _userSchema();
      final duplicate = ModelSchema(
        id: schema.id,
        implementationName: schema.implementationName,
        constructor: schema.constructor,
        fields: [
          schema.fields.first,
          FieldSchema(
            name: 'xs',
            shape: schema.fields.last.shape,
            defaultValueCode: 'const []',
            alternateJsonNames: const ['displayName'],
          ),
        ],
      );

      expect(
        () => _writer().write(duplicate),
        throwsA(
          _diagnostic(GenerationDiagnosticCode.invalidJsonConfiguration, 'xs'),
        ),
      );

      final jsonDisabled = ModelSchema(
        id: duplicate.id,
        implementationName: duplicate.implementationName,
        constructor: duplicate.constructor,
        fields: duplicate.fields,
        includeFromJson: false,
        includeToJson: false,
      );
      expect(() => _writer().write(jsonDisabled), returnsNormally);
    });
  });

  test(
    '生成源码可格式化，并实际满足深冻结、结构共享、泛型 witness 与 JSON path',
    () async {
      final generated = [
        _writer().write(_userSchema()),
        _writer().write(_boxSchema()),
        _writer().write(_bagSchema()),
        _writer().write(_changingNodeSchema()),
        _writer().write(_holderSchema()),
        _writer().write(_timerSchema()),
        _writer().write(_recordBoxSchema()),
        _writer().write(_recordTwinSchema()),
        _writer().write(_recordOtherLayoutSchema()),
        _writer().write(_dollarJsonSchema()),
        _writer().write(_decodeNameCollisionSchema()),
      ].join('\n');
      final fixture = _behaviorFixture(generated);
      final temporary = await Directory.systemTemp.createTemp(
        'dataforge_writer_test_',
      );
      addTearDown(() => temporary.delete(recursive: true));
      await Directory('${temporary.path}/bin').create(recursive: true);
      final annotationPath = Directory.current.parent.uri
          .resolve('annotation/')
          .toFilePath();
      await File('${temporary.path}/pubspec.yaml').writeAsString('''
name: dataforge_writer_fixture
publish_to: none
environment:
  sdk: '>=3.9.0 <4.0.0'
dependencies:
  dataforge_annotation:
    path: ${_yamlString(annotationPath)}
''');
      final sourceFile = File('${temporary.path}/bin/main.dart');
      await sourceFile.writeAsString(fixture);

      final format = await Process.run(Platform.resolvedExecutable, [
        'format',
        sourceFile.path,
      ], workingDirectory: temporary.path);
      expect(
        format.exitCode,
        0,
        reason: '${format.stdout}\n${format.stderr}\n$fixture',
      );

      final pubGet = await Process.run(Platform.resolvedExecutable, [
        'pub',
        'get',
        '--offline',
      ], workingDirectory: temporary.path);
      expect(pubGet.exitCode, 0, reason: '${pubGet.stdout}\n${pubGet.stderr}');

      final run = await Process.run(Platform.resolvedExecutable, [
        'run',
        'bin/main.dart',
      ], workingDirectory: temporary.path);
      expect(run.exitCode, 0, reason: '${run.stdout}\n${run.stderr}');
      expect(run.stdout, contains('writer behavior ok'));
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

ModelSchemaWriter _writer() =>
    const ModelSchemaWriter(symbolNameResolver: _resolve, runtimePrefix: 'df');

String _resolve(SymbolId symbol) => symbol.name;

String _otherPrefixedResolve(SymbolId symbol) => 'other.${symbol.name}';

String _typesPrefixedResolve(SymbolId symbol) => 'types.${symbol.name}';

ModelSchema _userSchema() {
  return _userSchemaWithImplementation('_User');
}

ModelSchema _userSchemaWithImplementation(String implementationName) {
  return ModelSchema(
    id: const SchemaId(libraryUri: _modelsUri, name: 'User'),
    implementationName: implementationName,
    constructor: ConstructorSchema(
      kind: ConstructorKind.redirectingFactory,
      parameters: const [
        ConstructorParameterSchema(
          name: 'name',
          shape: ScalarShape(ScalarKind.string),
          kind: ParameterKind.requiredNamed,
          fieldName: 'name',
        ),
        ConstructorParameterSchema(
          name: 'xs',
          shape: ListShape(ListShape(ScalarShape(ScalarKind.integer))),
          kind: ParameterKind.optionalNamed,
          defaultValueCode: 'const []',
          fieldName: 'xs',
        ),
      ],
    ),
    fields: [
      FieldSchema(
        name: 'name',
        shape: const ScalarShape(ScalarKind.string),
        isRequired: true,
        alternateJsonNames: const ['displayName'],
      ),
      FieldSchema(
        name: 'xs',
        shape: const ListShape(ListShape(ScalarShape(ScalarKind.integer))),
        defaultValueCode: 'const []',
      ),
    ],
  );
}

ModelSchema _boxSchema() {
  return ModelSchema(
    id: const SchemaId(libraryUri: _modelsUri, name: 'Box'),
    implementationName: '_Box',
    typeParameters: const [TypeParameterSchema(name: 'T')],
    constructor: ConstructorSchema(
      kind: ConstructorKind.redirectingFactory,
      parameters: [
        ConstructorParameterSchema(
          name: 'type',
          shape: _dataforgeTypeShape(const TypeParameterShape('T')),
          kind: ParameterKind.requiredNamed,
        ),
        const ConstructorParameterSchema(
          name: 'value',
          shape: TypeParameterShape('T'),
          kind: ParameterKind.requiredNamed,
          fieldName: 'value',
        ),
      ],
    ),
    fields: [
      FieldSchema(
        name: 'value',
        shape: const TypeParameterShape('T'),
        isRequired: true,
      ),
    ],
  );
}

ModelSchema _bagSchema() {
  const typeParameter = TypeParameterShape('T');
  const values = ListShape(typeParameter);
  final box = ModelShape(
    const SchemaId(libraryUri: _modelsUri, name: 'Box'),
    typeArguments: const [typeParameter],
    witnessArguments: const [typeParameter],
  );
  final record = RecordShape(
    positional: const [typeParameter],
    named: const {'items': values},
  );
  return ModelSchema(
    id: const SchemaId(libraryUri: _modelsUri, name: 'Bag'),
    implementationName: '_Bag',
    typeParameters: const [TypeParameterSchema(name: 'T')],
    constructor: ConstructorSchema(
      kind: ConstructorKind.redirectingFactory,
      parameters: [
        ConstructorParameterSchema(
          name: 'type',
          shape: _dataforgeTypeShape(typeParameter),
          kind: ParameterKind.requiredNamed,
        ),
        const ConstructorParameterSchema(
          name: 'values',
          shape: values,
          kind: ParameterKind.requiredNamed,
          fieldName: 'values',
        ),
        ConstructorParameterSchema(
          name: 'box',
          shape: box,
          kind: ParameterKind.requiredNamed,
          fieldName: 'box',
        ),
        ConstructorParameterSchema(
          name: 'record',
          shape: record,
          kind: ParameterKind.requiredNamed,
          fieldName: 'record',
        ),
      ],
    ),
    fields: [
      FieldSchema(name: 'values', shape: values, isRequired: true),
      FieldSchema(name: 'box', shape: box, isRequired: true),
      FieldSchema(name: 'record', shape: record, isRequired: true),
    ],
    includeFromJson: false,
    includeToJson: false,
  );
}

ModelSchema _changingNodeSchema() {
  const typeParameter = TypeParameterShape('T');
  const childArgument = ListShape(typeParameter);
  final child = NullableShape(
    ModelShape(
      const SchemaId(libraryUri: _modelsUri, name: 'ChangingNode'),
      typeArguments: const [childArgument],
      witnessArguments: const [childArgument],
    ),
  );
  return ModelSchema(
    id: const SchemaId(libraryUri: _modelsUri, name: 'ChangingNode'),
    implementationName: '_ChangingNode',
    typeParameters: const [TypeParameterSchema(name: 'T')],
    constructor: ConstructorSchema(
      kind: ConstructorKind.redirectingFactory,
      parameters: [
        ConstructorParameterSchema(
          name: 'type',
          shape: _dataforgeTypeShape(typeParameter),
          kind: ParameterKind.requiredNamed,
        ),
        ConstructorParameterSchema(
          name: 'child',
          shape: child,
          kind: ParameterKind.requiredNamed,
          fieldName: 'child',
        ),
        const ConstructorParameterSchema(
          name: 'value',
          shape: typeParameter,
          kind: ParameterKind.requiredNamed,
          fieldName: 'value',
        ),
      ],
    ),
    fields: [
      FieldSchema(name: 'child', shape: child, isRequired: true),
      FieldSchema(name: 'value', shape: typeParameter, isRequired: true),
    ],
  );
}

ModelSchema _timerSchema() {
  return ModelSchema(
    id: const SchemaId(libraryUri: _modelsUri, name: 'Timer'),
    implementationName: '_Timer',
    constructor: ConstructorSchema(
      kind: ConstructorKind.redirectingFactory,
      parameters: const [
        ConstructorParameterSchema(
          name: 'elapsed',
          shape: DurationShape(),
          kind: ParameterKind.requiredNamed,
          fieldName: 'elapsed',
        ),
      ],
    ),
    fields: [
      FieldSchema(
        name: 'elapsed',
        shape: const DurationShape(),
        isRequired: true,
      ),
    ],
  );
}

ModelSchema _holderSchema() {
  const listOfInt = ListShape(ScalarShape(ScalarKind.integer));
  final boxOfList = ModelShape(
    const SchemaId(libraryUri: _modelsUri, name: 'Box'),
    typeArguments: const [listOfInt],
    witnessArguments: const [listOfInt],
  );
  return ModelSchema(
    id: const SchemaId(libraryUri: _modelsUri, name: 'Holder'),
    implementationName: '_Holder',
    constructor: ConstructorSchema(
      kind: ConstructorKind.redirectingFactory,
      parameters: [
        ConstructorParameterSchema(
          name: 'box',
          shape: boxOfList,
          kind: ParameterKind.requiredNamed,
          fieldName: 'box',
        ),
      ],
    ),
    fields: [FieldSchema(name: 'box', shape: boxOfList, isRequired: true)],
  );
}

ModelSchema _recordBoxSchema() => _recordSchema('RecordBox', 'payload');

ModelSchema _recordTwinSchema() => _recordSchema('RecordTwin', 'payload');

ModelSchema _recordOtherLayoutSchema() =>
    _recordSchema('RecordOtherLayout', 'other');

ModelSchema _dollarJsonSchema() => ModelSchema(
  id: const SchemaId(libraryUri: _modelsUri, name: 'DollarJson'),
  implementationName: '_DollarJson',
  constructor: ConstructorSchema(
    kind: ConstructorKind.redirectingFactory,
    parameters: const [
      ConstructorParameterSchema(
        name: 'value',
        shape: ScalarShape(ScalarKind.string),
        kind: ParameterKind.requiredNamed,
        fieldName: 'value',
      ),
    ],
  ),
  fields: [
    FieldSchema(
      name: 'value',
      shape: const ScalarShape(ScalarKind.string),
      isRequired: true,
      jsonName: r'$id',
      alternateJsonNames: [r'${previous}'],
    ),
  ],
);

ModelSchema _decodeNameCollisionSchema() {
  const parameterNames = <String>['json', 'context', 'acceptedJsonKeys', 'key'];
  const fieldNames = <String>['a', 'b', 'c', 'd'];
  final typeParameters = <TypeParameterSchema>[
    for (var index = 0; index < parameterNames.length; index++)
      TypeParameterSchema(name: 'T$index'),
  ];
  final witnesses = <ConstructorParameterSchema>[
    for (var index = 0; index < parameterNames.length; index++)
      ConstructorParameterSchema(
        name: parameterNames[index],
        shape: _dataforgeTypeShape(TypeParameterShape('T$index')),
        kind: ParameterKind.requiredNamed,
      ),
  ];
  final fieldParameters = <ConstructorParameterSchema>[
    for (var index = 0; index < fieldNames.length; index++)
      ConstructorParameterSchema(
        name: fieldNames[index],
        shape: TypeParameterShape('T$index'),
        kind: ParameterKind.requiredNamed,
        fieldName: fieldNames[index],
      ),
  ];
  return ModelSchema(
    id: const SchemaId(libraryUri: _modelsUri, name: 'DecodeNameCollision'),
    implementationName: '_DecodeNameCollision',
    typeParameters: typeParameters,
    constructor: ConstructorSchema(
      kind: ConstructorKind.redirectingFactory,
      parameters: [...witnesses, ...fieldParameters],
    ),
    fields: [
      for (var index = 0; index < fieldNames.length; index++)
        FieldSchema(
          name: fieldNames[index],
          shape: TypeParameterShape('T$index'),
          isRequired: true,
        ),
    ],
  );
}

ModelSchema _recordSchema(String modelName, String namedField) {
  final record = RecordShape(
    positional: const [ListShape(ListShape(ScalarShape(ScalarKind.integer)))],
    named: {namedField: const TypeParameterShape('T')},
  );
  return ModelSchema(
    id: SchemaId(libraryUri: _modelsUri, name: modelName),
    implementationName: '_$modelName',
    typeParameters: const [TypeParameterSchema(name: 'T')],
    constructor: ConstructorSchema(
      kind: ConstructorKind.redirectingFactory,
      parameters: [
        ConstructorParameterSchema(
          name: 'payloadType',
          shape: _dataforgeTypeShape(const TypeParameterShape('T')),
          kind: ParameterKind.requiredNamed,
        ),
        ConstructorParameterSchema(
          name: 'value',
          shape: record,
          kind: ParameterKind.requiredNamed,
          fieldName: 'value',
        ),
      ],
    ),
    fields: [FieldSchema(name: 'value', shape: record, isRequired: true)],
    includeFromJson: false,
    includeToJson: false,
  );
}

CustomShape _dataforgeTypeShape(TypeShape target) => CustomShape(
  const SymbolId(libraryUri: _runtimeUri, name: 'DataforgeType'),
  typeArguments: [target],
);

ModelSchema _singleFieldSchema(
  TypeShape shape, {
  bool isFinal = true,
  ConstructorParameterSchema? semanticWitness,
  String fieldName = 'value',
}) {
  return ModelSchema(
    id: const SchemaId(libraryUri: _modelsUri, name: 'Value'),
    implementationName: '_Value',
    constructor: ConstructorSchema(
      kind: ConstructorKind.redirectingFactory,
      parameters: [
        if (semanticWitness != null) semanticWitness,
        ConstructorParameterSchema(
          name: fieldName,
          shape: shape,
          kind: ParameterKind.requiredNamed,
          fieldName: fieldName,
        ),
      ],
    ),
    fields: [
      FieldSchema(
        name: fieldName,
        shape: shape,
        isFinal: isFinal,
        isRequired: true,
      ),
    ],
  );
}

Matcher _diagnostic(GenerationDiagnosticCode code, String target) {
  return isA<ModelSchemaWriterException>()
      .having((error) => error.diagnostic.code, 'code', code)
      .having((error) => error.diagnostic.target, 'target', target);
}

String _yamlString(String value) => "'${value.replaceAll("'", "''")}'";

String _behaviorFixture(String generated) =>
    '''
import 'package:dataforge_annotation/dataforge_annotation.dart' as df;

@df.Dataforge()
abstract final class User with _\$User {
  const User._();

  factory User({
    required String name,
    List<List<int>> xs,
  }) = _User;

  factory User.fromJson(Map<String, Object?> json) = _User.fromJson;
}

@df.Dataforge()
abstract final class Box<T> with _\$Box<T> {
  const Box._();

  factory Box({
    required df.DataforgeType<T> type,
    required T value,
  }) = _Box<T>;

  factory Box.fromJson(
    Map<String, Object?> json, {
    required df.DataforgeType<T> type,
  }) = _Box<T>.fromJson;
}

@df.Dataforge(includeFromJson: false, includeToJson: false)
abstract final class Bag<T> with _\$Bag<T> {
  const Bag._();

  factory Bag({
    required df.DataforgeType<T> type,
    required List<T> values,
    required Box<T> box,
    required (T, {List<T> items}) record,
  }) = _Bag<T>;
}

@df.Dataforge()
abstract final class ChangingNode<T> with _\$ChangingNode<T> {
  const ChangingNode._();

  factory ChangingNode({
    required df.DataforgeType<T> type,
    required ChangingNode<List<T>>? child,
    required T value,
  }) = _ChangingNode<T>;

  factory ChangingNode.fromJson(
    Map<String, Object?> json, {
    required df.DataforgeType<T> type,
  }) = _ChangingNode<T>.fromJson;
}

@df.Dataforge()
abstract final class Timer with _\$Timer {
  const Timer._();

  factory Timer({required Duration elapsed}) = _Timer;

  factory Timer.fromJson(Map<String, Object?> json) = _Timer.fromJson;
}

@df.Dataforge()
abstract final class Holder with _\$Holder {
  const Holder._();

  factory Holder({required Box<List<int>> box}) = _Holder;

  factory Holder.fromJson(Map<String, Object?> json) = _Holder.fromJson;
}

@df.Dataforge(includeFromJson: false, includeToJson: false)
abstract final class RecordBox<T> with _\$RecordBox<T> {
  const RecordBox._();

  factory RecordBox({
    required df.DataforgeType<T> payloadType,
    required (List<List<int>>, {T payload}) value,
  }) = _RecordBox<T>;
}

@df.Dataforge(includeFromJson: false, includeToJson: false)
abstract final class RecordTwin<T> with _\$RecordTwin<T> {
  const RecordTwin._();

  factory RecordTwin({
    required df.DataforgeType<T> payloadType,
    required (List<List<int>>, {T payload}) value,
  }) = _RecordTwin<T>;
}

@df.Dataforge(includeFromJson: false, includeToJson: false)
abstract final class RecordOtherLayout<T> with _\$RecordOtherLayout<T> {
  const RecordOtherLayout._();

  factory RecordOtherLayout({
    required df.DataforgeType<T> payloadType,
    required (List<List<int>>, {T other}) value,
  }) = _RecordOtherLayout<T>;
}

@df.Dataforge()
abstract final class DollarJson with _\$DollarJson {
  const DollarJson._();

  factory DollarJson({required String value}) = _DollarJson;

  factory DollarJson.fromJson(Map<String, Object?> json) =
      _DollarJson.fromJson;
}

@df.Dataforge()
abstract final class DecodeNameCollision<T0, T1, T2, T3>
    with _\$DecodeNameCollision<T0, T1, T2, T3> {
  const DecodeNameCollision._();

  factory DecodeNameCollision({
    required df.DataforgeType<T0> json,
    required df.DataforgeType<T1> context,
    required df.DataforgeType<T2> acceptedJsonKeys,
    required df.DataforgeType<T3> key,
    required T0 a,
    required T1 b,
    required T2 c,
    required T3 d,
  }) = _DecodeNameCollision<T0, T1, T2, T3>;

  factory DecodeNameCollision.fromJson(
    Map<String, Object?> jsonValue, {
    required df.DataforgeType<T0> json,
    required df.DataforgeType<T1> context,
    required df.DataforgeType<T2> acceptedJsonKeys,
    required df.DataforgeType<T3> key,
  }) = _DecodeNameCollision<T0, T1, T2, T3>.fromJson;
}

$generated

final class IntType implements df.DataforgeType<int> {
  @override
  int freeze(int value) => value;

  @override
  bool equals(int left, int right) => left == right;

  @override
  int hash(int value) => value.hashCode;

  @override
  int fromJson(Object? json, df.JsonDecodeContext context) {
    if (json is int) return json;
    return context.fail('expected int');
  }

  @override
  Object? toJson(int value, df.JsonEncodeContext context) => value;
}

final class MutableListType implements df.DataforgeType<List<int>> {
  @override
  List<int> freeze(List<int> value) => List<int>.unmodifiable(value);

  @override
  bool equals(List<int> left, List<int> right) =>
      left.length == right.length &&
      left.indexed.every((entry) => entry.\$2 == right[entry.\$1]);

  @override
  int hash(List<int> value) => Object.hashAll(value);

  @override
  List<int> fromJson(Object? json, df.JsonDecodeContext context) => <int>[1];

  @override
  Object? toJson(List<int> value, df.JsonEncodeContext context) => value;
}

final class BadEncodeType implements df.DataforgeType<int> {
  @override
  int freeze(int value) => value;

  @override
  bool equals(int left, int right) => left == right;

  @override
  int hash(int value) => value.hashCode;

  @override
  int fromJson(Object? json, df.JsonDecodeContext context) => 1;

  @override
  Object? toJson(int value, df.JsonEncodeContext context) => Object();
}

Never fail(String message) => throw StateError(message);

void main() {
  final external = <List<int>>[
    <int>[1],
  ];
  final user = User(name: 'milu', xs: external);
  external.first.add(2);
  external.add(<int>[3]);
  if (user.xs.length != 1 || user.xs.single.length != 1) {
    fail('constructor did not eagerly copy nested lists');
  }
  try {
    user.xs.single.add(9);
    fail('inner list is mutable');
  } on UnsupportedError {
    // expected
  }
  try {
    user.xs.add(<int>[]);
    fail('outer list is mutable');
  } on UnsupportedError {
    // expected
  }

  final renamed = user.copyWith(name: 'new');
  if (!identical(user.copyWith(), user)) {
    fail('all-sentinel copyWith did not return this');
  }
  if (!identical(
    user.copyWith(
      name: 'milu',
      xs: <List<int>>[<int>[1]],
    ),
    user,
  )) {
    fail('value-equal copyWith did not return this');
  }
  if (!identical(renamed.xs, user.xs)) {
    fail('unchanged collection was not shared');
  }
  final replacement = <List<int>>[
    <int>[7],
  ];
  final replaced = user.copyWith(xs: replacement);
  replacement.single.add(8);
  if (replaced.xs.single.length != 1) {
    fail('copyWith replacement was not frozen');
  }
  if (user != User(name: 'milu', xs: <List<int>>[<int>[1]])) {
    fail('deep equality failed');
  }
  if (user.hashCode != User(name: 'milu', xs: <List<int>>[<int>[1]]).hashCode) {
    fail('deep hash failed');
  }
  if (user.toString() != 'User(name: milu, xs: [[1]])') {
    fail('unstable toString: \${user.toString()}');
  }

  final json = user.toJson();
  try {
    json['name'] = 'changed';
    fail('toJson map is mutable');
  } on UnsupportedError {
    // expected
  }
  final jsonXs = json['xs']! as List<Object?>;
  try {
    jsonXs.add(2);
    fail('toJson nested list is mutable');
  } on UnsupportedError {
    // expected
  }

  try {
    \$UserType.fromJson(
      <String, Object?>{
        'name': 'milu',
        'xs': <Object?>[
          <Object?>[1, 'bad'],
        ],
      },
      const df.JsonDecodeContext().field('owner'),
    );
    fail('invalid JSON was accepted');
  } on df.DataforgeDecodeException catch (error) {
    if (error.path != r'\$.owner.xs[0][1]' ||
        error.code != df.DataforgeJsonErrorCode.typeMismatch ||
        error.expectedType != 'int' ||
        error.actualType != 'String' ||
        error.model != 'package:writer_fixture/models.dart#User' ||
        error.field != 'xs') {
      fail('wrong decode path: \${error.path}');
    }
  }

  try {
    User.fromJson(<String, Object?>{
      'name': 'milu',
      'unexpected': true,
    });
    fail('unknown JSON key was accepted');
  } on df.DataforgeDecodeException catch (error) {
    if (error.path != r'\$.unexpected' ||
        error.code != df.DataforgeJsonErrorCode.unknownField ||
        error.expectedType != 'known JSON field' ||
        error.actualType != 'String' ||
        error.model != 'package:writer_fixture/models.dart#User' ||
        error.field != 'unexpected') {
      fail('wrong unknown-key path: \${error.path}');
    }
  }
  try {
    User.fromJson(<String, Object?>{
      'name': 'milu',
      'displayName': 'duplicate',
    });
    fail('primary and alternate names were both accepted');
  } on df.DataforgeDecodeException catch (error) {
    if (error.path != r'\$.displayName' ||
        error.code != df.DataforgeJsonErrorCode.conflictingFieldAliases ||
        error.expectedType != 'exactly one JSON field alias' ||
        error.actualType != 'multiple String keys' ||
        error.model != 'package:writer_fixture/models.dart#User' ||
        error.field != 'name') {
      fail('wrong alias-conflict path: \${error.path}');
    }
  }

  final firstType = IntType();
  final secondType = IntType();
  final first = Box<int>(type: firstType, value: 1);
  final sameWitness = Box<int>(type: firstType, value: 1);
  final otherWitness = Box<int>(type: secondType, value: 1);
  if (first != sameWitness) fail('same witness should compare equal');
  if (first == otherWitness) fail('different witnesses compared equal');
  final covariantView = Box<num>(type: firstType, value: 1);
  if (first != covariantView || covariantView != first) {
    fail('generic equality is not symmetric across covariant views');
  }
  if (first.hashCode != covariantView.hashCode) {
    fail('equal covariant views have different hashes');
  }
  final intBag = Bag<int>(
    type: firstType,
    values: <int>[1],
    box: first,
    record: (1, items: <int>[1]),
  );
  final numBag = Bag<num>(
    type: firstType,
    values: <num>[1],
    box: covariantView,
    record: (1, items: <num>[1]),
  );
  if (intBag != numBag || numBag != intBag) {
    fail('nested covariant equality is not symmetric');
  }
  if (intBag.hashCode != numBag.hashCode) {
    fail('nested covariant equality has inconsistent hashes');
  }
  final erasedBoxType = \$BoxType<dynamic>(firstType);
  if (!erasedBoxType.equals(first, covariantView)) {
    fail('erased model witness rejected compatible covariant values');
  }
  if (!df.dataforgeValueEquals(
    \$BagType<int>(firstType),
    \$BagType<num>(firstType),
    intBag,
    numBag,
  )) {
    fail('compatible covariant model witnesses rejected equal values');
  }

  final cyclic = <String, Object?>{};
  cyclic['child'] = cyclic;
  cyclic['value'] = 1;
  try {
    ChangingNode<int>.fromJson(cyclic, type: firstType);
    fail('changing recursive generic JSON cycle was accepted');
  } on df.DataforgeDecodeException catch (error) {
    if (error.code != df.DataforgeJsonErrorCode.cyclicInput ||
        error.path != r'\$.child.child') {
      fail('wrong changing generic cycle failure: \${error.code} \${error.path}');
    }
  }
  if (first.copyWith(value: 2) != Box<int>(type: firstType, value: 2)) {
    fail('generic copyWith lost its witness');
  }
  final decoded = Box<int>.fromJson(
    <String, Object?>{'value': 4},
    type: firstType,
  );
  if (decoded.value != 4) fail('generic fromJson failed');
  final boxType = \$BoxType<int>(firstType);
  final boxTypeIdentity = boxType as df.DataforgeTypeIdentity;
  try {
    boxTypeIdentity.dataforgeTypeArguments.add(firstType);
    fail('model witness type arguments are mutable');
  } on UnsupportedError {
    // expected
  }
  if (!identical(boxType.freeze(first), first)) {
    fail('model witness did not retain an already frozen value');
  }
  if (boxType.equals(
    otherWitness,
    Box<int>(type: secondType, value: 1),
  )) {
    fail('model witness accepted values frozen by incompatible semantics');
  }
  if (boxType.equals(otherWitness, otherWitness)) {
    fail('model witness accepted an identical value with incompatible semantics');
  }
  final firstHolder = Holder(
    box: Box<List<int>>(
      type: df.DataforgeTypes.list(df.DataforgeTypes.intType),
      value: <int>[1, 2],
    ),
  );
  final secondHolder = Holder(
    box: Box<List<int>>(
      type: df.DataforgeTypes.list(df.DataforgeTypes.intType),
      value: <int>[1, 2],
    ),
  );
  if (firstHolder != secondHolder) {
    fail('nested generic model witnesses were compared by object identity');
  }
  final firstHolderHash = firstHolder.hashCode;
  if (firstHolderHash != secondHolder.hashCode ||
      firstHolderHash != firstHolder.hashCode) {
    fail('nested generic model hash is not semantically stable');
  }
  if (!identical(firstHolder.copyWith(box: secondHolder.box), firstHolder)) {
    fail('nested generic value-equal copyWith did not return this');
  }

  final mutableListType = MutableListType();
  final recordLists = <List<int>>[
    <int>[1],
  ];
  final recordPayload = <int>[2];
  final record = RecordBox<List<int>>(
    payloadType: mutableListType,
    value: (recordLists, payload: recordPayload),
  );
  recordLists.single.add(9);
  recordLists.add(<int>[3]);
  recordPayload.add(4);
  if (record.value.\$1.length != 1 ||
      record.value.\$1.single.length != 1 ||
      record.value.payload.length != 1) {
    fail('record children were not deeply frozen');
  }
  try {
    record.value.\$1.single.add(5);
    fail('record positional child remained mutable');
  } on UnsupportedError {
    // expected
  }
  try {
    record.value.payload.add(5);
    fail('record named child remained mutable');
  } on UnsupportedError {
    // expected
  }
  final equalRecord = RecordBox<List<int>>(
    payloadType: mutableListType,
    value: (
      <List<int>>[<int>[1]],
      payload: <int>[2],
    ),
  );
  if (record != equalRecord || record.hashCode != equalRecord.hashCode) {
    fail('record equality/hash did not follow child witnesses');
  }
  if (!identical(
    record.copyWith(
      value: (
        <List<int>>[<int>[1]],
        payload: <int>[2],
      ),
    ),
    record,
  )) {
    fail('value-equal record copyWith did not return this');
  }
  final firstRecordType = _\$RecordBoxRecordDataforgeType0<List<int>>(
    df.DataforgeTypes.list(
      df.DataforgeTypes.list(df.DataforgeTypes.intType),
    ),
    mutableListType,
  );
  try {
    firstRecordType.dataforgeTypeArguments.add(mutableListType);
    fail('record witness type arguments are mutable');
  } on UnsupportedError {
    // expected
  }
  final secondRecordType = _\$RecordTwinRecordDataforgeType0<List<int>>(
    df.DataforgeTypes.list(
      df.DataforgeTypes.list(df.DataforgeTypes.intType),
    ),
    mutableListType,
  );
  if (!df.dataforgeTypeEquals(firstRecordType, secondRecordType) ||
      df.dataforgeTypeHash(firstRecordType) !=
          df.dataforgeTypeHash(secondRecordType)) {
    fail('record witness identity omitted layout or child semantics');
  }
  final otherLayoutRecordType =
      _\$RecordOtherLayoutRecordDataforgeType0<List<int>>(
        df.DataforgeTypes.list(
          df.DataforgeTypes.list(df.DataforgeTypes.intType),
        ),
        mutableListType,
      );
  if (df.dataforgeTypeEquals(firstRecordType, otherLayoutRecordType)) {
    fail('record witness identity ignored the named layout');
  }
  final incompatibleRecordType = _\$RecordBoxRecordDataforgeType0<List<int>>(
    df.DataforgeTypes.list(
      df.DataforgeTypes.list(df.DataforgeTypes.intType),
    ),
    MutableListType(),
  );
  if (df.dataforgeTypeEquals(firstRecordType, incompatibleRecordType)) {
    fail('record witness identity ignored custom child witness identity');
  }

  final decodedList = Box<List<int>>.fromJson(
    <String, Object?>{'value': <Object?>[1]},
    type: mutableListType,
  );
  try {
    decodedList.value.add(2);
    fail('fromJson result skipped witness.freeze');
  } on UnsupportedError {
    // expected
  }
  try {
    Box<int>(type: BadEncodeType(), value: 1).toJson();
    fail('illegal custom witness output was accepted');
  } on df.DataforgeEncodeException catch (error) {
    if (error.path != r'\$.value' ||
        error.code != df.DataforgeJsonErrorCode.invalidJsonOutput ||
        error.expectedType != 'JSON value' ||
        error.actualType != 'Object' ||
        error.model != 'package:writer_fixture/models.dart#Box' ||
        error.field != 'value') {
      fail('wrong encode path: \${error.path}');
    }
  }

  final timer = Timer(elapsed: const Duration(microseconds: 5));
  if (timer.toJson()['elapsed'] != 5) {
    fail('Duration toJson failed');
  }
  final decodedTimer = Timer.fromJson(<String, Object?>{'elapsed': 7});
  if (decodedTimer.elapsed != const Duration(microseconds: 7)) {
    fail('Duration fromJson failed');
  }

  final dollar = DollarJson.fromJson(<String, Object?>{r'\$id': 'primary'});
  if (dollar.value != 'primary' || dollar.toJson()[r'\$id'] != 'primary') {
    fail(r'JSON names containing \$ were not preserved');
  }
  final previousDollar = DollarJson.fromJson(
    <String, Object?>{r'\${previous}': 'previous'},
  );
  if (previousDollar.value != 'previous') {
    fail(r'alternate JSON name containing \$ was not preserved');
  }
  try {
    DollarJson.fromJson(<String, Object?>{r'\${previous}': 1});
    fail('invalid alternate JSON value was accepted');
  } on df.DataforgeDecodeException catch (error) {
    if (error.code != df.DataforgeJsonErrorCode.typeMismatch ||
        error.model != 'package:writer_fixture/models.dart#DollarJson' ||
        error.field != 'value' ||
        !error.path.contains('previous')) {
      fail('alternate JSON key lost structured field metadata');
    }
  }

  final collision = DecodeNameCollision<int, int, int, int>.fromJson(
    <String, Object?>{'a': 1, 'b': 2, 'c': 3, 'd': 4},
    json: IntType(),
    context: IntType(),
    acceptedJsonKeys: IntType(),
    key: IntType(),
  );
  if (collision.a != 1 ||
      collision.b != 2 ||
      collision.c != 3 ||
      collision.d != 4) {
    fail('decode helper names collided with witness parameters');
  }

  print('writer behavior ok');
}
''';
