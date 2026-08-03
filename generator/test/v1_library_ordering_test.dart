import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:dataforge/builder.dart';
import 'package:test/test.dart';

void main() {
  test('v1 models are ordered by source URI and offset across parts', () async {
    await testBuilder(
      dataforgeBuilder(BuilderOptions.empty),
      {
        'dataforge|lib/models.dart': _orderedLibrary,
        'dataforge|lib/a_part.dart': _orderedPart,
        'dataforge_annotation|lib/dataforge_annotation.dart':
            _annotationLibrary,
        'dataforge_annotation|lib/src/annotation.dart': _annotationSource,
        'dataforge_annotation|lib/src/runtime.dart': _runtimeSource,
      },
      generateFor: {'dataforge|lib/models.dart'},
      outputs: {
        'dataforge|lib/models.data.dart': decodedMatches(
          predicate<String>((source) {
            final partIndex = source.indexOf('final class _PartModel');
            final alphaIndex = source.indexOf('final class _Alpha');
            return partIndex >= 0 && alphaIndex >= 0 && partIndex < alphaIndex;
          }, 'emits the lexically earlier part model first'),
        ),
      },
      rootPackage: 'dataforge',
    );
  });

  test('a concrete declaration is rejected', () async {
    final logs = <String>[];

    await testBuilder(
      dataforgeBuilder(BuilderOptions.empty),
      {
        'dataforge|lib/concrete.dart': _concreteLibrary,
        'dataforge_annotation|lib/dataforge_annotation.dart':
            _annotationLibrary,
        'dataforge_annotation|lib/src/annotation.dart': _annotationSource,
        'dataforge_annotation|lib/src/runtime.dart': _runtimeSource,
      },
      generateFor: {'dataforge|lib/concrete.dart'},
      outputs: const {},
      onLog: (record) => logs.add(record.toString()),
      rootPackage: 'dataforge',
    );

    expect(logs, contains(contains('abstract final')));
  });

  test(
    'duplicate Dataforge names are rejected by the shared v1 frontend',
    () async {
      final logs = <String>[];

      await testBuilder(
        dataforgeBuilder(BuilderOptions.empty),
        {
          'dataforge|lib/collision.dart': _collisionLibrary,
          'dataforge_annotation|lib/dataforge_annotation.dart':
              _annotationLibrary,
          'dataforge_annotation|lib/src/annotation.dart': _annotationSource,
          'dataforge_annotation|lib/src/runtime.dart': _runtimeSource,
        },
        generateFor: {'dataforge|lib/collision.dart'},
        outputs: const {},
        onLog: (record) => logs.add(record.toString()),
        rootPackage: 'dataforge',
      );

      final message = logs.join('\n');
      expect(message, contains('DF1001'));
      expect(message, contains('library.generatedSymbols'));
    },
  );

  test(
    'supported facade enriches writer diagnostics with source location',
    () async {
      final logs = <String>[];

      await testBuilder(
        dataforgeBuilder(BuilderOptions.empty),
        {
          'dataforge|lib/writer_location.dart': _writerLocationLibrary,
          'dataforge_annotation|lib/dataforge_annotation.dart':
              _annotationLibrary,
          'dataforge_annotation|lib/src/annotation.dart': _annotationSource,
          'dataforge_annotation|lib/src/runtime.dart': _runtimeSource,
        },
        generateFor: {'dataforge|lib/writer_location.dart'},
        outputs: const {},
        onLog: (record) => logs.add(record.toString()),
        rootPackage: 'dataforge',
      );

      final message = logs.join('\n');
      expect(message, contains('DF1001'));
      expect(message, contains('hashCode'));
      expect(
        message,
        matches(RegExp(r'package:dataforge/writer_location\.dart:8:\d+')),
      );
    },
  );

  test(
    'generation preserves enum prefixes, typedef aliases and barrel companions',
    () async {
      await testBuilder(
        dataforgeBuilder(BuilderOptions.empty),
        {
          'dataforge|lib/symbols.dart': _symbolConsumerLibrary,
          'dataforge|lib/domain.dart': _symbolDomainLibrary,
          'dataforge|lib/types.dart': _symbolTypedefLibrary,
          'dataforge|lib/domain_barrel.dart': _symbolBarrelLibrary,
          'dataforge_annotation|lib/dataforge_annotation.dart':
              _annotationLibrary,
          'dataforge_annotation|lib/src/annotation.dart': _annotationSource,
          'dataforge_annotation|lib/src/runtime.dart': _runtimeSource,
        },
        generateFor: {'dataforge|lib/symbols.dart'},
        outputs: {
          'dataforge|lib/symbols.data.dart': decodedMatches(
            allOf(
              contains('values.Status'),
              contains('types.PublicMoney'),
              contains('api.Address'),
              contains(r'api.$AddressType'),
            ),
          ),
        },
        rootPackage: 'dataforge',
      );
    },
  );
}

const _orderedLibrary = r'''
import 'package:dataforge_annotation/dataforge_annotation.dart' as df;

part 'a_part.dart';
part 'models.data.dart';

@df.Dataforge()
abstract final class Alpha with _$Alpha {
  const Alpha._();

  factory Alpha({required String id}) = _Alpha;

  factory Alpha.fromJson(Map<String, Object?> json) = _Alpha.fromJson;
}
''';

const _annotationLibrary = r'''
export 'src/annotation.dart';
export 'src/runtime.dart';
''';

const _annotationSource = r'''
class Dataforge {
  final String name;
  final bool includeFromJson;
  final bool includeToJson;

  const Dataforge({
    this.name = '',
    this.includeFromJson = true,
    this.includeToJson = true,
  });
}

class JsonKey {
  const JsonKey();
}

class DataforgeDefault {
  final Object? value;

  const DataforgeDefault(this.value);
}
''';

const _runtimeSource = r'''
abstract interface class DataforgeType<T> {}

final class DataforgeTypes {}

abstract interface class DataforgeTypeIdentity {}

abstract interface class DataforgeTypeErasedEquality {}

abstract final class DataforgeJsonErrorCode {}

final class JsonDecodeContext {}

final class JsonEncodeContext {}

Object? dataforgeDecode(Object? value) => value;

Object? dataforgeFreeze(Object? value) => value;

Map<String, Object?> dataforgeNormalizeJsonObject(Object? value) => const {};

String dataforgeJsonActualType(Object? value) => 'Object';

Object? dataforgeEncode(Object? value) => value;

bool dataforgeTypeEquals(Object? left, Object? right) => left == right;

int dataforgeTypeHash(Object? value) => value.hashCode;

bool dataforgeValueEquals(
  Object? leftType,
  Object? rightType,
  Object? left,
  Object? right,
) => left == right;
''';

const _orderedPart = r'''
part of 'models.dart';

@df.Dataforge()
abstract final class PartModel with _$PartModel {
  const PartModel._();

  factory PartModel({required String id}) = _PartModel;

  factory PartModel.fromJson(Map<String, Object?> json) = _PartModel.fromJson;
}
''';

const _concreteLibrary = r'''
import 'package:dataforge_annotation/dataforge_annotation.dart' as df;

part 'concrete.data.dart';

@df.Dataforge()
class Concrete {
  final String id;

  const Concrete({required this.id});
}
''';

const _collisionLibrary = r'''
import 'package:dataforge_annotation/dataforge_annotation.dart' as df;

part 'collision.data.dart';

@df.Dataforge(name: 'Shared')
abstract final class CollisionA with _$Shared {
  const CollisionA._();
  factory CollisionA({required int value}) = _Shared;
  factory CollisionA.fromJson(Map<String, Object?> json) = _Shared.fromJson;
}

@df.Dataforge(name: 'Shared')
abstract final class CollisionB with _$Shared {
  const CollisionB._();
  factory CollisionB({required int value}) = _Shared;
  factory CollisionB.fromJson(Map<String, Object?> json) = _Shared.fromJson;
}
''';

const _writerLocationLibrary = r'''
import 'package:dataforge_annotation/dataforge_annotation.dart' as df;

part 'writer_location.data.dart';

@df.Dataforge(includeFromJson: false, includeToJson: false)
abstract final class WriterLocation with _$WriterLocation {
  const WriterLocation._();
  factory WriterLocation({required int hashCode}) = _WriterLocation;
}
''';

const _symbolDomainLibrary = r'''
import 'package:dataforge_annotation/dataforge_annotation.dart' as df;

enum Status { ready, done }

class Money {
  const Money();
}

@df.Dataforge()
abstract final class Address with _$Address {
  const Address._();
  factory Address({required String city}) = _Address;
  factory Address.fromJson(Map<String, Object?> json) = _Address.fromJson;
}
''';

const _symbolTypedefLibrary = r'''
import 'domain.dart';

typedef PublicMoney = Money;
''';

const _symbolBarrelLibrary = r'''
export 'domain.dart' show Address, $AddressType;
''';

const _symbolConsumerLibrary = r'''
import 'package:dataforge_annotation/dataforge_annotation.dart' as df;
import 'domain.dart' as values show Status;
import 'types.dart' as types show PublicMoney;
import 'domain_barrel.dart' as api;

part 'symbols.data.dart';

@df.Dataforge(includeFromJson: false, includeToJson: false)
abstract final class SymbolConsumer with _$SymbolConsumer {
  const SymbolConsumer._();
  factory SymbolConsumer({
    required df.DataforgeType<types.PublicMoney> moneyType,
    required values.Status status,
    required types.PublicMoney money,
    required api.Address address,
  }) = _SymbolConsumer;
}
''';
