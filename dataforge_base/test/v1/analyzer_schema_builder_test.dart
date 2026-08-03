import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:dataforge_base/src/v1/analyzer_schema_builder.dart';
import 'package:dataforge_base/src/v1/diagnostics.dart';
import 'package:dataforge_base/src/v1/schema.dart';
import 'package:dataforge_base/src/v1/writer.dart';
import 'package:test/test.dart';

const _annotationsSource = r'''
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
  final String name;
  final List<String> alternateNames;
  final bool ignore;
  final bool? includeIfNull;

  const JsonKey({
    this.name = '',
    this.alternateNames = const [],
    this.ignore = false,
    this.includeIfNull,
  });
}

class DataforgeDefault {
  final Object? value;
  const DataforgeDefault(this.value);
}

abstract interface class DataforgeType<T> {
  const DataforgeType();
}
abstract interface class DataforgeTypeIdentity {}
abstract interface class DataforgeTypeErasedEquality {}

final class DataforgeTypes {}
abstract final class DataforgeJsonErrorCode {}
final class JsonDecodeContext {}
final class JsonEncodeContext {}
T dataforgeDecode<T>(DataforgeType<T> type, Object? json, Object context) =>
    throw UnimplementedError();
T dataforgeFreeze<T>(DataforgeType<T> type, T value, Object context) =>
    throw UnimplementedError();
Map<String, Object?> dataforgeNormalizeJsonObject(
  Map<String, Object?> json,
  Object context,
) => json;
String dataforgeJsonActualType(Object? value) => 'Object';
Object? dataforgeEncode<T>(DataforgeType<T> type, T value, Object context) =>
    throw UnimplementedError();
bool dataforgeTypeEquals(
  DataforgeType<dynamic> left,
  DataforgeType<dynamic> right,
) => false;
int dataforgeTypeHash(DataforgeType<dynamic> type) => 0;
bool dataforgeValueEquals(
  DataforgeType<dynamic> leftType,
  DataforgeType<dynamic> rightType,
  Object? left,
  Object? right,
) => false;
''';

const _externalSource = r'''
import 'annotations.dart';

enum Status { active, disabled }

class Money {
  final int cents;
  const Money(this.cents);
}

class Codec<T> {
  final T value;
  const Codec(this.value);
}

@Dataforge()
abstract final class Address with _$Address {
  const Address._();
  factory Address({required String city}) = _Address;
  factory Address.fromJson(Map<String, Object?> json) = _Address.fromJson;
}

@Dataforge()
abstract final class WitnessTarget<T> with _$WitnessTarget<T> {
  const WitnessTarget._();
  factory WitnessTarget({
    required DataforgeType<T> type,
    required DataforgeType<Map<String, Set<T?>>> compositeType,
    required DataforgeType<Codec<T>> codecType,
    required T value,
    required Map<String, Set<T?>> composite,
    required Codec<T> codec,
  }) = _WitnessTarget<T>;
  factory WitnessTarget.fromJson(
    Map<String, Object?> json, {
    required DataforgeType<T> type,
    required DataforgeType<Map<String, Set<T?>>> compositeType,
    required DataforgeType<Codec<T>> codecType,
  }) = _WitnessTarget<T>.fromJson;
}

@Dataforge()
abstract final class NestedWitnessTarget<T> with _$NestedWitnessTarget<T> {
  const NestedWitnessTarget._();
  factory NestedWitnessTarget({
    required DataforgeType<WitnessTarget<List<T>>> targetType,
    required WitnessTarget<List<T>> target,
  }) = _NestedWitnessTarget<T>;
  factory NestedWitnessTarget.fromJson(
    Map<String, Object?> json, {
    required DataforgeType<WitnessTarget<List<T>>> targetType,
  }) = _NestedWitnessTarget<T>.fromJson;
}
''';

const _modelsSource = r'''
import 'annotations.dart' as df;
import 'external.dart' as api;

part 'models.data.dart';

@df.Dataforge(
  name: 'StoredUser',
  includeFromJson: false,
  includeToJson: false,
)
abstract final class User<T extends num> with _$StoredUser<T> {
  const User._();

  factory User({
    required df.DataforgeType<T> type,
    required df.DataforgeType<api.Money> moneyType,
    required df.DataforgeType<api.Codec<api.Money>> moneyCodecType,
    required df.DataforgeType<api.Codec<List<api.Money>>> moneyListCodecType,
    required T value,
    @df.JsonKey(
      name: 'created_at',
      alternateNames: ['createdAt'],
      includeIfNull: false,
    )
    required DateTime? createdAt,
    required Duration elapsed,
    required api.Status status,
    required api.Address address,
    required List<Map<String, Set<api.Address?>>> nested,
    required (int, {api.Status status}) record,
    required api.Money money,
    required api.WitnessTarget<api.Money> witnessTarget,
    required api.NestedWitnessTarget<api.Money> nestedWitnessTarget,
    @df.DataforgeDefault(3) int retries,
    @df.DataforgeDefault(const <String>[]) List<String> tags,
    @df.DataforgeDefault(const <String>{}) Set<String> flags,
    @df.DataforgeDefault(const <String, int>{}) Map<String, int> counts,
    @df.DataforgeDefault(null) String? note,
  }) = _StoredUser<T>;

}

@df.Dataforge()
abstract final class Existing with _$Existing {
  const Existing._();
  factory Existing({
    @df.DataforgeDefault('fallback') String label,
  }) = _Existing;
  factory Existing.fromJson(Map<String, Object?> json) = _Existing.fromJson;
}

@df.Dataforge()
class Concrete {
  final int value;
  const Concrete(this.value);
}
''';

const _modelsGeneratedSource = r'''
part of 'models.dart';

final class _Existing extends Existing {
  _Existing({this.label = 'fallback'}) : super._();
  @override
  final String label;
}
''';

const _invalidModelsSource = r'''
import 'annotations.dart';
import 'external.dart';

@Dataforge()
class NotAbstractFinal with _$NotAbstractFinal {
  const NotAbstractFinal._();
  factory NotAbstractFinal({required int value}) = _NotAbstractFinal;
  factory NotAbstractFinal.fromJson(Map<String, Object?> json) =
      _NotAbstractFinal.fromJson;
}

@Dataforge()
abstract final class MissingFactory with _$MissingFactory {
  const MissingFactory._();
  factory MissingFactory.fromJson(Map<String, Object?> json) =
      _MissingFactory.fromJson;
}

@Dataforge()
abstract final class MissingMixin {
  const MissingMixin._();
  factory MissingMixin({required int value}) = _MissingMixin;
  factory MissingMixin.fromJson(Map<String, Object?> json) =
      _MissingMixin.fromJson;
}

@Dataforge()
abstract final class WrongFromJson with _$WrongFromJson {
  const WrongFromJson._();
  factory WrongFromJson({required int value}) = _WrongFromJson;
  factory WrongFromJson.fromJson(Map<String, dynamic> json) =
      _OtherFromJson.fromJson;
}

@Dataforge()
abstract final class WrongName with _$WrongName {
  const WrongName._();
  factory WrongName({required int value}) = _OtherName;
  factory WrongName.fromJson(Map<String, Object?> json) = _WrongName.fromJson;
}

@Dataforge()
abstract final class Positional with _$Positional {
  const Positional._();
  factory Positional(int value) = _Positional;
  factory Positional.fromJson(Map<String, Object?> json) =
      _Positional.fromJson;
}

@Dataforge()
abstract final class Unsupported with _$Unsupported {
  const Unsupported._();
  factory Unsupported({
    required dynamic dynamicValue,
    required Object? objectValue,
    required void Function() callback,
    required Future<int> future,
  }) = _Unsupported;
  factory Unsupported.fromJson(Map<String, Object?> json) =
      _Unsupported.fromJson;
}

@Dataforge()
abstract final class Mutable with _$Mutable {
  const Mutable._();
  factory Mutable({required int value}) = _Mutable;
  factory Mutable.fromJson(Map<String, Object?> json) = _Mutable.fromJson;
  final int illegal = 0;
}

@Dataforge()
abstract final class NoBase with _$NoBase {
  factory NoBase({required int value}) = _NoBase;
  factory NoBase.fromJson(Map<String, Object?> json) = _NoBase.fromJson;
}

@Dataforge()
abstract final class ExtraSubtype with _$ExtraSubtype {
  const ExtraSubtype._();
  factory ExtraSubtype({required int value}) = _ExtraSubtype;
  factory ExtraSubtype.fromJson(Map<String, Object?> json) =
      _ExtraSubtype.fromJson;
}

final class HandwrittenSubtype extends ExtraSubtype {
  const HandwrittenSubtype() : super._();
}

@Dataforge()
abstract final class WitnessProblems<T> with _$WitnessProblems<T> {
  const WitnessProblems._();
  factory WitnessProblems({
    required DataforgeType<T> first,
    required DataforgeType<T> second,
    required DataforgeType<Uri> extra,
    required T value,
    required Money money,
  }) = _WitnessProblems<T>;
  factory WitnessProblems.fromJson(
    Map<String, Object?> json, {
    required DataforgeType<T> first,
    required DataforgeType<T> second,
    required DataforgeType<Uri> extra,
  }) = _WitnessProblems<T>.fromJson;
}

@Dataforge()
abstract final class IgnoredWithoutDefault with _$IgnoredWithoutDefault {
  const IgnoredWithoutDefault._();
  factory IgnoredWithoutDefault({
    @JsonKey(ignore: true) String? hidden,
  }) = _IgnoredWithoutDefault;
  factory IgnoredWithoutDefault.fromJson(Map<String, Object?> json) =
      _IgnoredWithoutDefault.fromJson;
}

@Dataforge()
abstract final class UnsupportedDefault with _$UnsupportedDefault {
  const UnsupportedDefault._();
  factory UnsupportedDefault({
    @DataforgeDefault(Duration(seconds: 1)) Duration timeout,
  }) = _UnsupportedDefault;
  factory UnsupportedDefault.fromJson(Map<String, Object?> json) =
      _UnsupportedDefault.fromJson;
}

@Dataforge()
abstract final class MissingNestedWitness with _$MissingNestedWitness {
  const MissingNestedWitness._();
  factory MissingNestedWitness({
    required DataforgeType<Money> moneyType,
    required NestedWitnessTarget<Money> target,
  }) = _MissingNestedWitness;
  factory MissingNestedWitness.fromJson(
    Map<String, Object?> json, {
    required DataforgeType<Money> moneyType,
  }) = _MissingNestedWitness.fromJson;
}
''';

const _cyclicModelsSource = r'''
import 'annotations.dart';

@Dataforge()
abstract final class CycleA<T> with _$CycleA<T> {
  const CycleA._();
  factory CycleA({
    required DataforgeType<CycleB<List<T>>> type,
    required CycleB<List<T>> value,
  }) = _CycleA<T>;
  factory CycleA.fromJson(
    Map<String, Object?> json, {
    required DataforgeType<CycleB<List<T>>> type,
  }) = _CycleA<T>.fromJson;
}

@Dataforge()
abstract final class CycleB<T> with _$CycleB<T> {
  const CycleB._();
  factory CycleB({
    required DataforgeType<CycleA<List<T>>> type,
    required CycleA<List<T>> value,
  }) = _CycleB<T>;
  factory CycleB.fromJson(
    Map<String, Object?> json, {
    required DataforgeType<CycleA<List<T>>> type,
  }) = _CycleB<T>.fromJson;
}

@Dataforge(includeFromJson: false, includeToJson: false)
abstract final class CycleHolder with _$CycleHolder {
  const CycleHolder._();
  factory CycleHolder({required CycleA<int> value}) = _CycleHolder;
}

@Dataforge()
abstract final class ChangingNode<T> with _$ChangingNode<T> {
  const ChangingNode._();
  factory ChangingNode({
    required DataforgeType<T> type,
    required ChangingNode<List<T>>? child,
    required T value,
  }) = _ChangingNode<T>;
  factory ChangingNode.fromJson(
    Map<String, Object?> json, {
    required DataforgeType<T> type,
  }) = _ChangingNode<T>.fromJson;
}
''';

const _hiddenRuntimeSource = r'''
import 'annotations.dart' show Dataforge;

@Dataforge()
abstract final class HiddenRuntime with _$HiddenRuntime {
  const HiddenRuntime._();
  factory HiddenRuntime({required int value}) = _HiddenRuntime;
  factory HiddenRuntime.fromJson(Map<String, Object?> json) =
      _HiddenRuntime.fromJson;
}
''';

const _separateRuntimePrefixSource = r'''
import 'annotations.dart' show Dataforge;
import 'annotations.dart' as runtime;

@Dataforge()
abstract final class SeparateRuntimePrefix with _$SeparateRuntimePrefix {
  const SeparateRuntimePrefix._();
  factory SeparateRuntimePrefix({required int value}) =
      _SeparateRuntimePrefix;
  factory SeparateRuntimePrefix.fromJson(Map<String, Object?> json) =
      _SeparateRuntimePrefix.fromJson;
}
''';

const _hiddenModelCompanionSource = r'''
import 'annotations.dart' as df;
import 'external.dart' show Address;

@df.Dataforge()
abstract final class HiddenModelCompanion with _$HiddenModelCompanion {
  const HiddenModelCompanion._();
  factory HiddenModelCompanion({required Address address}) =
      _HiddenModelCompanion;
  factory HiddenModelCompanion.fromJson(Map<String, Object?> json) =
      _HiddenModelCompanion.fromJson;
}
''';

const _exactHiddenModelCompanionSource = r'''
import 'annotations.dart' as df;
import 'external.dart' show Address;

@df.Dataforge(includeFromJson: false, includeToJson: false)
abstract final class ExactHiddenModelCompanion
    with _$ExactHiddenModelCompanion {
  const ExactHiddenModelCompanion._();
  factory ExactHiddenModelCompanion({
    required df.DataforgeType<Address> addressType,
    required Address address,
  }) = _ExactHiddenModelCompanion;
}
''';

const _hiddenModelBoundSource = r'''
import 'annotations.dart' as df;
import 'external.dart' show Address;

@df.Dataforge(includeFromJson: false, includeToJson: false)
abstract final class HiddenModelBound<T extends Address>
    with _$HiddenModelBound<T> {
  const HiddenModelBound._();
  factory HiddenModelBound({
    required df.DataforgeType<T> type,
    required T value,
  }) = _HiddenModelBound<T>;
}
''';

const _hiddenPrefixedModelCompanionSource = r'''
import 'annotations.dart' as df;
import 'external.dart' as api show Address;

@df.Dataforge()
abstract final class HiddenPrefixedModelCompanion
    with _$HiddenPrefixedModelCompanion {
  const HiddenPrefixedModelCompanion._();
  factory HiddenPrefixedModelCompanion({required api.Address address}) =
      _HiddenPrefixedModelCompanion;
  factory HiddenPrefixedModelCompanion.fromJson(Map<String, Object?> json) =
      _HiddenPrefixedModelCompanion.fromJson;
}
''';

const _separateModelPrefixSource = r'''
import 'annotations.dart' as df;
import 'external.dart' show Address;
import 'external.dart' as api;

@df.Dataforge()
abstract final class SeparateModelPrefix with _$SeparateModelPrefix {
  const SeparateModelPrefix._();
  factory SeparateModelPrefix({required Address address}) =
      _SeparateModelPrefix;
  factory SeparateModelPrefix.fromJson(Map<String, Object?> json) =
      _SeparateModelPrefix.fromJson;
}
''';

const _onlyPrefixedEnumSource = r'''
import 'annotations.dart' as df;
import 'external.dart' as values show Status;

@df.Dataforge()
abstract final class EnumOnly with _$EnumOnly {
  const EnumOnly._();
  factory EnumOnly({required values.Status status}) = _EnumOnly;
  factory EnumOnly.fromJson(Map<String, Object?> json) = _EnumOnly.fromJson;
}
''';

const _dualPrefixedEnumSource = r'''
import 'annotations.dart' as df;
import 'external.dart' as a show Status;
import 'external.dart' as z show Status;

@df.Dataforge()
abstract final class DualPrefixEnum with _$DualPrefixEnum {
  const DualPrefixEnum._();
  factory DualPrefixEnum({required z.Status a}) = _DualPrefixEnum;
  factory DualPrefixEnum.fromJson(Map<String, Object?> json) =
      _DualPrefixEnum.fromJson;
}
''';

const _fullModelBarrelSource = r'''
export 'external.dart' show Address, $AddressType;
''';

const _shownModelOnlyBarrelSource = r'''
export 'external.dart' show Address;
''';

const _hiddenModelCompanionBarrelSource = r'''
export 'external.dart' hide $AddressType;
''';

const _fullReexportModelSource = r'''
import 'annotations.dart' as df;
import 'full_model_barrel.dart' as api;

@df.Dataforge()
abstract final class FullReexportModel with _$FullReexportModel {
  const FullReexportModel._();
  factory FullReexportModel({required api.Address address}) =
      _FullReexportModel;
  factory FullReexportModel.fromJson(Map<String, Object?> json) =
      _FullReexportModel.fromJson;
}
''';

const _shownModelOnlyReexportSource = r'''
import 'annotations.dart' as df;
import 'shown_model_only_barrel.dart' as api;

@df.Dataforge()
abstract final class ShownModelOnlyReexport
    with _$ShownModelOnlyReexport {
  const ShownModelOnlyReexport._();
  factory ShownModelOnlyReexport({required api.Address address}) =
      _ShownModelOnlyReexport;
  factory ShownModelOnlyReexport.fromJson(Map<String, Object?> json) =
      _ShownModelOnlyReexport.fromJson;
}
''';

const _hiddenModelCompanionReexportSource = r'''
import 'annotations.dart' as df;
import 'hidden_model_companion_barrel.dart' as api;

@df.Dataforge()
abstract final class HiddenModelCompanionReexport
    with _$HiddenModelCompanionReexport {
  const HiddenModelCompanionReexport._();
  factory HiddenModelCompanionReexport({required api.Address address}) =
      _HiddenModelCompanionReexport;
  factory HiddenModelCompanionReexport.fromJson(Map<String, Object?> json) =
      _HiddenModelCompanionReexport.fromJson;
}
''';

const _typedefTypesSource = r'''
import 'external.dart';

typedef PublicMoney = Money;
typedef StatusAlias = Status;
''';

const _typedefOnlyModelSource = r'''
import 'annotations.dart' as df;
import 'typedef_types.dart' as values show PublicMoney;

@df.Dataforge(includeFromJson: false, includeToJson: false)
abstract final class TypedefOnlyModel with _$TypedefOnlyModel {
  const TypedefOnlyModel._();
  factory TypedefOnlyModel({
    required df.DataforgeType<values.PublicMoney> moneyType,
    required values.PublicMoney money,
  }) = _TypedefOnlyModel;
}
''';

const _defaultTypeSource = r'''
import 'annotations.dart' as df;
import 'external.dart' as values show Status;
import 'typedef_types.dart' as aliases show StatusAlias;

@df.Dataforge()
abstract final class InvalidDefaultType with _$InvalidDefaultType {
  const InvalidDefaultType._();
  factory InvalidDefaultType({
    @df.DataforgeDefault('wrong') int count,
    @df.DataforgeDefault(9007199254740993) double imprecise,
    @df.DataforgeDefault(<dynamic>[]) List<String> dynamicItems,
  }) = _InvalidDefaultType;
  factory InvalidDefaultType.fromJson(Map<String, Object?> json) =
      _InvalidDefaultType.fromJson;
}

@df.Dataforge()
abstract final class ContextualDefaults with _$ContextualDefaults {
  const ContextualDefaults._();
  factory ContextualDefaults({
    @df.DataforgeDefault(1) double ratio,
    @df.DataforgeDefault(<String>[]) List<String> labels,
  }) = _ContextualDefaults;
  factory ContextualDefaults.fromJson(Map<String, Object?> json) =
      _ContextualDefaults.fromJson;
}

@df.Dataforge()
abstract final class PrefixedEnumDefault with _$PrefixedEnumDefault {
  const PrefixedEnumDefault._();
  factory PrefixedEnumDefault({
    @df.DataforgeDefault(values.Status.active) values.Status status,
  }) = _PrefixedEnumDefault;
  factory PrefixedEnumDefault.fromJson(Map<String, Object?> json) =
      _PrefixedEnumDefault.fromJson;
}

@df.Dataforge()
abstract final class TypedefEnumDefault with _$TypedefEnumDefault {
  const TypedefEnumDefault._();
  factory TypedefEnumDefault({
    @df.DataforgeDefault(aliases.StatusAlias.disabled)
    aliases.StatusAlias status,
  }) = _TypedefEnumDefault;
  factory TypedefEnumDefault.fromJson(Map<String, Object?> json) =
      _TypedefEnumDefault.fromJson;
}
''';

const _collisionSource = r'''
import 'annotations.dart' as df;

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

@df.Dataforge(name: r'$SelfCollisionDataforgeType')
abstract final class SelfCollision with _$$SelfCollisionDataforgeType {
  const SelfCollision._();
  factory SelfCollision({required int value}) = _$SelfCollisionDataforgeType;
  factory SelfCollision.fromJson(Map<String, Object?> json) =
      _$SelfCollisionDataforgeType.fromJson;
}

@df.Dataforge(includeFromJson: false, includeToJson: false)
abstract final class RecordOwner with _$RecordOwner {
  const RecordOwner._();
  factory RecordOwner({required (int,) value}) = _RecordOwner;
}

@df.Dataforge(
  name: r'$RecordOwnerRecordDataforgeType0',
  includeFromJson: false,
  includeToJson: false,
)
abstract final class RecordCollision
    with _$$RecordOwnerRecordDataforgeType0 {
  const RecordCollision._();
  factory RecordCollision({required int value}) =
      _$RecordOwnerRecordDataforgeType0;
}

@df.Dataforge(includeFromJson: false, includeToJson: false)
abstract final class RecordBox<T> with _$RecordBox<T> {
  const RecordBox._();
  factory RecordBox({
    required df.DataforgeType<T> type,
    required T value,
  }) = _RecordBox<T>;
}

@df.Dataforge(includeFromJson: false, includeToJson: false)
abstract final class NestedRecordOwner with _$NestedRecordOwner {
  const NestedRecordOwner._();
  factory NestedRecordOwner({required RecordBox<(int,)> value}) =
      _NestedRecordOwner;
}

@df.Dataforge(
  name: r'$NestedRecordOwnerRecordDataforgeType0',
  includeFromJson: false,
  includeToJson: false,
)
abstract final class NestedRecordCollision
    with _$$NestedRecordOwnerRecordDataforgeType0 {
  const NestedRecordCollision._();
  factory NestedRecordCollision({required int value}) =
      _$NestedRecordOwnerRecordDataforgeType0;
}
''';

const _manualImplementationSource = r'''
import 'annotations.dart' as df;

@df.Dataforge(includeFromJson: false, includeToJson: false)
abstract final class ManualImplementation with _$ManualImplementation {
  const ManualImplementation._();
  factory ManualImplementation({required int value}) = _ManualImplementation;
}

final class _ManualImplementation extends ManualImplementation {
  _ManualImplementation({required this.value}) : super._();

  final int value;
}
''';

const _nonClassSubtypeSource = r'''
import 'annotations.dart' as df;

@df.Dataforge(
  includeFromJson: false,
  includeToJson: false,
)
abstract final class EnumBoundary with _$EnumBoundary {
  const EnumBoundary._();
  factory EnumBoundary({required int value}) = _EnumBoundary;
}

enum EnumBoundaryBypass implements EnumBoundary {
  instance(1);

  const EnumBoundaryBypass(this.value);

  @override
  final int value;
}

@df.Dataforge(
  includeFromJson: false,
  includeToJson: false,
)
abstract final class MixinBoundary with _$MixinBoundary {
  const MixinBoundary._();
  factory MixinBoundary({required int value}) = _MixinBoundary;
}

mixin MixinBoundaryBypass implements MixinBoundary {
  @override
  int get value => 1;
}

@df.Dataforge(
  includeFromJson: false,
  includeToJson: false,
)
abstract final class ExtensionBoundary with _$ExtensionBoundary {
  const ExtensionBoundary._();
  factory ExtensionBoundary({required int value}) = _ExtensionBoundary;
}

extension type ExtensionBoundaryBypass(ExtensionBoundary representation)
    implements ExtensionBoundary {}
''';

const _manualMixinSource = r'''
import 'annotations.dart' as df;

mixin _$HandwrittenMixin {}

@df.Dataforge(includeFromJson: false, includeToJson: false)
abstract final class HandwrittenMixin with _$HandwrittenMixin {
  const HandwrittenMixin._();
  factory HandwrittenMixin({required int value}) = _HandwrittenMixin;
}
''';

const _manualHelperSource = r'''
import 'annotations.dart' as df;

final Object _$HandwrittenHelperDataforgeType = Object();

@df.Dataforge(includeFromJson: false, includeToJson: false)
abstract final class HandwrittenHelper with _$HandwrittenHelper {
  const HandwrittenHelper._();
  factory HandwrittenHelper({required int value}) = _HandwrittenHelper;
}
''';

const _duplicateAnnotationSource = r'''
import 'annotations.dart' as df;

typedef Forge = df.Dataforge;
const configuredForge = df.Dataforge(name: 'Duplicated');

@Forge(name: 'Duplicated')
@configuredForge
abstract final class DuplicateAnnotation with _$Duplicated {
  const DuplicateAnnotation._();
  factory DuplicateAnnotation({required int value}) = _Duplicated;
  factory DuplicateAnnotation.fromJson(Map<String, Object?> json) =
      _Duplicated.fromJson;
}
''';

const _reservedMembersSource = r'''
import 'annotations.dart' as df;

@df.Dataforge()
abstract final class ReservedMembers with _$ReservedMembers {
  const ReservedMembers._();
  factory ReservedMembers({required int value}) = _ReservedMembers;
  factory ReservedMembers.fromJson(Map<String, Object?> json) =
      _ReservedMembers.fromJson;

  int get value => 1;

  ReservedMembers copyWith({Object? value}) => this;

  Map<String, Object?> toJson() => const {};

  @override
  bool operator ==(Object other) => false;

  @override
  int get hashCode => 1;

  @override
  String toString() => 'manual';
}
''';

const _implementationReferenceSource = r'''
import 'annotations.dart' as df;
part 'implementation_reference.data.dart';

@df.Dataforge(includeFromJson: false, includeToJson: false)
abstract final class FrozenBypass with _$FrozenBypass {
  const FrozenBypass._();
  factory FrozenBypass({required List<int> values}) = _FrozenBypass;
  factory FrozenBypass.unsafe({required List<int> values}) =
      _FrozenBypass._frozen;
}
''';

const _implementationReferenceGeneratedSource = r'''
part of 'implementation_reference.dart';

mixin _$FrozenBypass {
  List<int> get values;
}

final class _FrozenBypass extends FrozenBypass {
  _FrozenBypass({required List<int> values})
      : values = List<int>.unmodifiable(values),
        super._();

  const _FrozenBypass._frozen({required this.values}) : super._();

  @override
  final List<int> values;
}
''';

const _invalidHierarchySource = r'''
import 'annotations.dart' as df;

abstract class StatefulParent {
  const StatefulParent() : inherited = 1;

  final int inherited;
}

abstract interface class RequiredContract {
  int get contractValue;
}

@df.Dataforge(includeFromJson: false, includeToJson: false)
abstract final class InheritedState extends StatefulParent
    with _$InheritedState {
  const InheritedState._() : super();
  factory InheritedState({required int value}) = _InheritedState;
}

@df.Dataforge(includeFromJson: false, includeToJson: false)
abstract final class ImplementedContract with _$ImplementedContract
    implements RequiredContract {
  const ImplementedContract._();
  factory ImplementedContract({required int value}) = _ImplementedContract;
}

@df.Dataforge(includeFromJson: false, includeToJson: false)
abstract final class ExplicitObject extends Object with _$ExplicitObject {
  const ExplicitObject._();
  factory ExplicitObject({required int value}) = _ExplicitObject;
}
''';

const _exactTopTypeWitnessSource = r'''
import 'annotations.dart' as df;

@df.Dataforge(includeFromJson: false, includeToJson: false)
abstract final class ExactTopTypes with _$ExactTopTypes {
  const ExactTopTypes._();
  factory ExactTopTypes({
    required df.DataforgeType<Object?> objectType,
    required df.DataforgeType<dynamic> dynamicType,
    required Object? object,
    required List<Map<String, Object?>> values,
    required Map<String, List<dynamic>> dynamics,
  }) = _ExactTopTypes;
}

@df.Dataforge(includeFromJson: false, includeToJson: false)
abstract final class ExactLeafBox with _$ExactLeafBox {
  const ExactLeafBox._();
  factory ExactLeafBox({
    required df.DataforgeType<Object?> objectType,
    required Object? value,
  }) = _ExactLeafBox;
}

@df.Dataforge(includeFromJson: false, includeToJson: false)
abstract final class MissingExactLeafHolder with _$MissingExactLeafHolder {
  const MissingExactLeafHolder._();
  factory MissingExactLeafHolder({required ExactLeafBox value}) =
      _MissingExactLeafHolder;
}

@df.Dataforge(includeFromJson: false, includeToJson: false)
abstract final class GenericInner<T> with _$GenericInner<T> {
  const GenericInner._();
  factory GenericInner({
    required df.DataforgeType<T> type,
    required T value,
  }) = _GenericInner<T>;
}

@df.Dataforge(includeFromJson: false, includeToJson: false)
abstract final class GenericTarget<T> with _$GenericTarget<T> {
  const GenericTarget._();
  factory GenericTarget({
    required df.DataforgeType<GenericInner<T>> innerType,
    required GenericInner<T> inner,
  }) = _GenericTarget<T>;
}

@df.Dataforge(includeFromJson: false, includeToJson: false)
abstract final class GenericExactHolder with _$GenericExactHolder {
  const GenericExactHolder._();
  factory GenericExactHolder({
    required df.DataforgeType<GenericInner<int>> innerType,
    required GenericTarget<int> target,
  }) = _GenericExactHolder;
}

@df.Dataforge(includeFromJson: false, includeToJson: false)
abstract final class GenericListBox<T> with _$GenericListBox<T> {
  const GenericListBox._();
  factory GenericListBox({
    required df.DataforgeType<List<T>> valuesType,
    required List<T> values,
  }) = _GenericListBox<T>;
}

@df.Dataforge(includeFromJson: false, includeToJson: false)
abstract final class GenericListExactHolder with _$GenericListExactHolder {
  const GenericListExactHolder._();
  factory GenericListExactHolder({
    required df.DataforgeType<List<Object?>> valuesType,
    required GenericListBox<Object?> box,
  }) = _GenericListExactHolder;
}

@df.Dataforge(includeFromJson: false, includeToJson: false)
abstract final class GenericListMissingHolder with _$GenericListMissingHolder {
  const GenericListMissingHolder._();
  factory GenericListMissingHolder({required GenericListBox<Object?> box}) =
      _GenericListMissingHolder;
}

@df.Dataforge()
abstract final class GenericRecordJsonBox<T> with _$GenericRecordJsonBox<T> {
  const GenericRecordJsonBox._();
  factory GenericRecordJsonBox({
    required df.DataforgeType<List<T>> valuesType,
    required List<T> values,
  }) = _GenericRecordJsonBox<T>;
  factory GenericRecordJsonBox.fromJson(
    Map<String, Object?> json, {
    required df.DataforgeType<List<T>> valuesType,
  }) = _GenericRecordJsonBox<T>.fromJson;
}

@df.Dataforge()
abstract final class GenericRecordJsonExactHolder
    with _$GenericRecordJsonExactHolder {
  const GenericRecordJsonExactHolder._();
  factory GenericRecordJsonExactHolder({
    required df.DataforgeType<List<(int,)>> valuesType,
    required GenericRecordJsonBox<(int,)> box,
  }) = _GenericRecordJsonExactHolder;
  factory GenericRecordJsonExactHolder.fromJson(
    Map<String, Object?> json, {
    required df.DataforgeType<List<(int,)>> valuesType,
  }) = _GenericRecordJsonExactHolder.fromJson;
}
''';

void main() {
  group('V1ModelSchemaBuilder', () {
    late _Fixture fixture;

    setUpAll(() async {
      fixture = await _Fixture.create({
        'annotations.dart': _annotationsSource,
        'external.dart': _externalSource,
        'models.dart': _modelsSource,
        'models.data.dart': _modelsGeneratedSource,
        'invalid_models.dart': _invalidModelsSource,
        'cyclic_models.dart': _cyclicModelsSource,
        'hidden_runtime.dart': _hiddenRuntimeSource,
        'separate_runtime_prefix.dart': _separateRuntimePrefixSource,
        'hidden_model_companion.dart': _hiddenModelCompanionSource,
        'exact_hidden_model_companion.dart': _exactHiddenModelCompanionSource,
        'hidden_model_bound.dart': _hiddenModelBoundSource,
        'hidden_prefixed_model_companion.dart':
            _hiddenPrefixedModelCompanionSource,
        'separate_model_prefix.dart': _separateModelPrefixSource,
        'only_prefixed_enum.dart': _onlyPrefixedEnumSource,
        'dual_prefixed_enum.dart': _dualPrefixedEnumSource,
        'full_model_barrel.dart': _fullModelBarrelSource,
        'shown_model_only_barrel.dart': _shownModelOnlyBarrelSource,
        'hidden_model_companion_barrel.dart': _hiddenModelCompanionBarrelSource,
        'full_reexport_model.dart': _fullReexportModelSource,
        'shown_model_only_reexport.dart': _shownModelOnlyReexportSource,
        'hidden_model_companion_reexport.dart':
            _hiddenModelCompanionReexportSource,
        'typedef_types.dart': _typedefTypesSource,
        'typedef_only_model.dart': _typedefOnlyModelSource,
        'default_type.dart': _defaultTypeSource,
        'collision.dart': _collisionSource,
        'manual_implementation.dart': _manualImplementationSource,
        'non_class_subtype.dart': _nonClassSubtypeSource,
        'manual_mixin.dart': _manualMixinSource,
        'manual_helper.dart': _manualHelperSource,
        'duplicate_annotation.dart': _duplicateAnnotationSource,
        'reserved_members.dart': _reservedMembersSource,
        'implementation_reference.dart': _implementationReferenceSource,
        'implementation_reference.data.dart':
            _implementationReferenceGeneratedSource,
        'invalid_hierarchy.dart': _invalidHierarchySource,
        'exact_top_type_witness.dart': _exactTopTypeWitnessSource,
      });
    });

    tearDownAll(() async {
      await fixture.dispose();
    });

    test('bootstrap 构建完整递归 schema 并保留 prefix/default/witness', () {
      final library = fixture.library('models.dart');
      final result = fixture.builder.build(library.getClass('User')!);

      expect(result.diagnostics, isEmpty);
      final schema = result.schema!;
      expect(schema.implementationName, '_StoredUser');
      expect(schema.includeFromJson, isFalse);
      expect(schema.includeToJson, isFalse);
      expect(schema.generateCopyWith, isTrue);
      expect(schema.typeParameters.single.toDeclaration(), 'T extends num');
      expect(result.annotationPrefix, 'df');

      final semanticParameters = schema.constructor.parameters
          .where((parameter) => parameter.fieldName == null)
          .toList();
      expect(semanticParameters, hasLength(4));
      expect(schema.fields.map((field) => field.name), isNot(contains('type')));
      expect(
        schema.fields.map((field) => field.name),
        isNot(contains('moneyType')),
      );
      expect(
        schema.fields.map((field) => field.name),
        isNot(contains('moneyCodecType')),
      );
      expect(
        schema.fields.map((field) => field.name),
        isNot(contains('moneyListCodecType')),
      );

      final fields = {for (final field in schema.fields) field.name: field};
      expect(fields['value']!.shape, const TypeParameterShape('T'));
      expect(fields['createdAt']!.shape, const NullableShape(DateTimeShape()));
      expect(fields['elapsed']!.shape, const DurationShape());
      expect(fields['createdAt']!.jsonName, 'created_at');
      expect(fields['createdAt']!.alternateJsonNames, ['createdAt']);
      expect(fields['createdAt']!.includeIfNull, isFalse);
      expect(fields['address']!.shape, isA<ModelShape>());
      expect(fields['status']!.shape, isA<EnumShape>());
      expect(fields['money']!.shape, isA<CustomShape>());

      final witnessTarget = fields['witnessTarget']!.shape as ModelShape;
      expect(
        witnessTarget.witnessArguments.map(
          (argument) =>
              argument.toDartType(resolveSymbol: result.resolveSymbol),
        ),
        ['api.Money', 'Map<String, Set<api.Money?>>', 'api.Codec<api.Money>'],
      );

      final nestedTarget = fields['nestedWitnessTarget']!.shape as ModelShape;
      final nestedWitness = nestedTarget.witnessArguments.single as ModelShape;
      expect(
        nestedWitness.toDartType(resolveSymbol: result.resolveSymbol),
        'api.WitnessTarget<List<api.Money>>',
      );
      expect(
        nestedWitness.witnessArguments.map(
          (argument) =>
              argument.toDartType(resolveSymbol: result.resolveSymbol),
        ),
        [
          'List<api.Money>',
          'Map<String, Set<List<api.Money>?>>',
          'api.Codec<List<api.Money>>',
        ],
      );
      expect(
        fields['nested']!.shape.toDartType(resolveSymbol: result.resolveSymbol),
        'List<Map<String, Set<api.Address?>>>',
      );
      expect(
        fields['record']!.shape.toDartType(resolveSymbol: result.resolveSymbol),
        '(int, {api.Status status})',
      );

      expect(fields['retries']!.defaultValueCode, '3');
      expect(fields['tags']!.defaultValueCode, 'const <Never>[]');
      expect(fields['flags']!.defaultValueCode, 'const <Never>{}');
      expect(fields['counts']!.defaultValueCode, 'const <Never, Never>{}');
      expect(fields['note']!.defaultValueCode, 'null');
      expect(ModelSchema.fromMap(schema.toMap()), schema);

      final status = fields['status']!.shape as EnumShape;
      final address = fields['address']!.shape as ModelShape;
      expect(result.resolveSymbol(status.symbol), 'api.Status');
      expect(result.resolveSymbol(address.modelId.symbol), 'api.Address');
      expect(
        result.resolveSymbol(
          SymbolId(
            libraryUri: address.modelId.libraryUri,
            name: r'$AddressType',
          ),
        ),
        r'api.$AddressType',
      );
    });

    test('已有 generated target 的二次 build 不误判 inherited default', () {
      final element = fixture.library('models.dart').getClass('Existing')!;
      final first = fixture.builder.build(element);
      final second = fixture.builder.build(element);

      expect(first.diagnostics, isEmpty);
      expect(
        second.diagnostics,
        isEmpty,
        reason: second.diagnostics.map((item) => item.details).join('\n'),
      );
      expect(first.schema, second.schema);
      expect(first.schema!.fields.single.defaultValueCode, '"fallback"');
    });

    test(
      'annotated concrete class is rejected by the exclusive v1 contract',
      () {
        final concrete = fixture.library('models.dart').getClass('Concrete')!;
        final result = fixture.builder.build(concrete);

        expect(result.schema, isNull);
        expect(
          result.diagnostics.map((diagnostic) => diagnostic.code),
          everyElement(GenerationDiagnosticCode.invalidModel),
        );
        expect(
          result.diagnostics.map((diagnostic) => diagnostic.target),
          containsAll(<String>{'model.modifier', 'constructors.new'}),
        );
      },
    );

    test('class without @Dataforge returns a stable v1 diagnostic', () {
      final money = fixture.library('external.dart').getClass('Money')!;
      final result = fixture.builder.build(money);

      expect(result.schema, isNull);
      expect(result.diagnostics, hasLength(1));
      expect(
        result.diagnostics.single.code,
        GenerationDiagnosticCode.invalidModel,
      );
      expect(result.diagnostics.single.target, 'annotations.dataforge');
    });

    test('声明、构造器、可变状态与类型错误返回稳定 diagnostics', () {
      final library = fixture.library('invalid_models.dart');
      final cases = <String, GenerationDiagnosticCode>{
        'NotAbstractFinal': GenerationDiagnosticCode.invalidModel,
        'MissingFactory': GenerationDiagnosticCode.invalidModel,
        'MissingMixin': GenerationDiagnosticCode.invalidModel,
        'WrongFromJson': GenerationDiagnosticCode.constructorMismatch,
        'WrongName': GenerationDiagnosticCode.constructorMismatch,
        'Positional': GenerationDiagnosticCode.constructorMismatch,
        'Mutable': GenerationDiagnosticCode.mutableField,
        'NoBase': GenerationDiagnosticCode.constructorMismatch,
        'ExtraSubtype': GenerationDiagnosticCode.invalidModel,
      };

      for (final entry in cases.entries) {
        final result = fixture.builder.build(library.getClass(entry.key)!);
        expect(result.schema, isNull, reason: entry.key);
        expect(
          result.diagnostics.map((item) => item.code),
          contains(entry.value),
          reason: entry.key,
        );
        expect(
          result.diagnostics.every((item) => item.location != null),
          isTrue,
          reason: entry.key,
        );
      }

      final unsupported = fixture.builder.build(
        library.getClass('Unsupported')!,
      );
      expect(
        unsupported.diagnostics.where(
          (item) => item.code == GenerationDiagnosticCode.unsupportedType,
        ),
        hasLength(4),
      );
    });

    test('exact witness 校验 missing、duplicate 与 extra', () {
      final element = fixture
          .library('invalid_models.dart')
          .getClass('WitnessProblems')!;
      final result = fixture.builder.build(element);
      final witnessDiagnostics = result.diagnostics
          .where(
            (item) =>
                item.code ==
                GenerationDiagnosticCode.genericTypeWitnessRequired,
          )
          .toList();

      expect(result.schema, isNull);
      expect(witnessDiagnostics, hasLength(3));
      expect(
        witnessDiagnostics.any((item) => item.target!.endsWith('.duplicate')),
        isTrue,
      );
      expect(
        witnessDiagnostics.any((item) => item.target!.endsWith('.extra')),
        isTrue,
      );
      expect(
        witnessDiagnostics.any((item) => item.target!.contains('money')),
        isTrue,
      );
    });

    test('Object? 与 dynamic 可由任意深度的 exact leaf witness 覆盖', () {
      final result = fixture.builder.build(
        fixture
            .library('exact_top_type_witness.dart')
            .getClass('ExactTopTypes')!,
      );

      expect(
        result.diagnostics,
        isEmpty,
        reason: result.diagnostics.join('\n'),
      );
      expect(result.schema, isNotNull);
      expect(result.schema!.fields.map((field) => field.shape.toDartType()), [
        'Object?',
        'List<Map<String, Object?>>',
        'Map<String, List<dynamic>>',
      ]);
    });

    test('跨模型缺少 unsafe leaf witness 时返回稳定 missing diagnostic', () {
      final result = fixture.builder.build(
        fixture
            .library('exact_top_type_witness.dart')
            .getClass('MissingExactLeafHolder')!,
      );

      expect(
        result.schema,
        isNull,
        reason:
            '${result.schema?.fields.single.shape.toMap()} '
            '${result.diagnostics}',
      );
      expect(
        result.diagnostics,
        contains(
          isA<GenerationDiagnostic>()
              .having(
                (diagnostic) => diagnostic.code,
                'code',
                GenerationDiagnosticCode.genericTypeWitnessRequired,
              )
              .having(
                (diagnostic) => diagnostic.target,
                'target',
                contains('fields.value'),
              ),
        ),
      );
    });

    test('实例化后的泛型 model witness 可由 whole exact witness 覆盖', () {
      final result = fixture.builder.build(
        fixture
            .library('exact_top_type_witness.dart')
            .getClass('GenericExactHolder')!,
      );

      expect(
        result.diagnostics,
        isEmpty,
        reason: result.diagnostics.join('\n'),
      );
      expect(result.schema, isNotNull);
      final target = result.schema!.fields.single.shape as ModelShape;
      expect(target.witnessArguments, hasLength(1));
      expect(
        (target.witnessArguments.single as ModelShape).witnessArguments,
        isEmpty,
      );
      final source = ModelSchemaWriter(
        symbolNameResolver: result.resolveSymbol,
        runtimePrefix: result.annotationPrefix ?? '',
      ).write(result.schema!);
      expect(source, isNot(contains(r'$GenericInnerType')));
      expect(source, contains('innerType'));
    });

    test('泛型 model bound 仅作为 Dart 身份，不要求被隐藏的 companion', () {
      final result = fixture.builder.build(
        fixture
            .library('hidden_model_bound.dart')
            .getClass('HiddenModelBound')!,
      );

      expect(
        result.diagnostics,
        isEmpty,
        reason: result.diagnostics.join('\n'),
      );
      expect(result.schema, isNotNull);
      final bound = result.schema!.typeParameters.single.bound as ModelShape;
      expect(bound.modelId.name, 'Address');
      expect(bound.witnessArguments, isEmpty);

      final source = ModelSchemaWriter(
        symbolNameResolver: result.resolveSymbol,
        runtimePrefix: result.annotationPrefix ?? '',
      ).write(result.schema!);
      expect(source, contains('T extends Address'));
      expect(source, isNot(contains(r'$AddressType')));
    });

    test('泛型复合 unsafe witness 可 whole exact 覆盖，缺失时稳定拒绝', () {
      final library = fixture.library('exact_top_type_witness.dart');
      final covered = fixture.builder.build(
        library.getClass('GenericListExactHolder')!,
      );
      expect(
        covered.diagnostics,
        isEmpty,
        reason: covered.diagnostics.join('\n'),
      );
      expect(covered.schema, isNotNull);
      final box = covered.schema!.fields.single.shape as ModelShape;
      expect(box.typeArguments.single.toDartType(), 'Object?');
      expect(box.witnessArguments.single.toDartType(), 'List<Object?>');

      final missing = fixture.builder.build(
        library.getClass('GenericListMissingHolder')!,
      );
      expect(missing.schema, isNull);
      expect(
        missing.diagnostics,
        contains(
          isA<GenerationDiagnostic>().having(
            (diagnostic) => diagnostic.code,
            'code',
            GenerationDiagnosticCode.genericTypeWitnessRequired,
          ),
        ),
      );
    });

    test('实例化泛型的 exact composite witness 不被身份树中的 Record 越界误拒', () {
      final result = fixture.builder.build(
        fixture
            .library('exact_top_type_witness.dart')
            .getClass('GenericRecordJsonExactHolder')!,
      );

      expect(
        result.diagnostics,
        isEmpty,
        reason: result.diagnostics.join('\n'),
      );
      expect(result.schema, isNotNull);
      final box = result.schema!.fields.single.shape as ModelShape;
      expect(box.typeArguments.single, isA<RecordShape>());
      expect(box.witnessArguments.single.toDartType(), 'List<(int,)>');

      expect(
        () => ModelSchemaWriter(
          symbolNameResolver: result.resolveSymbol,
          runtimePrefix: result.annotationPrefix ?? '',
        ).write(result.schema!),
        returnsNormally,
      );
    });

    test('无 default 的 ignored 字段和 unsupported const 均拒绝', () {
      final library = fixture.library('invalid_models.dart');
      final ignored = fixture.builder.build(
        library.getClass('IgnoredWithoutDefault')!,
      );
      final unsupportedDefault = fixture.builder.build(
        library.getClass('UnsupportedDefault')!,
      );

      expect(
        ignored.diagnostics.map((item) => item.code),
        contains(GenerationDiagnosticCode.invalidJsonConfiguration),
      );
      expect(
        unsupportedDefault.diagnostics.map((item) => item.code),
        contains(GenerationDiagnosticCode.constructorMismatch),
      );
    });

    test('递归检查 ModelShape witnessArguments 的外层依赖', () {
      final element = fixture
          .library('invalid_models.dart')
          .getClass('MissingNestedWitness')!;
      final result = fixture.builder.build(element);
      final witnessDiagnostics = result.diagnostics
          .where(
            (diagnostic) =>
                diagnostic.code ==
                GenerationDiagnosticCode.genericTypeWitnessRequired,
          )
          .toList();

      expect(result.schema, isNull);
      expect(witnessDiagnostics, hasLength(1));
      expect(witnessDiagnostics.single.target, contains('fields.target'));
      final missingShape = TypeShape.fromMap(
        witnessDiagnostics.single.details['shape']! as Map<String, Object?>,
      );
      expect(
        missingShape.toDartType(resolveSymbol: result.resolveSymbol),
        'Codec<List<Money>>',
      );
    });

    test('循环 model witness 签名返回稳定 diagnostic，不递归溢出', () {
      final library = fixture.library('cyclic_models.dart');
      final changing = fixture.builder.build(library.getClass('ChangingNode')!);
      expect(changing.diagnostics, isEmpty);
      expect(changing.schema, isNotNull);
      expect(
        ModelSchemaWriter(
          symbolNameResolver: changing.resolveSymbol,
          runtimePrefix: changing.annotationPrefix ?? '',
        ).write(changing.schema!),
        contains(
          r'$ChangingNodeType<List<T>>('
          'DataforgeTypes.list(_type))',
        ),
      );

      final covered = fixture.builder.build(library.getClass('CycleA')!);
      expect(
        covered.diagnostics,
        isEmpty,
        reason: 'CycleA 自身的 whole exact witness 已切断其字段子树',
      );

      final element = library.getClass('CycleHolder')!;
      final result = fixture.builder.build(element);

      expect(result.schema, isNull);
      expect(
        result.diagnostics,
        contains(
          isA<GenerationDiagnostic>()
              .having(
                (diagnostic) => diagnostic.code,
                'code',
                GenerationDiagnosticCode.genericTypeWitnessRequired,
              )
              .having(
                (diagnostic) => diagnostic.target,
                'target',
                endsWith('.witnessArguments.cycle'),
              ),
        ),
      );
    });

    test('show/hide 不能隐藏生成 part 所需 runtime，可使用独立完整前缀', () {
      final hidden = fixture.builder.build(
        fixture.library('hidden_runtime.dart').getClass('HiddenRuntime')!,
      );
      expect(hidden.schema, isNull);
      expect(
        hidden.diagnostics,
        contains(
          isA<GenerationDiagnostic>()
              .having(
                (diagnostic) => diagnostic.code,
                'code',
                GenerationDiagnosticCode.invalidModel,
              )
              .having(
                (diagnostic) => diagnostic.target,
                'target',
                'imports.dataforgeRuntime',
              ),
        ),
      );

      final separate = fixture.builder.build(
        fixture
            .library('separate_runtime_prefix.dart')
            .getClass('SeparateRuntimePrefix')!,
      );
      expect(
        separate.diagnostics,
        isEmpty,
        reason: separate.diagnostics.map((item) => item.details).join('\n'),
      );
      expect(separate.annotationPrefix, 'runtime');
    });

    test('whole exact model witness 不依赖被隐藏的生成 companion', () {
      final result = fixture.builder.build(
        fixture
            .library('exact_hidden_model_companion.dart')
            .getClass('ExactHiddenModelCompanion')!,
      );

      expect(
        result.diagnostics,
        isEmpty,
        reason: result.diagnostics.join('\n'),
      );
      expect(result.schema, isNotNull);
      final fieldShape = result.schema!.fields.single.shape;
      final witnessShape =
          result.schema!.constructor.parameters
                  .where((parameter) => parameter.fieldName == null)
                  .single
                  .shape
              as CustomShape;
      expect(witnessShape.typeArguments.single, fieldShape);
      expect((fieldShape as ModelShape).witnessArguments, isEmpty);
      final source = ModelSchemaWriter(
        symbolNameResolver: result.resolveSymbol,
        runtimePrefix: result.annotationPrefix ?? '',
      ).write(result.schema!);
      expect(source, isNot(contains(r'$AddressType')));
      expect(source, contains('addressType.freeze'));
    });

    test('跨库 model import 必须同时暴露生成的 type companion', () {
      final hidden = fixture.builder.build(
        fixture
            .library('hidden_model_companion.dart')
            .getClass('HiddenModelCompanion')!,
      );
      expect(hidden.schema, isNull);
      expect(
        hidden.diagnostics,
        contains(
          isA<GenerationDiagnostic>().having(
            (diagnostic) => diagnostic.code,
            'code',
            GenerationDiagnosticCode.unsupportedType,
          ),
        ),
      );

      final hiddenPrefixed = fixture.builder.build(
        fixture
            .library('hidden_prefixed_model_companion.dart')
            .getClass('HiddenPrefixedModelCompanion')!,
      );
      expect(hiddenPrefixed.schema, isNull);
      expect(
        hiddenPrefixed.diagnostics,
        contains(
          isA<GenerationDiagnostic>().having(
            (diagnostic) => diagnostic.code,
            'code',
            GenerationDiagnosticCode.unsupportedType,
          ),
        ),
      );

      final separate = fixture.builder.build(
        fixture
            .library('separate_model_prefix.dart')
            .getClass('SeparateModelPrefix')!,
      );
      expect(separate.diagnostics, isEmpty);
      final shape = separate.schema!.fields.single.shape as ModelShape;
      expect(separate.resolveSymbol(shape.modelId.symbol), 'api.Address');
      expect(
        separate.resolveSymbol(
          SymbolId(libraryUri: shape.modelId.libraryUri, name: r'$AddressType'),
        ),
        r'api.$AddressType',
      );
    });

    test('enum-only prefixed import 保留精确 prefix', () {
      final result = fixture.builder.build(
        fixture.library('only_prefixed_enum.dart').getClass('EnumOnly')!,
      );

      expect(result.diagnostics, isEmpty);
      final shape = result.schema!.fields.single.shape as EnumShape;
      expect(result.resolveSymbol(shape.symbol), 'values.Status');

      final dual = fixture.builder.build(
        fixture.library('dual_prefixed_enum.dart').getClass('DualPrefixEnum')!,
      );
      expect(dual.diagnostics, isEmpty);
      final dualShape = dual.schema!.fields.single.shape as EnumShape;
      expect(dual.resolveSymbol(dualShape.symbol), 'z.Status');
    });

    test('re-export 每层 show/hide 都必须暴露 model companion', () {
      final full = fixture.builder.build(
        fixture
            .library('full_reexport_model.dart')
            .getClass('FullReexportModel')!,
      );
      expect(full.diagnostics, isEmpty);
      final fullShape = full.schema!.fields.single.shape as ModelShape;
      expect(full.resolveSymbol(fullShape.modelId.symbol), 'api.Address');
      expect(
        full.resolveSymbol(
          SymbolId(
            libraryUri: fullShape.modelId.libraryUri,
            name: r'$AddressType',
          ),
        ),
        r'api.$AddressType',
      );

      for (final (libraryName, modelName) in [
        ('shown_model_only_reexport.dart', 'ShownModelOnlyReexport'),
        (
          'hidden_model_companion_reexport.dart',
          'HiddenModelCompanionReexport',
        ),
      ]) {
        final hidden = fixture.builder.build(
          fixture.library(libraryName).getClass(modelName)!,
        );
        expect(hidden.schema, isNull);
        expect(
          hidden.diagnostics,
          contains(
            isA<GenerationDiagnostic>().having(
              (diagnostic) => diagnostic.code,
              'code',
              GenerationDiagnosticCode.unsupportedType,
            ),
          ),
        );
      }
    });

    test('typedef-only import 使用源码可见 alias 而非不可见底层类型', () {
      final result = fixture.builder.build(
        fixture
            .library('typedef_only_model.dart')
            .getClass('TypedefOnlyModel')!,
      );

      expect(
        result.diagnostics,
        isEmpty,
        reason: result.diagnostics.join('\n'),
      );
      final shape = result.schema!.fields.single.shape;
      expect(
        shape.toDartType(resolveSymbol: result.resolveSymbol),
        'values.PublicMoney',
      );
    });

    test('@DataforgeDefault 校验 resolved 常量可赋值性并保留位置', () {
      final invalid = fixture.builder.build(
        fixture.library('default_type.dart').getClass('InvalidDefaultType')!,
      );

      expect(invalid.schema, isNull);
      final diagnostic = invalid.diagnostics.singleWhere(
        (item) => item.target == 'constructors.new.parameters.count.default',
      );
      expect(diagnostic.code, GenerationDiagnosticCode.constructorMismatch);
      expect(diagnostic.details['expectedType'], 'int');
      expect(diagnostic.details['actualType'], 'String');
      expect(diagnostic.location, isNotNull);
      expect(diagnostic.location!.uri, contains('default_type.dart'));
      expect(diagnostic.location!.line, greaterThan(0));
      expect(diagnostic.location!.column, greaterThan(0));
      expect(
        invalid.diagnostics,
        contains(
          isA<GenerationDiagnostic>().having(
            (item) => item.target,
            'target',
            'constructors.new.parameters.imprecise.default',
          ),
        ),
      );
      expect(
        invalid.diagnostics,
        contains(
          isA<GenerationDiagnostic>().having(
            (item) => item.target,
            'target',
            'constructors.new.parameters.dynamicItems.default',
          ),
        ),
      );

      final contextual = fixture.builder.build(
        fixture.library('default_type.dart').getClass('ContextualDefaults')!,
      );
      expect(
        contextual.diagnostics,
        isEmpty,
        reason: contextual.diagnostics.join('\n'),
      );
      final fields = {
        for (final field in contextual.schema!.fields) field.name: field,
      };
      expect(fields['ratio']!.defaultValueCode, '1');
      expect(fields['labels']!.defaultValueCode, 'const <Never>[]');

      final enumDefault = fixture.builder.build(
        fixture.library('default_type.dart').getClass('PrefixedEnumDefault')!,
      );
      expect(
        enumDefault.diagnostics,
        isEmpty,
        reason: enumDefault.diagnostics.join('\n'),
      );
      expect(
        enumDefault.schema!.fields.single.defaultValueCode,
        'values.Status.active',
      );

      final typedefEnumDefault = fixture.builder.build(
        fixture.library('default_type.dart').getClass('TypedefEnumDefault')!,
      );
      expect(
        typedefEnumDefault.diagnostics,
        isEmpty,
        reason: typedefEnumDefault.diagnostics.join('\n'),
      );
      expect(
        typedefEnumDefault.schema!.fields.single.defaultValueCode,
        'aliases.StatusAlias.disabled',
      );
    });

    test('同 library 重复 Dataforge name 由 base 统一诊断', () {
      final library = fixture.library('collision.dart');
      for (final modelName in ['CollisionA', 'CollisionB']) {
        final result = fixture.builder.build(library.getClass(modelName)!);
        expect(result.schema, isNull);
        final diagnostic = result.diagnostics.singleWhere(
          (item) => item.target == 'library.generatedSymbols',
        );
        expect(diagnostic.code, GenerationDiagnosticCode.invalidModel);
        expect(diagnostic.details['symbols'], [r'_$Shared', '_Shared']);
        expect(diagnostic.details['models'], hasLength(2));
        expect(diagnostic.location, isNotNull);
      }

      final self = fixture.builder.build(library.getClass('SelfCollision')!);
      final selfDiagnostic = self.diagnostics.singleWhere(
        (item) => item.target == 'library.generatedSymbols',
      );
      expect(
        selfDiagnostic.details['symbols'],
        contains(r'_$SelfCollisionDataforgeType'),
      );
      expect(selfDiagnostic.details['models'], hasLength(1));

      for (final modelName in ['RecordOwner', 'RecordCollision']) {
        final result = fixture.builder.build(library.getClass(modelName)!);
        final diagnostic = result.diagnostics.singleWhere(
          (item) => item.target == 'library.generatedSymbols',
        );
        expect(
          diagnostic.details['symbols'],
          contains(r'_$RecordOwnerRecordDataforgeType0'),
        );
      }

      for (final modelName in ['NestedRecordOwner', 'NestedRecordCollision']) {
        final result = fixture.builder.build(library.getClass(modelName)!);
        final diagnostic = result.diagnostics.singleWhere(
          (item) => item.target == 'library.generatedSymbols',
        );
        expect(
          diagnostic.details['symbols'],
          contains(r'_$NestedRecordOwnerRecordDataforgeType0'),
        );
      }
    });

    test('用户源码手写同名 final subtype 不能冒充生成 implementation', () {
      final result = fixture.builder.build(
        fixture
            .library('manual_implementation.dart')
            .getClass('ManualImplementation')!,
      );

      expect(result.schema, isNull);
      final diagnostic = result.diagnostics.singleWhere(
        (item) => item.target == 'implementation.boundary',
      );
      expect(diagnostic.code, GenerationDiagnosticCode.invalidModel);
      expect(
        diagnostic.details['expectedSourceUri'],
        contains('manual_implementation.data.dart'),
      );
      expect(
        diagnostic.details['actualSourceUri'],
        contains('manual_implementation.dart'),
      );
    });

    test('同 library 的 enum、mixin 与 extension type 不能实现模型', () {
      final library = fixture.library('non_class_subtype.dart');
      final cases = <String, String>{
        'EnumBoundary': 'EnumBoundaryBypass',
        'MixinBoundary': 'MixinBoundaryBypass',
        'ExtensionBoundary': 'ExtensionBoundaryBypass',
      };

      for (final entry in cases.entries) {
        final result = fixture.builder.build(library.getClass(entry.key)!);

        expect(result.schema, isNull, reason: entry.key);
        final diagnostic = result.diagnostics.singleWhere(
          (item) => item.target == 'subtypes.${entry.value}',
        );
        expect(
          diagnostic.code,
          GenerationDiagnosticCode.invalidModel,
          reason: entry.key,
        );
        expect(diagnostic.location, isNotNull, reason: entry.key);
        expect(
          diagnostic.location!.uri,
          contains('non_class_subtype.dart'),
          reason: entry.key,
        );
      }
    });

    test('用户源码手写同名 mixin 不能冒充生成 mixin', () {
      final result = fixture.builder.build(
        fixture.library('manual_mixin.dart').getClass('HandwrittenMixin')!,
      );

      expect(result.schema, isNull);
      final diagnostic = result.diagnostics.singleWhere(
        (item) => item.target == 'model.mixin',
      );
      expect(diagnostic.code, GenerationDiagnosticCode.invalidModel);
      expect(
        diagnostic.details['expectedSourceUri'],
        contains('manual_mixin.data.dart'),
      );
      expect(
        diagnostic.details['actualSourceUri'],
        contains('manual_mixin.dart'),
      );
    });

    test('用户源码不能占用生成器保留的 top-level helper', () {
      final result = fixture.builder.build(
        fixture.library('manual_helper.dart').getClass('HandwrittenHelper')!,
      );

      expect(result.schema, isNull);
      final diagnostic = result.diagnostics.singleWhere(
        (item) =>
            item.target == r'generatedSymbols._$HandwrittenHelperDataforgeType',
      );
      expect(diagnostic.code, GenerationDiagnosticCode.invalidModel);
      expect(
        diagnostic.details['actualSourceUri'],
        contains('manual_helper.dart'),
      );
    });

    test('canonical Dataforge alias/const 重复注解统一拒绝', () {
      final result = fixture.builder.build(
        fixture
            .library('duplicate_annotation.dart')
            .getClass('DuplicateAnnotation')!,
      );

      expect(result.schema, isNull);
      final diagnostic = result.diagnostics.singleWhere(
        (item) => item.target == 'annotations.dataforge',
      );
      expect(diagnostic.code, GenerationDiagnosticCode.invalidModel);
      expect(diagnostic.details['annotationCount'], 2);
      expect(diagnostic.location, isNotNull);
    });

    test('用户同签名实现不能静默覆盖生成成员或 factory 属性', () {
      final result = fixture.builder.build(
        fixture.library('reserved_members.dart').getClass('ReservedMembers')!,
      );

      expect(result.schema, isNull);
      expect(
        result.diagnostics.map((item) => item.target).toSet(),
        containsAll(<String>{
          'members.value',
          'members.copyWith',
          'members.toJson',
          'members.==',
          'members.hashCode',
          'members.toString',
        }),
      );
      expect(
        result.diagnostics
            .where((item) => item.target?.startsWith('members.') == true)
            .every((item) => item.location != null),
        isTrue,
      );
    });

    test(
      '额外 named factory 不能 redirect 到生成 implementation 的 private bypass',
      () {
        final result = fixture.builder.build(
          fixture
              .library('implementation_reference.dart')
              .getClass('FrozenBypass')!,
        );

        expect(result.schema, isNull);
        final diagnostic = result.diagnostics.singleWhere(
          (item) => item.target == 'implementation.references',
        );
        expect(diagnostic.code, GenerationDiagnosticCode.invalidModel);
        expect(diagnostic.details['reference'], '_FrozenBypass._frozen');
        expect(diagnostic.location, isNotNull);
        expect(
          diagnostic.location!.uri,
          contains('implementation_reference.dart'),
        );
        final constructorDiagnostic = result.diagnostics.singleWhere(
          (item) => item.target == 'constructors.unsafe',
        );
        expect(
          constructorDiagnostic.code,
          GenerationDiagnosticCode.invalidModel,
        );
        expect(constructorDiagnostic.location, isNotNull);
      },
    );

    test('模型拒绝 non-Object superclass 与 implements 契约', () {
      final library = fixture.library('invalid_hierarchy.dart');
      final cases = <String, String>{
        'InheritedState': 'model.superclass',
        'ImplementedContract': 'model.interfaces',
      };

      for (final entry in cases.entries) {
        final result = fixture.builder.build(library.getClass(entry.key)!);

        expect(result.schema, isNull, reason: entry.key);
        final diagnostic = result.diagnostics.singleWhere(
          (item) => item.target == entry.value,
        );
        expect(
          diagnostic.code,
          GenerationDiagnosticCode.invalidModel,
          reason: entry.key,
        );
        expect(diagnostic.location, isNotNull, reason: entry.key);
        expect(
          diagnostic.location!.uri,
          contains('invalid_hierarchy.dart'),
          reason: entry.key,
        );
      }

      final explicitObject = fixture.builder.build(
        library.getClass('ExplicitObject')!,
      );
      expect(explicitObject.schema, isNotNull);
      expect(explicitObject.diagnostics, isEmpty);
    });
  });
}

final class _Fixture {
  final Directory directory;
  final Map<String, LibraryElement> libraries;
  final V1ModelSchemaBuilder builder;

  _Fixture(this.directory, this.libraries, this.builder);

  static Future<_Fixture> create(Map<String, String> sources) async {
    final directory = await Directory.systemTemp.createTemp(
      'dataforge_v1_builder_',
    );
    for (final entry in sources.entries) {
      await File('${directory.path}/${entry.key}').writeAsString(entry.value);
    }

    final libraries = <String, LibraryElement>{};
    for (final name in sources.keys) {
      final result = await resolveFile(path: '${directory.path}/$name');
      if (result is! ResolvedUnitResult) {
        throw StateError('无法 resolve fixture $name: $result');
      }
      libraries[name] = result.libraryElement;
    }

    final annotationUri = File(
      '${directory.path}/annotations.dart',
    ).uri.toString();
    final builder = V1ModelSchemaBuilder(
      dataforgeAnnotation: SymbolId(
        libraryUri: annotationUri,
        name: 'Dataforge',
      ),
      jsonKeyAnnotation: SymbolId(libraryUri: annotationUri, name: 'JsonKey'),
      dataforgeType: SymbolId(libraryUri: annotationUri, name: 'DataforgeType'),
      dataforgeDefaultAnnotation: SymbolId(
        libraryUri: annotationUri,
        name: 'DataforgeDefault',
      ),
    );
    return _Fixture(directory, libraries, builder);
  }

  LibraryElement library(String name) => libraries[name]!;

  Future<void> dispose() => directory.delete(recursive: true);
}
