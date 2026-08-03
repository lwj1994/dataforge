import 'dart:collection';
import 'dart:math';

import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:test/test.dart';

void main() {
  group('DataforgeType freeze', () {
    test('递归复制集合，外部变更不会影响冻结值', () {
      final type = DataforgeTypes.map(
        DataforgeTypes.string,
        DataforgeTypes.list(
          DataforgeTypes.set(DataforgeTypes.nullable(DataforgeTypes.intType)),
        ),
      );
      final source = <String, List<Set<int?>>>{
        'groups': [
          {1, null},
        ],
      };

      final frozen = type.freeze(source);

      source['groups']!.first.add(2);
      source['groups']!.add({3});
      source['other'] = [
        {4},
      ];

      expect(
        frozen,
        equals(<String, List<Set<int?>>>{
          'groups': [
            {1, null},
          ],
        }),
      );
    });

    test('任意容器层级都不可通过 getter 修改', () {
      final type = DataforgeTypes.map(
        DataforgeTypes.string,
        DataforgeTypes.list(DataforgeTypes.set(DataforgeTypes.intType)),
      );
      final frozen = type.freeze(<String, List<Set<int>>>{
        'groups': [
          {1},
        ],
      });

      expect(
        () => frozen['other'] = <Set<int>>[],
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => frozen['groups']!.add(<int>{2}),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => frozen['groups']!.first.add(2),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('nullable witness 保留 list、set 与 map value 的 null 位置', () {
      final nullableInt = DataforgeTypes.nullable(DataforgeTypes.intType);

      expect(
        DataforgeTypes.list(nullableInt).freeze(<int?>[1, null, 2]),
        equals(<int?>[1, null, 2]),
      );
      expect(
        DataforgeTypes.set(nullableInt).freeze(<int?>{1, null}),
        equals(<int?>{1, null}),
      );
      expect(
        DataforgeTypes.map(
          DataforgeTypes.string,
          nullableInt,
        ).freeze(<String, int?>{'value': null}),
        equals(<String, int?>{'value': null}),
      );
    });

    test('Set 与 Map 的冻结容器使用 witness 定义的键语义', () {
      const keyType = _CaseInsensitiveStringType();
      final setType = DataforgeTypes.set(keyType);
      final mapType = DataforgeTypes.map(keyType, DataforgeTypes.intType);

      final frozenSet = setType.freeze(<String>{'A', 'B'});
      final frozenMap = mapType.freeze(<String, int>{'A': 1, 'B': 2});

      expect(frozenSet, hasLength(2));
      expect(frozenSet.contains('a'), isTrue);
      expect(frozenSet.contains('A'), isTrue);
      expect(frozenMap, hasLength(2));
      expect(frozenMap['A'], equals(1));
      expect(frozenMap['a'], equals(1));
    });

    test('Set 冻结拒绝 witness 语义下重复的元素', () {
      final type = DataforgeTypes.set(const _CaseInsensitiveStringType());

      expect(
        () => type.freeze(<String>{'A', 'a'}),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Set JSON decode rejects duplicate semantic elements', () {
      final type = DataforgeTypes.set(const _CaseInsensitiveStringType());

      expect(
        () => type.fromJson(<Object?>[
          'A',
          'a',
        ], const JsonDecodeContext().field('values')),
        throwsA(
          isA<DataforgeDecodeException>()
              .having(
                (error) => error.code,
                'code',
                DataforgeJsonErrorCode.duplicateElement,
              )
              .having((error) => error.path, 'path', r'$.values[1]'),
        ),
      );
    });

    test('Map key 本身是集合时也会递归复制、冻结并按值查找', () {
      final key = <int>[1, 2];
      final type = DataforgeTypes.map(
        DataforgeTypes.list(DataforgeTypes.intType),
        DataforgeTypes.string,
      );

      final frozen = type.freeze(<List<int>, String>{key: 'value'});
      key.add(3);

      expect(frozen[<int>[1, 2]], equals('value'));
      expect(frozen[<int>[1, 2, 3]], isNull);
      final frozenKey = frozen.keys.single;
      expect(() => frozenKey.add(4), throwsA(isA<UnsupportedError>()));
    });

    test('Map 冻结拒绝 witness 语义下重复的 key', () {
      final type = DataforgeTypes.map(
        const _CaseInsensitiveStringType(),
        DataforgeTypes.intType,
      );

      expect(
        () => type.freeze(<String, int>{'A': 1, 'a': 2}),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('DataforgeType equality 与 hash', () {
    test('内置 witness 暴露的完整类型树参数不可修改', () {
      final identities = <DataforgeType<dynamic>>[
        DataforgeTypes.nullable(DataforgeTypes.intType),
        DataforgeTypes.list(DataforgeTypes.intType),
        DataforgeTypes.set(DataforgeTypes.intType),
        DataforgeTypes.map(DataforgeTypes.string, DataforgeTypes.intType),
      ];

      for (final type in identities) {
        final identity = type as DataforgeTypeIdentity;
        expect(
          () => identity.dataforgeTypeArguments.add(DataforgeTypes.boolType),
          throwsA(isA<UnsupportedError>()),
        );
      }
    });

    test('组合 witness 按完整语义树比较，custom leaf 默认保持 identity', () {
      final first = DataforgeTypes.map(
        DataforgeTypes.string,
        DataforgeTypes.list(DataforgeTypes.nullable(DataforgeTypes.intType)),
      );
      final second = DataforgeTypes.map(
        DataforgeTypes.string,
        DataforgeTypes.list(DataforgeTypes.nullable(DataforgeTypes.intType)),
      );

      expect(identical(first, second), isFalse);
      expect(dataforgeTypeEquals(first, second), isTrue);
      expect(dataforgeTypeHash(first), dataforgeTypeHash(second));

      const custom = _CaseInsensitiveStringType();
      const otherCustom = _CaseInsensitiveStringType();
      expect(identical(custom, otherCustom), isTrue);
      final customA = _NonConstCaseInsensitiveStringType();
      final customB = _NonConstCaseInsensitiveStringType();
      expect(dataforgeTypeEquals(customA, customB), isFalse);
      expect(
        dataforgeTypeEquals(
          DataforgeTypes.list(customA),
          DataforgeTypes.list(customB),
        ),
        isFalse,
      );
    });

    test('double 与 num witness 为 NaN 提供稳定相等和 hash', () {
      expect(DataforgeTypes.doubleType.equals(double.nan, double.nan), isTrue);
      expect(
        DataforgeTypes.doubleType.hash(double.nan),
        DataforgeTypes.doubleType.hash(double.nan),
      );
      expect(DataforgeTypes.numType.equals(double.nan, double.nan), isTrue);
      expect(
        DataforgeTypes.numType.hash(double.nan),
        DataforgeTypes.numType.hash(double.nan),
      );

      final listType = DataforgeTypes.list(DataforgeTypes.doubleType);
      expect(
        listType.equals(<double>[double.nan], <double>[double.nan]),
        isTrue,
      );
      expect(
        listType.hash(<double>[double.nan]),
        listType.hash(<double>[double.nan]),
      );
    });

    test('嵌套 map/set 使用 witness 值语义且 hash 一致', () {
      final type = DataforgeTypes.map(
        DataforgeTypes.string,
        DataforgeTypes.set(DataforgeTypes.nullable(DataforgeTypes.intType)),
      );
      final left = <String, Set<int?>>{
        'first': {1, null, 2},
        'second': {3},
      };
      final right = <String, Set<int?>>{
        'second': {3},
        'first': {2, 1, null},
      };

      expect(type.equals(left, right), isTrue);
      expect(type.hash(left), equals(type.hash(right)));
      expect(
        type.equals(left, <String, Set<int?>>{
          'first': {1, null},
        }),
        isFalse,
      );
    });

    test('list 顺序属于值语义', () {
      final type = DataforgeTypes.list(DataforgeTypes.intType);

      expect(type.equals(<int>[1, 2], <int>[1, 2]), isTrue);
      expect(type.equals(<int>[1, 2], <int>[2, 1]), isFalse);
    });

    test(
      'covariant composite witnesses compare through a symmetric bridge',
      () {
        final intList = DataforgeTypes.list<int>(DataforgeTypes.intType);
        final numList = DataforgeTypes.list<num>(DataforgeTypes.intType);

        expect(dataforgeTypeEquals(intList, numList), isTrue);
        expect(
          dataforgeValueEquals(intList, numList, <int>[1], <num>[1]),
          isTrue,
        );
        expect(
          dataforgeValueEquals(numList, intList, <num>[1], <int>[1]),
          isTrue,
        );
        expect(
          dataforgeValueEquals(intList, numList, <int>[1], <num>[2]),
          isFalse,
        );

        final leftMap = DataforgeTypes.map<num, String>(
          DataforgeTypes.intType,
          DataforgeTypes.string,
        );
        final rightMap = DataforgeTypes.map<int, Object>(
          DataforgeTypes.intType,
          DataforgeTypes.string,
        );
        final leftValue = leftMap.freeze(<num, String>{1: 'one'});
        final rightValue = rightMap.freeze(<int, Object>{1: 'one'});
        expect(dataforgeTypeEquals(leftMap, rightMap), isTrue);
        expect(
          dataforgeValueEquals(leftMap, rightMap, leftValue, rightValue),
          isTrue,
        );
        expect(
          dataforgeValueEquals(rightMap, leftMap, rightValue, leftValue),
          isTrue,
        );
      },
    );

    test('DateTime 同一时刻具有相等值与相同 hash', () {
      final utc = DateTime.parse('2026-01-23T08:00:00.000Z');
      final local = utc.toLocal();

      expect(DataforgeTypes.dateTime.equals(utc, local), isTrue);
      expect(
        DataforgeTypes.dateTime.hash(utc),
        equals(DataforgeTypes.dateTime.hash(local)),
      );
    });

    test('随机嵌套集合满足相等传递性、同 hash 与冻结后稳定性', () {
      final type = DataforgeTypes.map(
        DataforgeTypes.string,
        DataforgeTypes.list(
          DataforgeTypes.set(DataforgeTypes.nullable(DataforgeTypes.intType)),
        ),
      );

      for (var seed = 0; seed < 200; seed++) {
        final random = Random(seed);
        final source = <String, List<Set<int?>>>{};
        final keyCount = random.nextInt(6);
        for (var keyIndex = 0; keyIndex < keyCount; keyIndex++) {
          source['key$keyIndex'] = List<Set<int?>>.generate(
            random.nextInt(5),
            (_) => <int?>{
              for (var index = 0; index < random.nextInt(6); index++)
                random.nextBool() ? random.nextInt(9) : null,
            },
          );
        }

        Map<String, List<Set<int?>>> reorderedCopy() {
          final entries = source.entries.toList()..shuffle(random);
          return <String, List<Set<int?>>>{
            for (final entry in entries)
              entry.key: <Set<int?>>[
                for (final values in entry.value)
                  <int?>{...(values.toList()..shuffle(random))},
              ],
          };
        }

        final second = reorderedCopy();
        final third = reorderedCopy();
        expect(type.equals(source, second), isTrue, reason: 'seed=$seed');
        expect(type.equals(second, third), isTrue, reason: 'seed=$seed');
        expect(type.equals(source, third), isTrue, reason: 'seed=$seed');
        expect(type.hash(source), type.hash(second), reason: 'seed=$seed');
        expect(type.hash(second), type.hash(third), reason: 'seed=$seed');

        final frozen = type.freeze(source);
        final frozenHash = type.hash(frozen);
        for (final values in source.values) {
          values.add(<int?>{seed});
          if (values.isNotEmpty) values.first.add(seed + 100);
        }
        source['mutated'] = <Set<int?>>[
          <int?>{seed},
        ];
        expect(type.hash(frozen), frozenHash, reason: 'seed=$seed');
        expect(frozen.containsKey('mutated'), isFalse, reason: 'seed=$seed');
      }
    });
  });

  group('DataforgeType JSON', () {
    test('strict JSON 异常提供稳定 code 与结构化类型/模型/字段', () {
      expect(
        () => DataforgeTypes.intType.fromJson(
          '1',
          const JsonDecodeContext(
            model: 'package:fixture/model.dart#Counter',
          ).field('wire_count', schemaField: 'count'),
        ),
        throwsA(
          isA<DataforgeDecodeException>()
              .having(
                (error) => error.code,
                'code',
                DataforgeJsonErrorCode.typeMismatch,
              )
              .having((error) => error.path, 'path', r'$.wire_count')
              .having((error) => error.expectedType, 'expectedType', 'int')
              .having((error) => error.actualType, 'actualType', 'String')
              .having(
                (error) => error.model,
                'model',
                'package:fixture/model.dart#Counter',
              )
              .having((error) => error.field, 'field', 'count'),
        ),
      );

      final nested = const JsonDecodeContext(model: 'Outer')
          .field('child', schemaField: 'child')
          .atModel('package:fixture/inner.dart#Inner');
      expect(
        () => nested.fail(
          'invalid',
          code: DataforgeJsonErrorCode.invalidValue,
          expectedType: 'Inner',
          actualType: 'String',
        ),
        throwsA(
          isA<DataforgeDecodeException>()
              .having(
                (error) => error.model,
                'model',
                'package:fixture/inner.dart#Inner',
              )
              .having((error) => error.field, 'field', 'child'),
        ),
      );
    });

    test('primitive 与 nullable 组合可往返', () {
      final nullableInt = DataforgeTypes.nullable(DataforgeTypes.intType);
      final listType = DataforgeTypes.list(nullableInt);
      final duration = const Duration(microseconds: 1234);

      expect(
        listType.fromJson(<Object?>[1, null, 2], const JsonDecodeContext()),
        equals(<int?>[1, null, 2]),
      );
      expect(
        DataforgeTypes.doubleType.fromJson(1, const JsonDecodeContext()),
        equals(1.0),
      );
      final durationJson = DataforgeTypes.duration.toJson(
        duration,
        const JsonEncodeContext(),
      );
      expect(durationJson, equals(1234));
      expect(
        DataforgeTypes.duration.fromJson(
          durationJson,
          const JsonDecodeContext(),
        ),
        equals(duration),
      );
    });

    test('DateTime 只接受严格 ISO-8601 字符串', () {
      final value = DateTime.parse('2026-07-31T12:34:56.789Z');
      final encoded = DataforgeTypes.dateTime.toJson(
        value,
        const JsonEncodeContext(),
      );

      expect(encoded, equals('2026-07-31T12:34:56.789Z'));
      expect(
        DataforgeTypes.dateTime.fromJson(encoded, const JsonDecodeContext()),
        equals(value),
      );
      expect(
        () => DataforgeTypes.dateTime.fromJson(
          1785501296789,
          const JsonDecodeContext(),
        ),
        throwsA(isA<DataforgeDecodeException>()),
      );
      expect(
        () => DataforgeTypes.dateTime.fromJson(
          '1785501296789',
          const JsonDecodeContext(),
        ),
        throwsA(isA<DataforgeDecodeException>()),
      );
      expect(
        () => DataforgeTypes.dateTime.fromJson(
          '2020-01-42T00:00:00Z',
          const JsonDecodeContext(),
        ),
        throwsA(isA<DataforgeDecodeException>()),
      );
      expect(
        () => DataforgeTypes.dateTime.fromJson(
          '2024-02-29T12:00:00+14:01',
          const JsonDecodeContext(),
        ),
        throwsA(isA<DataforgeDecodeException>()),
      );
      expect(
        DataforgeTypes.dateTime.fromJson(
          '2024-02-29T12:00:00+14:00',
          const JsonDecodeContext(),
        ),
        DateTime.parse('2024-02-29T12:00:00+14:00'),
      );
      for (final ambiguous in <String>['2026-07-31', '2026-07-31T12:34:56']) {
        expect(
          () => DataforgeTypes.dateTime.fromJson(
            ambiguous,
            const JsonDecodeContext(),
          ),
          throwsA(isA<DataforgeDecodeException>()),
          reason: ambiguous,
        );
      }
    });

    test('DateTime 输出正规化为 UTC，与按时刻的值语义一致', () {
      final local = DateTime(2026, 7, 31, 12, 34, 56, 789);

      final encoded = DataforgeTypes.dateTime.toJson(
        local,
        const JsonEncodeContext(),
      );
      final decoded = DataforgeTypes.dateTime.fromJson(
        encoded,
        const JsonDecodeContext(),
      );

      expect(encoded, endsWith('Z'));
      expect(DataforgeTypes.dateTime.equals(local, decoded), isTrue);
      expect(
        DataforgeTypes.dateTime.hash(local),
        DataforgeTypes.dateTime.hash(decoded),
      );
    });

    test('enum witness 精确匹配名称并可嵌套在集合', () {
      final type = DataforgeTypes.list(
        DataforgeTypes.enumeration(_RuntimeState.values),
      );

      expect(
        type.fromJson(<Object?>['ready', 'done'], const JsonDecodeContext()),
        equals(<_RuntimeState>[_RuntimeState.ready, _RuntimeState.done]),
      );
      expect(
        type.toJson(<_RuntimeState>[
          _RuntimeState.done,
        ], const JsonEncodeContext()),
        equals(<Object?>['done']),
      );
      expect(
        () => type.fromJson(<Object?>['READY'], const JsonDecodeContext()),
        throwsA(
          isA<DataforgeDecodeException>().having(
            (error) => error.path,
            'path',
            r'$[0]',
          ),
        ),
      );
    });

    test('enum witness 冻结与编码都拒绝未声明的值', () {
      final type = DataforgeTypes.enumeration(<_RuntimeState>[
        _RuntimeState.ready,
      ]);

      expect(() => type.freeze(_RuntimeState.done), throwsArgumentError);
      expect(
        () => dataforgeEncode(
          type,
          _RuntimeState.done,
          const JsonEncodeContext().field('state'),
        ),
        throwsA(
          isA<DataforgeEncodeException>().having(
            (error) => error.path,
            'path',
            r'$.state',
          ),
        ),
      );
      expect(
        () => DataforgeTypes.enumeration(<_RuntimeState>[
          _RuntimeState.ready,
          _RuntimeState.ready,
        ]),
        throwsArgumentError,
      );
    });

    test('enum witness identity 使用实际 enum 类型与无序名称集', () {
      final forward = DataforgeTypes.enumeration(<Enum>[
        _RuntimeState.ready,
        _RuntimeState.done,
      ]);
      final reverse = DataforgeTypes.enumeration(<Enum>[
        _RuntimeState.done,
        _RuntimeState.ready,
      ]);
      final other = DataforgeTypes.enumeration(<Enum>[
        _OtherRuntimeState.ready,
        _OtherRuntimeState.done,
      ]);

      expect(dataforgeTypeEquals(forward, reverse), isTrue);
      expect(dataforgeTypeHash(forward), dataforgeTypeHash(reverse));
      expect(dataforgeTypeEquals(forward, other), isFalse);
      expect(
        () => DataforgeTypes.enumeration(<Enum>[
          _RuntimeState.ready,
          _OtherRuntimeState.done,
        ]),
        throwsArgumentError,
      );
    });

    test('map key 与 value 都通过 witness', () {
      final type = DataforgeTypes.map(
        DataforgeTypes.intType,
        DataforgeTypes.nullable(DataforgeTypes.doubleType),
      );

      final decoded = type.fromJson(<String, Object?>{
        '1': 1,
        '2': null,
      }, const JsonDecodeContext());

      expect(decoded, equals(<int, double?>{1: 1.0, 2: null}));
      expect(
        type.toJson(decoded, const JsonEncodeContext()),
        equals(<String, Object?>{'1': 1.0, '2': null}),
      );
    });

    test('map decode 拒绝非 String JSON key 与解码后的 key 碰撞', () {
      final type = DataforgeTypes.map(
        DataforgeTypes.intType,
        DataforgeTypes.string,
      );

      expect(
        () => type.fromJson(<Object?, Object?>{
          1: 'value',
        }, const JsonDecodeContext()),
        throwsA(isA<DataforgeDecodeException>()),
      );
      final hostileKey = _ThrowingToString();
      expect(
        () => type.fromJson(<Object?, Object?>{
          hostileKey: 'value',
        }, const JsonDecodeContext()),
        throwsA(
          isA<DataforgeDecodeException>()
              .having(
                (error) => error.actualType,
                'actualType',
                '_ThrowingToString',
              )
              .having(
                (error) => error.path,
                'path',
                contains('_ThrowingToString'),
              ),
        ),
      );
      expect(
        () => type.fromJson(<String, Object?>{
          '1': 'first',
          '01': 'second',
        }, const JsonDecodeContext()),
        throwsA(
          isA<DataforgeDecodeException>().having(
            (error) => error.path,
            'path',
            r'$["01"]',
          ),
        ),
      );
    });

    test('decode 与 encode 的集合结果也递归不可修改', () {
      final type = DataforgeTypes.map(
        DataforgeTypes.string,
        DataforgeTypes.list(DataforgeTypes.intType),
      );
      final decoded = type.fromJson(<String, Object?>{
        'values': <Object?>[1, 2],
      }, const JsonDecodeContext());
      final encoded =
          type.toJson(decoded, const JsonEncodeContext())
              as Map<String, Object?>;

      expect(() => decoded['values']!.add(3), throwsA(isA<UnsupportedError>()));
      expect(
        () => encoded['other'] = <Object?>[],
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => (encoded['values']! as List<Object?>).add(3),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('禁止惰性 cast，错误在 fromJson 调用内立即抛出', () {
      final type = DataforgeTypes.list(DataforgeTypes.intType);

      expect(
        () => type.fromJson(<Object?>[
          1,
          'invalid',
          3,
        ], const JsonDecodeContext()),
        throwsA(
          isA<DataforgeDecodeException>().having(
            (error) => error.path,
            'path',
            r'$[1]',
          ),
        ),
      );
    });

    test('嵌套 decode 异常包含完整 JSONPath', () {
      final type = DataforgeTypes.map(
        DataforgeTypes.string,
        DataforgeTypes.list(DataforgeTypes.list(DataforgeTypes.intType)),
      );

      expect(
        () => type.fromJson(<String, Object?>{
          'users': <Object?>[
            <Object?>[1, 'invalid'],
          ],
        }, const JsonDecodeContext()),
        throwsA(
          isA<DataforgeDecodeException>()
              .having((error) => error.path, 'path', r'$.users[0][1]')
              .having(
                (error) => error.toString(),
                'toString',
                contains(r'$.users[0][1]'),
              ),
        ),
      );
    });

    test('map key decode 异常指向具体 key', () {
      final type = DataforgeTypes.map(
        DataforgeTypes.intType,
        DataforgeTypes.string,
      );

      expect(
        () => type.fromJson(<String, Object?>{
          'not-int': 'value',
        }, const JsonDecodeContext()),
        throwsA(
          isA<DataforgeDecodeException>().having(
            (error) => error.path,
            'path',
            r'$["not-int"]',
          ),
        ),
      );
    });

    test('自定义 witness 的 encode 异常保留元素路径与 cause', () {
      final type = DataforgeTypes.list(const _FailingStringType());

      expect(
        () => type.toJson(<String>['ok', 'bad'], const JsonEncodeContext()),
        throwsA(
          isA<DataforgeEncodeException>()
              .having((error) => error.path, 'path', r'$[1]')
              .having((error) => error.cause, 'cause', isA<StateError>()),
        ),
      );
    });

    test('统一字段边界冻结 custom decode 结果并包装顶层异常', () {
      const type = _MutableListType();
      final decoded = dataforgeDecode(type, <Object?>[
        1,
        2,
      ], const JsonDecodeContext().field('values'));

      expect(decoded, equals(<int>[1, 2]));
      expect(() => decoded.add(3), throwsA(isA<UnsupportedError>()));
      expect(
        () => dataforgeDecode(
          const _ThrowingDecodeType(),
          'bad',
          const JsonDecodeContext().field('value'),
        ),
        throwsA(
          isA<DataforgeDecodeException>()
              .having((error) => error.path, 'path', r'$.value')
              .having((error) => error.cause, 'cause', isA<StateError>()),
        ),
      );
      expect(
        () => dataforgeFreeze(
          const _RejectingFreezeIntType(),
          1,
          const JsonDecodeContext().field('defaulted'),
        ),
        throwsA(
          isA<DataforgeDecodeException>()
              .having((error) => error.path, 'path', r'$.defaulted')
              .having((error) => error.cause, 'cause', isA<StateError>()),
        ),
      );
    });

    test('统一字段边界校验 custom 顶层 encode 输出', () {
      expect(
        () => dataforgeEncode(
          const _LooseJsonType(),
          DateTime(2026),
          const JsonEncodeContext().field('value'),
        ),
        throwsA(
          isA<DataforgeEncodeException>().having(
            (error) => error.path,
            'path',
            r'$.value',
          ),
        ),
      );
    });

    test('non-null custom witness 不得编码为 null', () {
      expect(
        () => dataforgeEncode(
          const _NullEncodingIntType(),
          1,
          const JsonEncodeContext().field('value'),
        ),
        throwsA(
          isA<DataforgeEncodeException>()
              .having((error) => error.path, 'path', r'$.value')
              .having(
                (error) => error.message,
                'message',
                contains('non-null value as null'),
              ),
        ),
      );
      expect(
        dataforgeEncode<int?>(
          DataforgeTypes.nullable(DataforgeTypes.intType),
          null,
          const JsonEncodeContext().field('value'),
        ),
        isNull,
      );
    });

    test('自定义 witness 输出会立即校验并递归冻结', () {
      final type = DataforgeTypes.list(const _LooseJsonType());
      final source = <Object?>[
        <String, Object?>{
          'values': <Object?>[1, 2],
        },
      ];

      final encoded =
          type.toJson(<Object?>[source.first], const JsonEncodeContext())
              as List<Object?>;
      (source.first! as Map<String, Object?>)['values'] = <Object?>[9];

      expect(
        encoded,
        equals(<Object?>[
          <String, Object?>{
            'values': <Object?>[1, 2],
          },
        ]),
      );
      expect(
        () => (encoded.first! as Map<String, Object?>)['other'] = 3,
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => type.toJson(<Object?>[DateTime(2026)], const JsonEncodeContext()),
        throwsA(
          isA<DataforgeEncodeException>().having(
            (error) => error.path,
            'path',
            r'$[0]',
          ),
        ),
      );
    });

    test('循环 JSON 输出被拒绝而不是栈溢出', () {
      final cyclic = <Object?>[];
      cyclic.add(cyclic);

      expect(
        () => const JsonEncodeContext().snapshot(cyclic),
        throwsA(
          isA<DataforgeEncodeException>().having(
            (error) => error.path,
            'path',
            r'$[0]',
          ),
        ),
      );
    });

    test('循环 JSON 输入被拒绝而不是栈溢出', () {
      final cyclic = <String, Object?>{};
      cyclic['next'] = cyclic;

      expect(
        () => dataforgeDecode<Object?>(
          const _RecursiveJsonType(),
          cyclic,
          const JsonDecodeContext().field('node'),
        ),
        throwsA(
          isA<DataforgeDecodeException>()
              .having(
                (error) => error.code,
                'code',
                DataforgeJsonErrorCode.cyclicInput,
              )
              .having((error) => error.path, 'path', r'$.node.next'),
        ),
      );
    });

    test('不同 witness 可在同一容器上做有限委托', () {
      expect(
        dataforgeDecode<List<int>>(
          const _DelegatingIntListType(),
          <Object?>[1, 2],
          const JsonDecodeContext().field('values'),
        ),
        [1, 2],
      );
    });

    test('JSON snapshot 拒绝 identity Map 中重复的 String key', () {
      final firstKey = String.fromCharCodes(<int>[107, 101, 121]);
      final secondKey = String.fromCharCodes(<int>[107, 101, 121]);
      final source = HashMap<String, Object?>.identity()
        ..[firstKey] = 1
        ..[secondKey] = 2;
      expect(source, hasLength(2));

      expect(
        () => const JsonEncodeContext().field('payload').snapshot(source),
        throwsA(
          isA<DataforgeEncodeException>().having(
            (error) => error.path,
            'path',
            r'$.payload.key',
          ),
        ),
      );
    });

    test('JSON object 输入正规化 comparator 并拒绝重复 String key', () {
      final firstKey = String.fromCharCodes(<int>[107, 101, 121]);
      final secondKey = String.fromCharCodes(<int>[107, 101, 121]);
      final source = HashMap<String, Object?>.identity()
        ..[firstKey] = 1
        ..[secondKey] = 2;

      expect(
        () => dataforgeNormalizeJsonObject(
          source,
          const JsonDecodeContext().field('payload'),
        ),
        throwsA(
          isA<DataforgeDecodeException>().having(
            (error) => error.path,
            'path',
            r'$.payload.key',
          ),
        ),
      );

      final normalized = dataforgeNormalizeJsonObject(<String, Object?>{
        'key': 1,
      }, const JsonDecodeContext());
      expect(normalized['key'], 1);
      expect(() => normalized['other'] = 2, throwsUnsupportedError);
    });

    test('嵌套 Map decode 在 custom key witness 前拒绝重复 wire key', () {
      final firstKey = String.fromCharCodes(<int>[107, 101, 121]);
      final secondKey = String.fromCharCodes(<int>[107, 101, 121]);
      final source = HashMap<String, Object?>.identity()
        ..[firstKey] = 1
        ..[secondKey] = 2;
      final type = DataforgeTypes.map(
        const _IdentityKeyType(),
        DataforgeTypes.intType,
      );

      expect(
        () => type.fromJson(source, const JsonDecodeContext().field('nested')),
        throwsA(
          isA<DataforgeDecodeException>()
              .having(
                (error) => error.code,
                'code',
                DataforgeJsonErrorCode.duplicateKey,
              )
              .having((error) => error.path, 'path', r'$.nested.key'),
        ),
      );
    });

    test('非有限数值在 encode 时带路径失败', () {
      final context = const JsonEncodeContext().field('score');

      expect(
        () => DataforgeTypes.doubleType.toJson(double.nan, context),
        throwsA(
          isA<DataforgeEncodeException>().having(
            (error) => error.path,
            'path',
            r'$.score',
          ),
        ),
      );
    });
  });
}

enum _RuntimeState { ready, done }

enum _OtherRuntimeState { ready, done }

final class _CaseInsensitiveStringType implements DataforgeType<String> {
  const _CaseInsensitiveStringType();

  @override
  String freeze(String value) => value;

  @override
  bool equals(String left, String right) =>
      left.toLowerCase() == right.toLowerCase();

  @override
  int hash(String value) => value.toLowerCase().hashCode;

  @override
  String fromJson(Object? json, JsonDecodeContext context) {
    if (json is String) return json;
    return context.fail('Expected String.');
  }

  @override
  Object? toJson(String value, JsonEncodeContext context) => value;
}

final class _NonConstCaseInsensitiveStringType
    implements DataforgeType<String> {
  @override
  String freeze(String value) => value;

  @override
  bool equals(String left, String right) =>
      left.toLowerCase() == right.toLowerCase();

  @override
  int hash(String value) => value.toLowerCase().hashCode;

  @override
  String fromJson(Object? json, JsonDecodeContext context) {
    if (json is String) return json;
    return context.fail('Expected String.');
  }

  @override
  Object? toJson(String value, JsonEncodeContext context) => value;
}

final class _IdentityKey {
  const _IdentityKey(this.value);

  final String value;
}

final class _IdentityKeyType implements DataforgeType<_IdentityKey> {
  const _IdentityKeyType();

  @override
  _IdentityKey freeze(_IdentityKey value) => value;

  @override
  bool equals(_IdentityKey left, _IdentityKey right) => identical(left, right);

  @override
  int hash(_IdentityKey value) => identityHashCode(value);

  @override
  _IdentityKey fromJson(Object? json, JsonDecodeContext context) {
    if (json is String) return _IdentityKey(json);
    return context.fail('Expected String.');
  }

  @override
  Object? toJson(_IdentityKey value, JsonEncodeContext context) => value.value;
}

final class _LooseJsonType implements DataforgeType<Object?> {
  const _LooseJsonType();

  @override
  Object? freeze(Object? value) => value;

  @override
  bool equals(Object? left, Object? right) => left == right;

  @override
  int hash(Object? value) => value.hashCode;

  @override
  Object? fromJson(Object? json, JsonDecodeContext context) => json;

  @override
  Object? toJson(Object? value, JsonEncodeContext context) => value;
}

final class _RecursiveJsonType implements DataforgeType<Object?> {
  const _RecursiveJsonType();

  @override
  Object? freeze(Object? value) => value;

  @override
  bool equals(Object? left, Object? right) => identical(left, right);

  @override
  int hash(Object? value) => identityHashCode(value);

  @override
  Object? fromJson(Object? json, JsonDecodeContext context) {
    if (json == null) return null;
    if (json is! Map<String, Object?>) {
      return context.fail(
        'Expected recursive JSON object.',
        expectedType: 'Map<String, Object?>',
        actualType: dataforgeJsonActualType(json),
      );
    }
    return dataforgeDecode<Object?>(this, json['next'], context.field('next'));
  }

  @override
  Object? toJson(Object? value, JsonEncodeContext context) => value;
}

final class _DelegatingIntListType implements DataforgeType<List<int>> {
  const _DelegatingIntListType([this.remainingDelegations = 1]);

  final int remainingDelegations;

  static final DataforgeType<List<int>> _delegate = DataforgeTypes.list(
    DataforgeTypes.intType,
  );

  @override
  List<int> freeze(List<int> value) => _delegate.freeze(value);

  @override
  bool equals(List<int> left, List<int> right) => _delegate.equals(left, right);

  @override
  int hash(List<int> value) => _delegate.hash(value);

  @override
  List<int> fromJson(Object? json, JsonDecodeContext context) =>
      remainingDelegations == 0
      ? dataforgeDecode(_delegate, json, context)
      : dataforgeDecode(
          _DelegatingIntListType(remainingDelegations - 1),
          json,
          context,
        );

  @override
  Object? toJson(List<int> value, JsonEncodeContext context) =>
      dataforgeEncode(_delegate, value, context);
}

final class _FailingStringType implements DataforgeType<String> {
  const _FailingStringType();

  @override
  String freeze(String value) => value;

  @override
  bool equals(String left, String right) => left == right;

  @override
  int hash(String value) => value.hashCode;

  @override
  String fromJson(Object? json, JsonDecodeContext context) {
    if (json is String) return json;
    return context.fail('Expected String.');
  }

  @override
  Object? toJson(String value, JsonEncodeContext context) {
    if (value == 'bad') throw StateError('cannot encode bad');
    return value;
  }
}

final class _MutableListType implements DataforgeType<List<int>> {
  const _MutableListType();

  @override
  List<int> freeze(List<int> value) => List<int>.unmodifiable(value);

  @override
  bool equals(List<int> left, List<int> right) =>
      DataforgeTypes.list(DataforgeTypes.intType).equals(left, right);

  @override
  int hash(List<int> value) =>
      DataforgeTypes.list(DataforgeTypes.intType).hash(value);

  @override
  List<int> fromJson(Object? json, JsonDecodeContext context) {
    if (json is! List) return context.fail('Expected List.');
    return json.cast<int>().toList();
  }

  @override
  Object? toJson(List<int> value, JsonEncodeContext context) => value;
}

final class _ThrowingDecodeType implements DataforgeType<int> {
  const _ThrowingDecodeType();

  @override
  int freeze(int value) => value;

  @override
  bool equals(int left, int right) => left == right;

  @override
  int hash(int value) => value.hashCode;

  @override
  int fromJson(Object? json, JsonDecodeContext context) {
    throw StateError('cannot decode');
  }

  @override
  Object? toJson(int value, JsonEncodeContext context) => value;
}

final class _NullEncodingIntType implements DataforgeType<int> {
  const _NullEncodingIntType();

  @override
  int freeze(int value) => value;

  @override
  bool equals(int left, int right) => left == right;

  @override
  int hash(int value) => value.hashCode;

  @override
  int fromJson(Object? json, JsonDecodeContext context) {
    if (json is int) return json;
    return context.fail('Expected int.');
  }

  @override
  Object? toJson(int value, JsonEncodeContext context) => null;
}

final class _RejectingFreezeIntType implements DataforgeType<int> {
  const _RejectingFreezeIntType();

  @override
  int freeze(int value) => throw StateError('cannot freeze');

  @override
  bool equals(int left, int right) => left == right;

  @override
  int hash(int value) => value.hashCode;

  @override
  int fromJson(Object? json, JsonDecodeContext context) => 1;

  @override
  Object? toJson(int value, JsonEncodeContext context) => value;
}

final class _ThrowingToString {
  @override
  String toString() => throw StateError('must not be called for JSONPath');
}
