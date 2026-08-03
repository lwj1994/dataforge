import 'package:dataforge_base/src/v1/schema.dart';
import 'package:test/test.dart';

const packageUri = 'package:example/models.dart';
const userId = SchemaId(libraryUri: packageUri, name: 'User');
const statusId = SymbolId(libraryUri: packageUri, name: 'Status');

void main() {
  group('稳定身份', () {
    test('SymbolId 和 SchemaId 可稳定 round-trip', () {
      const symbol = SymbolId(libraryUri: packageUri, name: 'Money');
      const schema = SchemaId(libraryUri: packageUri, name: 'Invoice');

      expect(SymbolId.fromMap(symbol.toMap()), symbol);
      expect(SymbolId.fromMap(symbol.toMap()).hashCode, symbol.hashCode);
      expect(symbol.canonicalName, '$packageUri::Money');

      expect(SchemaId.fromMap(schema.toMap()), schema);
      expect(SchemaId.fromMap(schema.toMap()).hashCode, schema.hashCode);
      expect(
        schema.symbol,
        const SymbolId(libraryUri: packageUri, name: 'Invoice'),
      );
    });
  });

  group('TypeShape', () {
    test('所有节点均支持 equality/hash/toMap/fromMap', () {
      final shapes = <TypeShape>[
        const NullableShape(ScalarShape(ScalarKind.string)),
        const ScalarShape(ScalarKind.integer),
        const EnumShape(statusId),
        const DateTimeShape(),
        const DurationShape(),
        ModelShape(
          userId,
          typeArguments: const [TypeParameterShape('T')],
          witnessArguments: const [ListShape(TypeParameterShape('T'))],
        ),
        const TypeParameterShape('T'),
        const ListShape(ScalarShape(ScalarKind.string)),
        const SetShape(ScalarShape(ScalarKind.integer)),
        const MapShape(
          key: ScalarShape(ScalarKind.string),
          value: NullableShape(DateTimeShape()),
        ),
        RecordShape(
          positional: const [ScalarShape(ScalarKind.integer)],
          named: const {'status': EnumShape(statusId)},
        ),
        CustomShape(
          const SymbolId(libraryUri: packageUri, name: 'Money'),
          typeArguments: const [ScalarShape(ScalarKind.string)],
        ),
      ];

      for (final shape in shapes) {
        final restored = TypeShape.fromMap(shape.toMap());
        expect(restored, shape, reason: 'failed for ${shape.kind}');
        expect(
          restored.hashCode,
          shape.hashCode,
          reason: 'hash failed for ${shape.kind}',
        );
        expect(restored.toMap(), shape.toMap());
      }
    });

    test('任意层 List/Map/Set/nullable/model 递归不丢信息', () {
      final shape = NullableShape(
        ListShape(
          MapShape(
            key: const ScalarShape(ScalarKind.string),
            value: SetShape(ListShape(NullableShape(ModelShape(userId)))),
          ),
        ),
      );

      expect(shape.toDartType(), 'List<Map<String, Set<List<User?>>>>?');
      expect(
        shape.toDartType(resolveSymbol: (symbol) => 'models.${symbol.name}'),
        'List<Map<String, Set<List<models.User?>>>>?',
      );

      final restored = TypeShape.fromMap(shape.toMap());
      expect(restored, shape);
      expect(restored.toDartType(), shape.toDartType());
    });

    test('ModelShape 显式保存已实例化的 witness 调用签名', () {
      final shape = ModelShape(
        userId,
        typeArguments: const [ScalarShape(ScalarKind.string)],
        witnessArguments: [
          const MapShape(
            key: ScalarShape(ScalarKind.string),
            value: SetShape(NullableShape(ScalarShape(ScalarKind.integer))),
          ),
          CustomShape(
            const SymbolId(libraryUri: packageUri, name: 'Codec'),
            typeArguments: const [ScalarShape(ScalarKind.string)],
          ),
        ],
      );

      final wire = shape.toMap();
      final restored = TypeShape.fromMap(wire) as ModelShape;

      expect(wire['witnessArguments'], hasLength(2));
      expect(restored, shape);
      expect(restored.hashCode, shape.hashCode);
      expect(
        restored.witnessArguments.map((argument) => argument.toDartType()),
        ['Map<String, Set<int?>>', 'Codec<String>'],
      );
      expect(
        () => restored.witnessArguments.add(
          const ScalarShape(ScalarKind.integer),
        ),
        throwsUnsupportedError,
      );

      final differentSignature = ModelShape(
        userId,
        typeArguments: const [ScalarShape(ScalarKind.string)],
        witnessArguments: const [ScalarShape(ScalarKind.string)],
      );
      expect(differentSignature, isNot(shape));
    });

    test('record 同时保留位置字段和命名字段', () {
      final shape = RecordShape(
        positional: const [ScalarShape(ScalarKind.integer)],
        named: const {'labels': ListShape(ScalarShape(ScalarKind.string))},
      );

      expect(shape.toDartType(), '(int, {List<String> labels})');
      expect(TypeShape.fromMap(shape.toMap()), shape);

      final single = RecordShape(
        positional: const [ScalarShape(ScalarKind.string)],
      );
      expect(single.toDartType(), '(String,)');
      expect(TypeShape.fromMap(single.toMap()), single);
    });

    test('未知 kind 返回稳定 FormatException', () {
      expect(
        () => TypeShape.fromMap({'kind': 'future'}),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains(r'$.typeShape.kind'),
          ),
        ),
      );
    });
  });

  group('泛型声明与使用分离', () {
    test('bound 只渲染在声明位置', () {
      const parameter = TypeParameterSchema(
        name: 'T',
        bound: ScalarShape(ScalarKind.number),
      );
      const use = TypeParameterShape('T');

      expect(parameter.toDeclaration(), 'T extends num');
      expect(parameter.toUse(), 'T');
      expect(use.toDartType(), 'T');
      expect(const ListShape(use).toDartType(), 'List<T>');
      expect(const ListShape(use).toDartType(), isNot(contains('extends')));
    });

    test('ModelSchema round-trip 保留 bound 但不污染字段类型使用', () {
      final schema = ModelSchema(
        id: const SchemaId(libraryUri: packageUri, name: 'Box'),
        implementationName: r'_$Box',
        typeParameters: const [
          TypeParameterSchema(name: 'T', bound: ScalarShape(ScalarKind.number)),
        ],
        constructor: ConstructorSchema(
          kind: ConstructorKind.redirectingFactory,
          parameters: const [
            ConstructorParameterSchema(
              name: 'values',
              shape: ListShape(TypeParameterShape('T')),
              kind: ParameterKind.requiredNamed,
              fieldName: 'values',
            ),
          ],
        ),
        fields: [
          FieldSchema(
            name: 'values',
            shape: const ListShape(TypeParameterShape('T')),
            isRequired: true,
          ),
        ],
      );

      final restored = ModelSchema.fromMap(schema.toMap());
      expect(restored, schema);
      expect(restored.typeParameters.single.toDeclaration(), 'T extends num');
      expect(restored.fields.single.shape.toDartType(), 'List<T>');
    });
  });

  group('ModelSchema', () {
    test('完整元数据可版本化 round-trip', () {
      final constructor = ConstructorSchema(
        name: 'create',
        kind: ConstructorKind.redirectingFactory,
        isConst: false,
        parameters: const [
          ConstructorParameterSchema(
            name: 'createdAt',
            shape: DateTimeShape(),
            kind: ParameterKind.requiredNamed,
            fieldName: 'createdAt',
          ),
          ConstructorParameterSchema(
            name: 'status',
            shape: EnumShape(statusId),
            kind: ParameterKind.optionalNamed,
            defaultValueCode: 'Status.pending',
            fieldName: 'status',
          ),
        ],
      );
      final schema = ModelSchema(
        id: userId,
        implementationName: r'_$User',
        constructor: constructor,
        fields: [
          FieldSchema(
            name: 'createdAt',
            shape: const DateTimeShape(),
            isRequired: true,
            jsonName: 'created_at',
            alternateJsonNames: const ['createdAt', r'$created'],
            includeIfNull: false,
          ),
          FieldSchema(
            name: 'status',
            shape: const EnumShape(statusId),
            defaultValueCode: 'Status.pending',
          ),
        ],
        includeFromJson: true,
        includeToJson: false,
        generateCopyWith: true,
        deepFreeze: true,
      );

      final wire = schema.toMap();
      final restored = ModelSchema.fromMap(wire);

      expect(wire['formatVersion'], ModelSchema.currentFormatVersion);
      expect(restored, schema);
      expect(restored.hashCode, schema.hashCode);
      expect(restored.toMap(), wire);
      expect(restored.constructor, constructor);
    });

    test('DateTime 字段元数据 round-trip 后仍是 DateTimeShape', () {
      final schema = ModelSchema(
        id: const SchemaId(libraryUri: packageUri, name: 'Event'),
        implementationName: r'_$Event',
        constructor: ConstructorSchema(
          kind: ConstructorKind.redirectingFactory,
        ),
        fields: [FieldSchema(name: 'createdAt', shape: const DateTimeShape())],
      );

      final restored = ModelSchema.fromMap(schema.toMap());
      expect(restored.fields.single.shape, isA<DateTimeShape>());
      expect(restored.fields.single.shape.toMap(), {'kind': 'dateTime'});
      expect(restored, schema);
    });

    test('Duration 是独立 builtin shape 并可 round-trip', () {
      const shape = DurationShape();

      expect(shape.toDartType(), 'Duration');
      expect(shape.toMap(), {'kind': 'duration'});
      expect(TypeShape.fromMap(shape.toMap()), shape);
      expect(TypeShape.fromMap(shape.toMap()).hashCode, shape.hashCode);
    });

    test('输入集合和 Schema 暴露集合均不会被外部修改', () {
      final inputFields = <FieldSchema>[
        FieldSchema(name: 'name', shape: const ScalarShape(ScalarKind.string)),
      ];
      final schema = ModelSchema(
        id: userId,
        implementationName: r'_$User',
        constructor: ConstructorSchema(kind: ConstructorKind.factory),
        fields: inputFields,
      );

      inputFields.clear();
      expect(schema.fields, hasLength(1));
      expect(
        () => schema.fields.add(
          FieldSchema(
            name: 'age',
            shape: const ScalarShape(ScalarKind.integer),
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('拒绝未知 wire format version', () {
      final schema = ModelSchema(
        id: userId,
        implementationName: r'_$User',
        constructor: ConstructorSchema(kind: ConstructorKind.factory),
      );
      final map = schema.toMap()..['formatVersion'] = 2;

      expect(
        () => ModelSchema.fromMap(map),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('format version 2'),
          ),
        ),
      );
    });
  });
}
