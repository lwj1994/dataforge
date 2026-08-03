import 'dart:collection';
import 'dart:convert';

/// Defines the complete runtime contract for values of type [T].
///
/// Custom types must implement this interface explicitly. The runtime does not
/// provide a `dynamic` witness that could bypass deep immutability.
///
/// Implementations must remain semantically immutable for their entire
/// lifetime. They must not change [freeze], [equals], [hash], or JSON codec
/// behavior after model construction. [freeze] must recursively copy and
/// isolate all mutable state, or return a value already proven deeply
/// immutable. [equals] and [hash] must remain consistent and time-invariant.
/// Dataforge cannot repair a mutable custom witness generically.
abstract interface class DataforgeType<T> {
  const DataforgeType();

  /// Returns an equivalent value that satisfies this type's deep immutability.
  T freeze(T value);

  /// Compares two values using this type's value semantics.
  bool equals(T left, T right);

  /// Returns a hash consistent with [equals].
  int hash(T value);

  /// Eagerly decodes [T] from a JSON-compatible value.
  T fromJson(Object? json, JsonDecodeContext context);

  /// Eagerly encodes [value] as a JSON-compatible value.
  Object? toJson(T value, JsonEncodeContext context);
}

/// Optional protocol for semantic witness identity.
///
/// Built-in and generated model witnesses implement this interface so separate
/// instances describing the same complete type tree remain compatible. Custom
/// [DataforgeType] implementations use object identity by default and should
/// opt in only when semantic equivalence is guaranteed.
///
/// [dataforgeTypeId], [dataforgeTypeArguments], their list, and all descendants
/// must remain immutable for the witness lifetime and form a finite acyclic
/// tree. Otherwise model equality and hash contracts are invalid. Cyclic
/// identity graphs are unsupported.
abstract interface class DataforgeTypeIdentity {
  /// Stable identity of this witness node, excluding child witnesses.
  Object get dataforgeTypeId;

  /// Ordered immutable direct children in the complete type tree; never cyclic.
  List<DataforgeType<dynamic>> get dataforgeTypeArguments;
}

/// Optional untyped equality protocol for covariantly instantiated witnesses.
///
/// Implementations compare [left] and [right] jointly with [other], which is
/// already known to have a compatible semantic type tree. The method must be
/// total, symmetric with the corresponding call on [other], and consistent
/// with both witnesses' [DataforgeType.hash] implementations.
abstract interface class DataforgeTypeErasedEquality {
  bool dataforgeEqualsErased(
    DataforgeType<dynamic> other,
    Object? left,
    Object? right,
  );
}

/// Whether two witnesses describe the same complete semantic type tree.
///
/// Custom witnesses without [DataforgeTypeIdentity] are compatible only when
/// they are the identical object.
bool dataforgeTypeEquals(
  DataforgeType<dynamic> left,
  DataforgeType<dynamic> right,
) {
  if (identical(left, right)) return true;
  if (left is! DataforgeTypeIdentity || right is! DataforgeTypeIdentity) {
    return false;
  }
  final leftIdentity = left as DataforgeTypeIdentity;
  final rightIdentity = right as DataforgeTypeIdentity;
  if (leftIdentity.dataforgeTypeId != rightIdentity.dataforgeTypeId) {
    return false;
  }
  final leftArguments = leftIdentity.dataforgeTypeArguments;
  final rightArguments = rightIdentity.dataforgeTypeArguments;
  if (leftArguments.length != rightArguments.length) return false;
  for (var index = 0; index < leftArguments.length; index++) {
    if (!dataforgeTypeEquals(leftArguments[index], rightArguments[index])) {
      return false;
    }
  }
  return true;
}

/// Returns a semantic witness hash consistent with [dataforgeTypeEquals].
int dataforgeTypeHash(DataforgeType<dynamic> type) {
  if (type is! DataforgeTypeIdentity) return identityHashCode(type);
  final identity = type as DataforgeTypeIdentity;
  return Object.hash(
    identity.dataforgeTypeId,
    Object.hashAll(identity.dataforgeTypeArguments.map(dataforgeTypeHash)),
  );
}

/// Compares values whose compatible witnesses may have different covariant
/// Dart instantiations.
///
/// A generated `Model<int>` and `Model<num>` can carry semantically identical
/// witness trees while their collection or model wrappers remain reified with
/// different Dart type arguments. Calling only one typed [DataforgeType.equals]
/// bridge can therefore throw a [TypeError]. This function tries both compatible
/// witnesses, ignores only an inapplicable covariant bridge, and combines all
/// applicable results symmetrically.
bool dataforgeValueEquals(
  DataforgeType<dynamic> leftType,
  DataforgeType<dynamic> rightType,
  Object? left,
  Object? right,
) {
  if (!dataforgeTypeEquals(leftType, rightType)) return false;
  if (identical(left, right)) return true;

  final leftErased = leftType is DataforgeTypeErasedEquality
      ? (leftType as DataforgeTypeErasedEquality).dataforgeEqualsErased(
          rightType,
          left,
          right,
        )
      : null;
  final rightErased = rightType is DataforgeTypeErasedEquality
      ? (rightType as DataforgeTypeErasedEquality).dataforgeEqualsErased(
          leftType,
          right,
          left,
        )
      : null;
  if (leftErased != null || rightErased != null) {
    if (leftErased == null) return rightErased!;
    if (rightErased == null) return leftErased;
    return leftErased && rightErased;
  }

  final leftResult = _tryDataforgeValueEquals(leftType, left, right);
  final rightResult = identical(leftType, rightType)
      ? leftResult
      : _tryDataforgeValueEquals(rightType, left, right);
  if (leftResult == null) return rightResult ?? false;
  if (rightResult == null) return leftResult;
  return leftResult && rightResult;
}

bool? _tryDataforgeValueEquals(
  DataforgeType<dynamic> type,
  Object? left,
  Object? right,
) {
  try {
    return type.equals(left, right);
  } on TypeError {
    // A covariant runtime bridge rejected this witness instantiation. The
    // compatible witness from the other value may still accept both values.
    return null;
  }
}

/// Stable machine-readable codes for strict JSON failures.
abstract final class DataforgeJsonErrorCode {
  static const decodeFailure = 'DFJ1000';
  static const typeMismatch = 'DFJ1001';
  static const invalidValue = 'DFJ1002';
  static const missingRequiredField = 'DFJ1003';
  static const unknownField = 'DFJ1004';
  static const conflictingFieldAliases = 'DFJ1005';
  static const duplicateKey = 'DFJ1006';
  static const unsupportedDirection = 'DFJ1007';
  static const cyclicInput = 'DFJ1008';
  static const duplicateElement = 'DFJ1009';

  static const encodeFailure = 'DFJ2000';
  static const invalidJsonOutput = 'DFJ2001';
  static const duplicateEncodedKey = 'DFJ2002';
}

/// A JSON decoding failure with the failing JSONPath.
final class DataforgeDecodeException implements Exception {
  const DataforgeDecodeException(
    this.message, {
    this.code = DataforgeJsonErrorCode.decodeFailure,
    required this.path,
    required this.expectedType,
    required this.actualType,
    this.model,
    this.field,
    this.cause,
    this.stackTrace,
  });

  final String message;
  final String code;
  final String path;
  final String expectedType;
  final String actualType;
  final String? model;
  final String? field;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => 'DataforgeDecodeException($code) at $path: $message';
}

/// A JSON encoding failure with the failing JSONPath.
final class DataforgeEncodeException implements Exception {
  const DataforgeEncodeException(
    this.message, {
    this.code = DataforgeJsonErrorCode.encodeFailure,
    required this.path,
    required this.expectedType,
    required this.actualType,
    this.model,
    this.field,
    this.cause,
    this.stackTrace,
  });

  final String message;
  final String code;
  final String path;
  final String expectedType;
  final String actualType;
  final String? model;
  final String? field;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => 'DataforgeEncodeException($code) at $path: $message';
}

/// JSON decoding context.
///
/// The context is immutable. [field], [index], [mapKey], and [mapValue] create
/// new contexts carrying child paths.
final class JsonDecodeContext {
  const JsonDecodeContext({this.model})
    : path = r'$',
      isMapKey = false,
      fieldName = null,
      _traversal = null;

  const JsonDecodeContext._(
    this.path,
    this.isMapKey,
    this.model,
    this.fieldName,
    this._traversal,
  );

  final String path;
  final String? model;
  final String? fieldName;
  final _JsonDecodeTraversal? _traversal;

  /// Whether the current value is a JSON object key.
  final bool isMapKey;

  JsonDecodeContext field(String name, {String? schemaField}) =>
      JsonDecodeContext._(
        _appendJsonPathKey(path, name),
        false,
        model,
        schemaField ?? name,
        _traversal,
      );

  JsonDecodeContext atModel(String name) =>
      JsonDecodeContext._(path, isMapKey, name, fieldName, _traversal);

  JsonDecodeContext index(int index) {
    if (index < 0) {
      throw ArgumentError.value(index, 'index', 'must not be negative');
    }
    return JsonDecodeContext._(
      '$path[$index]',
      false,
      model,
      fieldName,
      _traversal,
    );
  }

  JsonDecodeContext mapKey(Object? key) => JsonDecodeContext._(
    _appendJsonPathKey(path, key),
    true,
    model,
    fieldName,
    _traversal,
  );

  JsonDecodeContext mapValue(Object? key) => JsonDecodeContext._(
    _appendJsonPathKey(path, key),
    false,
    model,
    fieldName,
    _traversal,
  );

  T _decodeContainer<T>(
    Object container,
    DataforgeType<T> type,
    T Function(JsonDecodeContext context) decode,
  ) {
    final traversal = _traversal ?? _JsonDecodeTraversal();
    if (!traversal.enter(container, type)) {
      return fail(
        'Cyclic JSON input is not supported.',
        code: DataforgeJsonErrorCode.cyclicInput,
        expectedType: 'finite acyclic JSON value',
        actualType: dataforgeJsonActualType(container),
      );
    }
    final activeContext = identical(traversal, _traversal)
        ? this
        : JsonDecodeContext._(path, isMapKey, model, fieldName, traversal);
    try {
      return decode(activeContext);
    } finally {
      traversal.leave(container, type);
    }
  }

  Never fail(
    String message, {
    String code = DataforgeJsonErrorCode.decodeFailure,
    String? expectedType,
    String? actualType,
    String? model,
    String? field,
    Object? cause,
    StackTrace? stackTrace,
  }) {
    throw DataforgeDecodeException(
      message,
      code: code,
      path: path,
      expectedType: expectedType ?? 'valid JSON value',
      actualType: actualType ?? 'invalid JSON input',
      model: model ?? this.model,
      field: field ?? fieldName,
      cause: cause,
      stackTrace: stackTrace,
    );
  }
}

final class _JsonDecodeTraversal {
  static const _maximumDelegationsPerContainer = 64;

  final Map<Object, List<DataforgeType<dynamic>>> _activeTypesByContainer =
      HashMap<Object, List<DataforgeType<dynamic>>>.identity();

  bool enter<T>(Object container, DataforgeType<T> type) {
    final activeTypes = _activeTypesByContainer.putIfAbsent(
      container,
      () => <DataforgeType<dynamic>>[],
    );
    if (activeTypes.length >= _maximumDelegationsPerContainer ||
        activeTypes.any((active) => _sameDecodeWitnessNode(active, type))) {
      return false;
    }
    activeTypes.add(type);
    return true;
  }

  static bool _sameDecodeWitnessNode(
    DataforgeType<dynamic> left,
    DataforgeType<dynamic> right,
  ) {
    if (identical(left, right)) return true;
    if (left is DataforgeTypeIdentity && right is DataforgeTypeIdentity) {
      return (left as DataforgeTypeIdentity).dataforgeTypeId ==
          (right as DataforgeTypeIdentity).dataforgeTypeId;
    }
    if (left is DataforgeTypeIdentity || right is DataforgeTypeIdentity) {
      return false;
    }
    return false;
  }

  void leave<T>(Object container, DataforgeType<T> type) {
    final activeTypes = _activeTypesByContainer[container];
    if (activeTypes == null) return;
    final index = activeTypes.lastIndexWhere(
      (active) => identical(active, type),
    );
    if (index >= 0) activeTypes.removeAt(index);
    if (activeTypes.isEmpty) _activeTypesByContainer.remove(container);
  }
}

/// JSON encoding context.
///
/// The context is immutable. [field], [index], [mapKey], and [mapValue] create
/// new contexts carrying child paths.
final class JsonEncodeContext {
  const JsonEncodeContext({this.model})
    : path = r'$',
      isMapKey = false,
      fieldName = null;

  const JsonEncodeContext._(
    this.path,
    this.isMapKey,
    this.model,
    this.fieldName,
  );

  final String path;
  final String? model;
  final String? fieldName;

  /// Whether the current value is a JSON object key.
  final bool isMapKey;

  JsonEncodeContext field(String name, {String? schemaField}) =>
      JsonEncodeContext._(
        _appendJsonPathKey(path, name),
        false,
        model,
        schemaField ?? name,
      );

  JsonEncodeContext atModel(String name) =>
      JsonEncodeContext._(path, isMapKey, name, fieldName);

  JsonEncodeContext index(int index) {
    if (index < 0) {
      throw ArgumentError.value(index, 'index', 'must not be negative');
    }
    return JsonEncodeContext._('$path[$index]', false, model, fieldName);
  }

  JsonEncodeContext mapKey(Object? key) => JsonEncodeContext._(
    _appendJsonPathKey(path, key),
    true,
    model,
    fieldName,
  );

  JsonEncodeContext mapValue(Object? key) => JsonEncodeContext._(
    _appendJsonPathKey(path, key),
    false,
    model,
    fieldName,
  );

  Never fail(
    String message, {
    String code = DataforgeJsonErrorCode.encodeFailure,
    String? expectedType,
    String? actualType,
    String? model,
    String? field,
    Object? cause,
    StackTrace? stackTrace,
  }) {
    throw DataforgeEncodeException(
      message,
      code: code,
      path: path,
      expectedType: expectedType ?? 'JSON value',
      actualType: actualType ?? 'invalid JSON output',
      model: model ?? this.model,
      field: field ?? fieldName,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  /// Validates [value] as JSON while recursively copying and freezing containers.
  ///
  /// Custom witness output crosses this boundary so model-owned containers
  /// cannot leak and invalid objects fail before a later `jsonEncode` call.
  Object? snapshot(Object? value) =>
      _snapshotJsonValue(value, this, HashSet<Object>.identity());
}

/// Decodes and freezes a custom or built-in type through one strict boundary.
///
/// Generated code decodes fields only through this function, preserving the
/// current JSONPath for ordinary witness failures and preventing decoded values
/// from bypassing deep freeze.
T dataforgeFreeze<T>(
  DataforgeType<T> type,
  T value,
  JsonDecodeContext context,
) {
  try {
    return type.freeze(value);
  } on DataforgeDecodeException {
    rethrow;
  } catch (error, stackTrace) {
    return context.fail(
      'Failed to freeze $T (${error.runtimeType}).',
      expectedType: '$T',
      actualType: dataforgeJsonActualType(value),
      cause: error,
      stackTrace: stackTrace,
    );
  }
}

T dataforgeDecode<T>(
  DataforgeType<T> type,
  Object? json,
  JsonDecodeContext context,
) {
  try {
    T decode(JsonDecodeContext activeContext) => dataforgeFreeze(
      type,
      type.fromJson(json, activeContext),
      activeContext,
    );

    if (json is List || json is Map) {
      return context._decodeContainer(json as Object, type, decode);
    }
    return decode(context);
  } on DataforgeDecodeException {
    rethrow;
  } catch (error, stackTrace) {
    return context.fail(
      'Failed to decode $T (${error.runtimeType}).',
      expectedType: '$T',
      actualType: dataforgeJsonActualType(json),
      cause: error,
      stackTrace: stackTrace,
    );
  }
}

/// Copies external JSON objects into a map with standard String equality.
///
/// This boundary rejects equal duplicate String keys from identity or custom
/// comparator maps so generated `containsKey` and `[]` operations never inherit
/// caller-defined comparison semantics.
Map<String, Object?> dataforgeNormalizeJsonObject(
  Map<String, Object?> json,
  JsonDecodeContext context,
) {
  try {
    final result = <String, Object?>{};
    for (final entry in json.entries) {
      if (result.containsKey(entry.key)) {
        return context
            .field(entry.key)
            .fail(
              'Multiple JSON object entries use the same String key.',
              code: DataforgeJsonErrorCode.duplicateKey,
              expectedType: 'unique String key',
              actualType: 'String',
            );
      }
      result[entry.key] = entry.value;
    }
    return Map<String, Object?>.unmodifiable(result);
  } on DataforgeDecodeException {
    rethrow;
  } catch (error, stackTrace) {
    return context.fail(
      'Failed to read JSON object (${error.runtimeType}).',
      expectedType: 'Map<String, Object?>',
      actualType: dataforgeJsonActualType(json),
      cause: error,
      stackTrace: stackTrace,
    );
  }
}

/// Encodes, validates, and snapshots JSON output through one strict boundary.
///
/// Custom witnesses cannot return non-JSON objects or leak mutable containers.
Object? dataforgeEncode<T>(
  DataforgeType<T> type,
  T value,
  JsonEncodeContext context,
) {
  try {
    final encoded = type.toJson(value, context);
    if (encoded == null && null is! T) {
      return context.fail(
        'DataforgeType<$T> encoded a non-null value as null.',
        code: DataforgeJsonErrorCode.invalidJsonOutput,
        expectedType: 'non-null JSON value',
        actualType: 'null',
      );
    }
    return context.snapshot(encoded);
  } on DataforgeEncodeException {
    rethrow;
  } catch (error, stackTrace) {
    return context.fail(
      'Failed to encode $T (${error.runtimeType}).',
      expectedType: 'JSON value',
      actualType: dataforgeJsonActualType(value),
      cause: error,
      stackTrace: stackTrace,
    );
  }
}

/// Built-in provably immutable types and recursive combinators.
final class DataforgeTypes {
  DataforgeTypes._();

  static const DataforgeType<String> string = _StringType();
  static const DataforgeType<int> intType = _IntType();
  static const DataforgeType<double> doubleType = _DoubleType();
  static const DataforgeType<num> numType = _NumType();
  static const DataforgeType<bool> boolType = _BoolType();
  static const DataforgeType<DateTime> dateTime = _DateTimeType();
  static const DataforgeType<Duration> duration = _DurationType();

  /// Creates a strict enum witness whose wire value exactly matches [Enum.name].
  static DataforgeType<T> enumeration<T extends Enum>(List<T> values) =>
      _EnumType<T>(values);

  static DataforgeType<T?> nullable<T>(DataforgeType<T> valueType) =>
      _NullableType<T>(valueType);

  static DataforgeType<List<T>> list<T>(DataforgeType<T> elementType) =>
      _ListType<T>(elementType);

  static DataforgeType<Set<T>> set<T>(DataforgeType<T> elementType) =>
      _SetType<T>(elementType);

  static DataforgeType<Map<K, V>> map<K, V>(
    DataforgeType<K> keyType,
    DataforgeType<V> valueType,
  ) => _MapType<K, V>(keyType, valueType);
}

enum _BuiltInDataforgeTypeId {
  string,
  integer,
  doublePrecision,
  number,
  boolean,
  dateTime,
  duration,
  enumeration,
  nullable,
  list,
  set,
  map,
}

abstract class _IdentifiedDataforgeType<T> extends DataforgeType<T>
    implements DataforgeTypeIdentity, DataforgeTypeErasedEquality {
  const _IdentifiedDataforgeType();

  @override
  List<DataforgeType<dynamic>> get dataforgeTypeArguments => const [];

  @override
  bool dataforgeEqualsErased(
    DataforgeType<dynamic> other,
    Object? left,
    Object? right,
  ) {
    if (!dataforgeTypeEquals(this, other)) return false;
    return _tryDataforgeValueEquals(this, left, right) ??
        _tryDataforgeValueEquals(other, left, right) ??
        false;
  }
}

final class _StringType extends _IdentifiedDataforgeType<String> {
  const _StringType();

  @override
  Object get dataforgeTypeId => _BuiltInDataforgeTypeId.string;

  @override
  String freeze(String value) => value;

  @override
  bool equals(String left, String right) => left == right;

  @override
  int hash(String value) => value.hashCode;

  @override
  String fromJson(Object? json, JsonDecodeContext context) {
    if (json is String) return json;
    return _failExpected(context, 'String', json);
  }

  @override
  Object toJson(String value, JsonEncodeContext context) => value;
}

final class _IntType extends _IdentifiedDataforgeType<int> {
  const _IntType();

  @override
  Object get dataforgeTypeId => _BuiltInDataforgeTypeId.integer;

  @override
  int freeze(int value) => value;

  @override
  bool equals(int left, int right) => left == right;

  @override
  int hash(int value) => value.hashCode;

  @override
  int fromJson(Object? json, JsonDecodeContext context) {
    if (json is int) return json;
    if (context.isMapKey && json is String) {
      final parsed = int.tryParse(json);
      if (parsed != null) return parsed;
    }
    return _failExpected(context, 'int', json);
  }

  @override
  Object toJson(int value, JsonEncodeContext context) =>
      context.isMapKey ? value.toString() : value;
}

final class _DoubleType extends _IdentifiedDataforgeType<double> {
  const _DoubleType();

  @override
  Object get dataforgeTypeId => _BuiltInDataforgeTypeId.doublePrecision;

  @override
  double freeze(double value) => value;

  @override
  bool equals(double left, double right) =>
      left == right || (left.isNaN && right.isNaN);

  @override
  int hash(double value) => value.isNaN ? 0x7ff80000 : value.hashCode;

  @override
  double fromJson(Object? json, JsonDecodeContext context) {
    num? parsed;
    if (json is num) {
      parsed = json;
    } else if (context.isMapKey && json is String) {
      parsed = double.tryParse(json);
    }
    if (parsed == null || !parsed.isFinite) {
      return _failExpected(context, 'finite double', json);
    }
    return parsed.toDouble();
  }

  @override
  Object toJson(double value, JsonEncodeContext context) {
    if (!value.isFinite) {
      return context.fail(
        'Expected a finite double, got $value.',
        code: DataforgeJsonErrorCode.invalidJsonOutput,
        expectedType: 'finite double',
        actualType: 'double',
      );
    }
    return context.isMapKey ? value.toString() : value;
  }
}

final class _NumType extends _IdentifiedDataforgeType<num> {
  const _NumType();

  @override
  Object get dataforgeTypeId => _BuiltInDataforgeTypeId.number;

  @override
  num freeze(num value) => value;

  @override
  bool equals(num left, num right) =>
      left == right || (left.isNaN && right.isNaN);

  @override
  int hash(num value) => value.isNaN ? 0x7ff80000 : value.hashCode;

  @override
  num fromJson(Object? json, JsonDecodeContext context) {
    num? parsed;
    if (json is num) {
      parsed = json;
    } else if (context.isMapKey && json is String) {
      parsed = int.tryParse(json) ?? double.tryParse(json);
    }
    if (parsed == null || !parsed.isFinite) {
      return _failExpected(context, 'finite num', json);
    }
    return parsed;
  }

  @override
  Object toJson(num value, JsonEncodeContext context) {
    if (!value.isFinite) {
      return context.fail(
        'Expected a finite num, got $value.',
        code: DataforgeJsonErrorCode.invalidJsonOutput,
        expectedType: 'finite num',
        actualType: dataforgeJsonActualType(value),
      );
    }
    return context.isMapKey ? value.toString() : value;
  }
}

final class _BoolType extends _IdentifiedDataforgeType<bool> {
  const _BoolType();

  @override
  Object get dataforgeTypeId => _BuiltInDataforgeTypeId.boolean;

  @override
  bool freeze(bool value) => value;

  @override
  bool equals(bool left, bool right) => left == right;

  @override
  int hash(bool value) => value.hashCode;

  @override
  bool fromJson(Object? json, JsonDecodeContext context) {
    if (json is bool) return json;
    if (context.isMapKey && json is String) {
      if (json == 'true') return true;
      if (json == 'false') return false;
    }
    return _failExpected(context, 'bool', json);
  }

  @override
  Object toJson(bool value, JsonEncodeContext context) =>
      context.isMapKey ? value.toString() : value;
}

final class _DateTimeType extends _IdentifiedDataforgeType<DateTime> {
  const _DateTimeType();

  @override
  Object get dataforgeTypeId => _BuiltInDataforgeTypeId.dateTime;

  @override
  DateTime freeze(DateTime value) => value;

  @override
  bool equals(DateTime left, DateTime right) => left.isAtSameMomentAs(right);

  @override
  int hash(DateTime value) => value.microsecondsSinceEpoch.hashCode;

  @override
  DateTime fromJson(Object? json, JsonDecodeContext context) {
    if (json is! String) {
      return _failExpected(context, 'ISO-8601 DateTime string', json);
    }
    final value = _tryParseStrictDateTime(json);
    if (value != null) return value;
    return context.fail(
      'Expected a valid ISO-8601 DateTime string.',
      code: DataforgeJsonErrorCode.invalidValue,
      expectedType: 'ISO-8601 DateTime string with Z or explicit offset',
      actualType: 'String',
    );
  }

  @override
  Object toJson(DateTime value, JsonEncodeContext context) =>
      value.toUtc().toIso8601String();
}

final class _DurationType extends _IdentifiedDataforgeType<Duration> {
  const _DurationType();

  @override
  Object get dataforgeTypeId => _BuiltInDataforgeTypeId.duration;

  @override
  Duration freeze(Duration value) => value;

  @override
  bool equals(Duration left, Duration right) => left == right;

  @override
  int hash(Duration value) => value.hashCode;

  @override
  Duration fromJson(Object? json, JsonDecodeContext context) {
    int? microseconds;
    if (json is int) {
      microseconds = json;
    } else if (context.isMapKey && json is String) {
      microseconds = int.tryParse(json);
    }
    if (microseconds == null) {
      return _failExpected(context, 'Duration in microseconds', json);
    }
    return Duration(microseconds: microseconds);
  }

  @override
  Object toJson(Duration value, JsonEncodeContext context) =>
      context.isMapKey ? value.inMicroseconds.toString() : value.inMicroseconds;
}

final class _EnumType<T extends Enum> extends _IdentifiedDataforgeType<T> {
  _EnumType(List<T> values) : values = List<T>.unmodifiable(values) {
    if (values.isEmpty) {
      throw ArgumentError.value(values, 'values', 'must not be empty');
    }
    if (values.map((value) => value.name).toSet().length != values.length) {
      throw ArgumentError.value(
        values,
        'values',
        'must not contain duplicate enum values',
      );
    }
    final enumType = values.first.runtimeType;
    if (values.any((value) => value.runtimeType != enumType)) {
      throw ArgumentError.value(
        values,
        'values',
        'must all belong to the same enum type',
      );
    }
  }

  final List<T> values;

  @override
  Object get dataforgeTypeId {
    final names = values.map((value) => value.name).toList()..sort();
    return (
      _BuiltInDataforgeTypeId.enumeration,
      values.first.runtimeType,
      names.join(','),
    );
  }

  @override
  T freeze(T value) {
    if (values.contains(value)) return value;
    throw ArgumentError.value(
      value,
      'value',
      'must be included in the configured enum values',
    );
  }

  @override
  bool equals(T left, T right) => left == right;

  @override
  int hash(T value) => value.hashCode;

  @override
  T fromJson(Object? json, JsonDecodeContext context) {
    if (json is String) {
      for (final value in values) {
        if (value.name == json) return value;
      }
    }
    return context.fail(
      'Expected one of ${values.map((value) => value.name).join(', ')}, '
      'got ${json == null ? 'null' : json.runtimeType}.',
      code: DataforgeJsonErrorCode.invalidValue,
      expectedType: values.map((value) => value.name).join('|'),
      actualType: dataforgeJsonActualType(json),
    );
  }

  @override
  Object toJson(T value, JsonEncodeContext context) {
    if (!values.contains(value)) {
      return context.fail(
        'Expected one of ${values.map((value) => value.name).join(', ')}, '
        'got ${value.name}.',
        code: DataforgeJsonErrorCode.invalidJsonOutput,
        expectedType: values.map((value) => value.name).join('|'),
        actualType: value.runtimeType.toString(),
      );
    }
    return value.name;
  }
}

final class _NullableType<T> extends _IdentifiedDataforgeType<T?> {
  const _NullableType(this.valueType);

  final DataforgeType<T> valueType;

  @override
  Object get dataforgeTypeId => _BuiltInDataforgeTypeId.nullable;

  @override
  List<DataforgeType<dynamic>> get dataforgeTypeArguments =>
      List<DataforgeType<dynamic>>.unmodifiable([valueType]);

  @override
  T? freeze(T? value) => value == null ? null : valueType.freeze(value);

  @override
  bool equals(T? left, T? right) {
    if (left == null || right == null) return left == right;
    return valueType.equals(left, right);
  }

  @override
  bool dataforgeEqualsErased(
    DataforgeType<dynamic> other,
    Object? left,
    Object? right,
  ) {
    if (other is! _NullableType || !dataforgeTypeEquals(this, other)) {
      return false;
    }
    if (left == null || right == null) return left == right;
    return dataforgeValueEquals(valueType, other.valueType, left, right);
  }

  @override
  int hash(T? value) => value == null ? 0 : valueType.hash(value);

  @override
  T? fromJson(Object? json, JsonDecodeContext context) =>
      json == null ? null : _decodeChild(valueType, json, context);

  @override
  Object? toJson(T? value, JsonEncodeContext context) =>
      value == null ? null : _encodeChild(valueType, value, context);
}

final class _ListType<T> extends _IdentifiedDataforgeType<List<T>> {
  const _ListType(this.elementType);

  final DataforgeType<T> elementType;

  @override
  Object get dataforgeTypeId => _BuiltInDataforgeTypeId.list;

  @override
  List<DataforgeType<dynamic>> get dataforgeTypeArguments =>
      List<DataforgeType<dynamic>>.unmodifiable([elementType]);

  @override
  List<T> freeze(List<T> value) =>
      List<T>.unmodifiable(value.map(elementType.freeze));

  @override
  bool equals(List<T> left, List<T> right) {
    if (identical(left, right)) return true;
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (!elementType.equals(left[index], right[index])) return false;
    }
    return true;
  }

  @override
  bool dataforgeEqualsErased(
    DataforgeType<dynamic> other,
    Object? left,
    Object? right,
  ) {
    if (other is! _ListType ||
        !dataforgeTypeEquals(this, other) ||
        left is! List ||
        right is! List ||
        left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (!dataforgeValueEquals(
        elementType,
        other.elementType,
        left[index],
        right[index],
      )) {
        return false;
      }
    }
    return true;
  }

  @override
  int hash(List<T> value) => Object.hashAll(value.map(elementType.hash));

  @override
  List<T> fromJson(Object? json, JsonDecodeContext context) {
    if (json is! List) {
      return _failExpected(context, 'List', json);
    }
    final result = <T>[];
    for (var index = 0; index < json.length; index++) {
      result.add(_decodeChild(elementType, json[index], context.index(index)));
    }
    return List<T>.unmodifiable(result);
  }

  @override
  Object toJson(List<T> value, JsonEncodeContext context) {
    final result = <Object?>[];
    for (var index = 0; index < value.length; index++) {
      result.add(_encodeChild(elementType, value[index], context.index(index)));
    }
    return List<Object?>.unmodifiable(result);
  }
}

final class _SetType<T> extends _IdentifiedDataforgeType<Set<T>> {
  const _SetType(this.elementType);

  final DataforgeType<T> elementType;

  @override
  Object get dataforgeTypeId => _BuiltInDataforgeTypeId.set;

  @override
  List<DataforgeType<dynamic>> get dataforgeTypeArguments =>
      List<DataforgeType<dynamic>>.unmodifiable([elementType]);

  @override
  Set<T> freeze(Set<T> value) {
    final result = LinkedHashSet<T>(
      equals: elementType.equals,
      hashCode: elementType.hash,
      isValidKey: (value) => value is T,
    );
    for (final element in value) {
      final frozenElement = elementType.freeze(element);
      if (!result.add(frozenElement)) {
        throw ArgumentError.value(
          element,
          'value',
          'Multiple set elements are equal under the configured DataforgeType.',
        );
      }
    }
    return UnmodifiableSetView<T>(result);
  }

  @override
  bool equals(Set<T> left, Set<T> right) {
    if (identical(left, right)) return true;
    if (left.length != right.length) return false;
    final unmatched = right.toList(growable: false);
    final matched = List<bool>.filled(unmatched.length, false);
    for (final leftValue in left) {
      var found = false;
      for (var index = 0; index < unmatched.length; index++) {
        if (!matched[index] &&
            elementType.equals(leftValue, unmatched[index])) {
          matched[index] = true;
          found = true;
          break;
        }
      }
      if (!found) return false;
    }
    return true;
  }

  @override
  bool dataforgeEqualsErased(
    DataforgeType<dynamic> other,
    Object? left,
    Object? right,
  ) {
    if (other is! _SetType ||
        !dataforgeTypeEquals(this, other) ||
        left is! Set ||
        right is! Set ||
        left.length != right.length) {
      return false;
    }
    final unmatched = right.toList(growable: false);
    final matched = List<bool>.filled(unmatched.length, false);
    for (final leftValue in left) {
      var found = false;
      for (var index = 0; index < unmatched.length; index++) {
        if (!matched[index] &&
            dataforgeValueEquals(
              elementType,
              other.elementType,
              leftValue,
              unmatched[index],
            )) {
          matched[index] = true;
          found = true;
          break;
        }
      }
      if (!found) return false;
    }
    return true;
  }

  @override
  int hash(Set<T> value) =>
      Object.hashAllUnordered(value.map(elementType.hash));

  @override
  Set<T> fromJson(Object? json, JsonDecodeContext context) {
    if (json is! List) {
      return _failExpected(context, 'List for Set', json);
    }
    final result = LinkedHashSet<T>(
      equals: elementType.equals,
      hashCode: elementType.hash,
      isValidKey: (value) => value is T,
    );
    for (var index = 0; index < json.length; index++) {
      final element = _decodeChild(
        elementType,
        json[index],
        context.index(index),
      );
      if (!result.add(element)) {
        return context
            .index(index)
            .fail(
              'Multiple JSON array elements decode to the same set element.',
              code: DataforgeJsonErrorCode.duplicateElement,
              expectedType: 'unique decoded set element',
              actualType: dataforgeJsonActualType(element),
            );
      }
    }
    return UnmodifiableSetView<T>(result);
  }

  @override
  Object toJson(Set<T> value, JsonEncodeContext context) {
    final result = <Object?>[];
    var index = 0;
    for (final element in value) {
      result.add(_encodeChild(elementType, element, context.index(index)));
      index++;
    }
    return List<Object?>.unmodifiable(result);
  }
}

final class _MapType<K, V> extends _IdentifiedDataforgeType<Map<K, V>> {
  const _MapType(this.keyType, this.valueType);

  final DataforgeType<K> keyType;
  final DataforgeType<V> valueType;

  @override
  Object get dataforgeTypeId => _BuiltInDataforgeTypeId.map;

  @override
  List<DataforgeType<dynamic>> get dataforgeTypeArguments =>
      List<DataforgeType<dynamic>>.unmodifiable([keyType, valueType]);

  @override
  Map<K, V> freeze(Map<K, V> value) {
    final result = LinkedHashMap<K, V>(
      equals: keyType.equals,
      hashCode: keyType.hash,
      isValidKey: (value) => value is K,
    );
    for (final entry in value.entries) {
      final frozenKey = keyType.freeze(entry.key);
      if (result.containsKey(frozenKey)) {
        throw ArgumentError.value(
          entry.key,
          'value',
          'Multiple map keys are equal under the configured DataforgeType.',
        );
      }
      result[frozenKey] = valueType.freeze(entry.value);
    }
    return UnmodifiableMapView<K, V>(result);
  }

  @override
  bool equals(Map<K, V> left, Map<K, V> right) {
    if (identical(left, right)) return true;
    if (left.length != right.length) return false;
    final rightEntries = right.entries.toList(growable: false);
    final matched = List<bool>.filled(rightEntries.length, false);
    for (final leftEntry in left.entries) {
      var found = false;
      for (var index = 0; index < rightEntries.length; index++) {
        final rightEntry = rightEntries[index];
        if (!matched[index] &&
            keyType.equals(leftEntry.key, rightEntry.key) &&
            valueType.equals(leftEntry.value, rightEntry.value)) {
          matched[index] = true;
          found = true;
          break;
        }
      }
      if (!found) return false;
    }
    return true;
  }

  @override
  bool dataforgeEqualsErased(
    DataforgeType<dynamic> other,
    Object? left,
    Object? right,
  ) {
    if (other is! _MapType ||
        !dataforgeTypeEquals(this, other) ||
        left is! Map ||
        right is! Map ||
        left.length != right.length) {
      return false;
    }
    final rightEntries = right.entries.toList(growable: false);
    final matched = List<bool>.filled(rightEntries.length, false);
    for (final leftEntry in left.entries) {
      var found = false;
      for (var index = 0; index < rightEntries.length; index++) {
        final rightEntry = rightEntries[index];
        if (!matched[index] &&
            dataforgeValueEquals(
              keyType,
              other.keyType,
              leftEntry.key,
              rightEntry.key,
            ) &&
            dataforgeValueEquals(
              valueType,
              other.valueType,
              leftEntry.value,
              rightEntry.value,
            )) {
          matched[index] = true;
          found = true;
          break;
        }
      }
      if (!found) return false;
    }
    return true;
  }

  @override
  int hash(Map<K, V> value) => Object.hashAllUnordered(
    value.entries.map(
      (entry) =>
          Object.hash(keyType.hash(entry.key), valueType.hash(entry.value)),
    ),
  );

  @override
  Map<K, V> fromJson(Object? json, JsonDecodeContext context) {
    if (json is! Map) {
      return _failExpected(context, 'Map', json);
    }
    final result = LinkedHashMap<K, V>(
      equals: keyType.equals,
      hashCode: keyType.hash,
      isValidKey: (value) => value is K,
    );
    final rawKeys = <String>{};
    for (final entry in json.entries) {
      if (entry.key is! String) {
        return context
            .mapKey(entry.key)
            .fail(
              'JSON object keys must be String.',
              code: DataforgeJsonErrorCode.typeMismatch,
              expectedType: 'String',
              actualType: dataforgeJsonActualType(entry.key),
            );
      }
      final rawKey = entry.key as String;
      if (!rawKeys.add(rawKey)) {
        return context
            .mapKey(rawKey)
            .fail(
              'Multiple JSON object entries use the same String key.',
              code: DataforgeJsonErrorCode.duplicateKey,
              expectedType: 'unique String key',
              actualType: 'String',
            );
      }
      final decodedKey = _decodeChild(keyType, rawKey, context.mapKey(rawKey));
      if (result.containsKey(decodedKey)) {
        return context
            .mapKey(rawKey)
            .fail(
              'Multiple JSON keys decode to the same map key.',
              code: DataforgeJsonErrorCode.duplicateKey,
              expectedType: 'unique decoded map key',
              actualType: dataforgeJsonActualType(decodedKey),
            );
      }
      final decodedValue = _decodeChild(
        valueType,
        entry.value,
        context.mapValue(rawKey),
      );
      result[decodedKey] = decodedValue;
    }
    return UnmodifiableMapView<K, V>(result);
  }

  @override
  Object toJson(Map<K, V> value, JsonEncodeContext context) {
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      final encodedKey = _encodeChild(
        keyType,
        entry.key,
        context.mapKey(entry.key),
      );
      if (encodedKey is! String) {
        return context
            .mapKey(entry.key)
            .fail(
              'A map key witness must encode its value as String.',
              code: DataforgeJsonErrorCode.invalidJsonOutput,
              expectedType: 'String',
              actualType: dataforgeJsonActualType(encodedKey),
            );
      }
      if (result.containsKey(encodedKey)) {
        return context
            .mapKey(encodedKey)
            .fail(
              'Multiple map keys encode to "$encodedKey".',
              code: DataforgeJsonErrorCode.duplicateEncodedKey,
              expectedType: 'unique encoded String key',
              actualType: 'String',
            );
      }
      result[encodedKey] = _encodeChild(
        valueType,
        entry.value,
        context.mapValue(encodedKey),
      );
    }
    return Map<String, Object?>.unmodifiable(result);
  }
}

T _decodeChild<T>(
  DataforgeType<T> type,
  Object? json,
  JsonDecodeContext context,
) => dataforgeDecode(type, json, context);

Object? _encodeChild<T>(
  DataforgeType<T> type,
  T value,
  JsonEncodeContext context,
) => dataforgeEncode(type, value, context);

Object? _snapshotJsonValue(
  Object? value,
  JsonEncodeContext context,
  Set<Object> activeContainers,
) {
  if (value == null || value is String || value is bool || value is int) {
    return value;
  }
  if (value is double) {
    if (!value.isFinite) {
      return context.fail(
        'JSON numbers must be finite, got $value.',
        code: DataforgeJsonErrorCode.invalidJsonOutput,
        expectedType: 'finite JSON number',
        actualType: 'double',
      );
    }
    return value;
  }

  if (value is List) {
    if (!activeContainers.add(value)) {
      return context.fail(
        'Cyclic JSON List output is not supported.',
        code: DataforgeJsonErrorCode.invalidJsonOutput,
        expectedType: 'acyclic JSON List',
        actualType: 'List',
      );
    }
    try {
      return List<Object?>.unmodifiable(
        value.indexed.map(
          (entry) => _snapshotJsonValue(
            entry.$2,
            context.index(entry.$1),
            activeContainers,
          ),
        ),
      );
    } finally {
      activeContainers.remove(value);
    }
  }

  if (value is Map) {
    if (!activeContainers.add(value)) {
      return context.fail(
        'Cyclic JSON Map output is not supported.',
        code: DataforgeJsonErrorCode.invalidJsonOutput,
        expectedType: 'acyclic JSON Map',
        actualType: 'Map',
      );
    }
    try {
      final result = <String, Object?>{};
      for (final entry in value.entries) {
        final key = entry.key;
        if (key is! String) {
          return context
              .mapKey(key)
              .fail(
                'JSON object keys must be String, got ${key.runtimeType}.',
                code: DataforgeJsonErrorCode.invalidJsonOutput,
                expectedType: 'String',
                actualType: dataforgeJsonActualType(key),
              );
        }
        if (result.containsKey(key)) {
          return context
              .mapKey(key)
              .fail(
                'Multiple JSON object entries use the same String key.',
                code: DataforgeJsonErrorCode.duplicateEncodedKey,
                expectedType: 'unique String key',
                actualType: 'String',
              );
        }
        result[key] = _snapshotJsonValue(
          entry.value,
          context.mapValue(key),
          activeContainers,
        );
      }
      return Map<String, Object?>.unmodifiable(result);
    } finally {
      activeContainers.remove(value);
    }
  }

  return context.fail(
    'Expected a JSON value, got ${value.runtimeType}.',
    code: DataforgeJsonErrorCode.invalidJsonOutput,
    expectedType: 'JSON value',
    actualType: dataforgeJsonActualType(value),
  );
}

Never _failExpected(
  JsonDecodeContext context,
  String expected,
  Object? actual,
) => context.fail(
  'Expected $expected, got ${dataforgeJsonActualType(actual)}.',
  code: DataforgeJsonErrorCode.typeMismatch,
  expectedType: expected,
  actualType: dataforgeJsonActualType(actual),
);

/// Returns a JSON-domain type name stable across Dart VM and Web runtimes.
String dataforgeJsonActualType(Object? value) => switch (value) {
  null => 'null',
  bool() => 'bool',
  int() => 'int',
  double() => 'double',
  String() => 'String',
  List() => 'List',
  Map() => 'Map',
  _ => value.runtimeType.toString(),
};

final RegExp _strictDateTimePattern = RegExp(
  r'^([+-]?\d{4,6})-(\d{2})-(\d{2})'
  r'T(\d{2}):(\d{2}):(\d{2})'
  r'(?:[.,](\d{1,6}))?'
  r'(?:(?:[zZ])|([+-])(\d{2}):(\d{2}))$',
);

DateTime? _tryParseStrictDateTime(String source) {
  final match = _strictDateTimePattern.firstMatch(source);
  if (match == null) return null;

  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  if (month < 1 || month > 12) return null;
  final daysInMonth = switch (month) {
    2 => _isLeapYear(year) ? 29 : 28,
    4 || 6 || 9 || 11 => 30,
    _ => 31,
  };
  if (day < 1 || day > daysInMonth) return null;

  final hourSource = match.group(4);
  if (hourSource != null) {
    final hour = int.parse(hourSource);
    final minute = int.parse(match.group(5)!);
    final second = int.parse(match.group(6)!);
    if (hour > 23 || minute > 59 || second > 59) return null;

    final offsetHourSource = match.group(9);
    if (offsetHourSource != null) {
      final offsetHour = int.parse(offsetHourSource);
      final offsetMinute = int.parse(match.group(10)!);
      if (offsetHour > 14 ||
          offsetMinute > 59 ||
          (offsetHour == 14 && offsetMinute != 0)) {
        return null;
      }
    }
  }
  return DateTime.tryParse(source);
}

bool _isLeapYear(int year) =>
    year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);

String _appendJsonPathKey(String path, Object? key) {
  if (key is String && RegExp(r'^[A-Za-z_$][A-Za-z0-9_$]*$').hasMatch(key)) {
    return '$path.$key';
  }
  final String rendered;
  if (key == null) {
    rendered = 'null';
  } else if (key is String) {
    rendered = key;
  } else if (key is bool || key is int || key is double) {
    // Core primitive toString implementations are trusted and deterministic.
    rendered = key.toString();
  } else {
    // Never invoke user-defined toString while constructing an error path.
    rendered = '<${dataforgeJsonActualType(key)}>';
  }
  return '$path[${jsonEncode(rendered)}]';
}
