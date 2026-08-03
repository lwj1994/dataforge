import 'dart:collection';

import 'package:collection/collection.dart';

import 'schema.dart';

const DeepCollectionEquality _detailsEquality = DeepCollectionEquality();

/// Publicly stable diagnostic code.
///
/// Human-readable messages may evolve. Automation, IDEs, and migration tools
/// should depend only on [value].
final class GenerationDiagnosticCode {
  final String value;

  const GenerationDiagnosticCode._(this.value);

  factory GenerationDiagnosticCode(String value) {
    if (!RegExp(r'^DF\d{4}$').hasMatch(value)) {
      throw ArgumentError.value(
        value,
        'value',
        'Generation diagnostic code must match DFdddd.',
      );
    }
    return GenerationDiagnosticCode._(value);
  }

  static const invalidModel = GenerationDiagnosticCode._('DF1001');
  static const mutableField = GenerationDiagnosticCode._('DF1002');
  static const constructorMismatch = GenerationDiagnosticCode._('DF1003');
  static const unsupportedType = GenerationDiagnosticCode._('DF1004');
  static const genericTypeWitnessRequired = GenerationDiagnosticCode._(
    'DF1005',
  );
  static const invalidJsonConfiguration = GenerationDiagnosticCode._('DF1006');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GenerationDiagnosticCode && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

enum GenerationDiagnosticSeverity { info, warning, error }

/// Analyzer-independent source location.
final class GenerationSourceLocation {
  final String uri;
  final int offset;
  final int length;
  final int line;
  final int column;

  const GenerationSourceLocation({
    required this.uri,
    required this.offset,
    required this.length,
    required this.line,
    required this.column,
  }) : assert(uri != ''),
       assert(offset >= 0),
       assert(length >= 0),
       assert(line >= 1),
       assert(column >= 1);

  Map<String, Object?> toMap() => {
    'uri': uri,
    'offset': offset,
    'length': length,
    'line': line,
    'column': column,
  };

  factory GenerationSourceLocation.fromMap(Map<String, Object?> map) {
    String readString(String key) {
      final value = map[key];
      if (value is String) return value;
      throw FormatException('Invalid diagnostic location "$key": $value.');
    }

    int readInt(String key) {
      final value = map[key];
      if (value is int) return value;
      throw FormatException('Invalid diagnostic location "$key": $value.');
    }

    return GenerationSourceLocation(
      uri: readString('uri'),
      offset: readInt('offset'),
      length: readInt('length'),
      line: readInt('line'),
      column: readInt('column'),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is GenerationSourceLocation &&
            other.uri == uri &&
            other.offset == offset &&
            other.length == length &&
            other.line == line &&
            other.column == column;
  }

  @override
  int get hashCode => Object.hash(uri, offset, length, line, column);
}

/// Stable, sortable, and versioned generation diagnostic.
///
/// [stableId] excludes the message, source offset, and details, so wording
/// changes and preceding source edits do not break deduplication of the same
/// schema target by IDEs or migration tools.
final class GenerationDiagnostic implements Comparable<GenerationDiagnostic> {
  static const int currentFormatVersion = 1;

  final int formatVersion;
  final GenerationDiagnosticCode code;
  final GenerationDiagnosticSeverity severity;
  final String message;
  final SchemaId? schemaId;
  final String? target;
  final GenerationSourceLocation? location;
  final Map<String, Object?> details;

  GenerationDiagnostic({
    this.formatVersion = currentFormatVersion,
    required this.code,
    required this.severity,
    required this.message,
    this.schemaId,
    this.target,
    this.location,
    Map<String, Object?> details = const {},
  }) : details = _freezeDiagnosticDetails(details),
       assert(formatVersion == currentFormatVersion),
       assert(message != '');

  /// Stable identity for automation; message and source span are excluded.
  String get stableId =>
      [code.value, schemaId?.canonicalName ?? '', target ?? ''].join('|');

  Map<String, Object?> toMap() => {
    'formatVersion': formatVersion,
    'code': code.value,
    'severity': severity.name,
    'message': message,
    'schemaId': schemaId?.toMap(),
    'target': target,
    'location': location?.toMap(),
    'details': details,
  };

  factory GenerationDiagnostic.fromMap(Map<String, Object?> map) {
    Object? require(String key) {
      if (!map.containsKey(key)) {
        throw FormatException('Missing diagnostic field "$key".');
      }
      return map[key];
    }

    final version = require('formatVersion');
    if (version is! int || version != currentFormatVersion) {
      throw FormatException(
        'Unsupported diagnostic format version $version; '
        'expected $currentFormatVersion.',
      );
    }

    final codeValue = require('code');
    final severityValue = require('severity');
    final messageValue = require('message');
    if (codeValue is! String) {
      throw FormatException('Invalid diagnostic code: $codeValue.');
    }
    if (severityValue is! String) {
      throw FormatException('Invalid diagnostic severity: $severityValue.');
    }
    if (messageValue is! String) {
      throw FormatException('Invalid diagnostic message: $messageValue.');
    }

    final severity = GenerationDiagnosticSeverity.values.where(
      (candidate) => candidate.name == severityValue,
    );
    if (severity.isEmpty) {
      throw FormatException('Unknown diagnostic severity: $severityValue.');
    }

    final schemaValue = map['schemaId'];
    final locationValue = map['location'];
    final targetValue = map['target'];
    final detailsValue = require('details');
    if (targetValue != null && targetValue is! String) {
      throw FormatException('Invalid diagnostic target: $targetValue.');
    }

    return GenerationDiagnostic(
      formatVersion: version,
      code: GenerationDiagnosticCode(codeValue),
      severity: severity.single,
      message: messageValue,
      schemaId: schemaValue == null
          ? null
          : SchemaId.fromMap(_stringMap(schemaValue, 'schemaId')),
      target: targetValue as String?,
      location: locationValue == null
          ? null
          : GenerationSourceLocation.fromMap(
              _stringMap(locationValue, 'location'),
            ),
      details: _stringMap(detailsValue, 'details'),
    );
  }

  static Map<String, Object?> _stringMap(Object? value, String field) {
    if (value is! Map) {
      throw FormatException('Invalid diagnostic $field: $value.');
    }
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) {
        throw FormatException('Invalid diagnostic $field key: $key.');
      }
      result[key] = entry.value;
    }
    return result;
  }

  @override
  int compareTo(GenerationDiagnostic other) {
    final severityComparison = _severityRank(
      severity,
    ).compareTo(_severityRank(other.severity));
    if (severityComparison != 0) return severityComparison;
    final codeComparison = code.value.compareTo(other.code.value);
    if (codeComparison != 0) return codeComparison;
    final idComparison = stableId.compareTo(other.stableId);
    if (idComparison != 0) return idComparison;
    return message.compareTo(other.message);
  }

  static int _severityRank(GenerationDiagnosticSeverity severity) {
    switch (severity) {
      case GenerationDiagnosticSeverity.error:
        return 0;
      case GenerationDiagnosticSeverity.warning:
        return 1;
      case GenerationDiagnosticSeverity.info:
        return 2;
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is GenerationDiagnostic &&
            other.formatVersion == formatVersion &&
            other.code == code &&
            other.severity == severity &&
            other.message == message &&
            other.schemaId == schemaId &&
            other.target == target &&
            other.location == location &&
            _detailsEquality.equals(other.details, details);
  }

  @override
  int get hashCode => Object.hashAll([
    formatVersion,
    code,
    severity,
    message,
    schemaId,
    target,
    location,
    _detailsEquality.hash(details),
  ]);

  @override
  String toString() {
    final schema = schemaId == null ? '' : ' ${schemaId!.canonicalName}';
    final targetText = target == null ? '' : ' $target';
    final source = location == null
        ? ''
        : ' (${location!.uri}:${location!.line}:${location!.column})';
    return '[${code.value}/${severity.name}]$schema$targetText: '
        '$message$source';
  }
}

Map<String, Object?> _freezeDiagnosticDetails(Map<String, Object?> details) =>
    _freezeDiagnosticMap(details, HashSet<Object>.identity(), r'$.details');

Map<String, Object?> _freezeDiagnosticMap(
  Map<Object?, Object?> value,
  Set<Object> active,
  String path,
) {
  if (!active.add(value)) {
    throw ArgumentError.value(value, 'details', 'contains a cycle at $path');
  }
  try {
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) {
        throw ArgumentError.value(
          key,
          'details',
          'contains a non-String map key at $path',
        );
      }
      result[key] = _freezeDiagnosticValue(entry.value, active, '$path.$key');
    }
    return Map<String, Object?>.unmodifiable(result);
  } finally {
    active.remove(value);
  }
}

Object? _freezeDiagnosticValue(Object? value, Set<Object> active, String path) {
  if (value == null || value is String || value is bool || value is int) {
    return value;
  }
  if (value is double) {
    if (value.isFinite) return value;
    throw ArgumentError.value(
      value,
      'details',
      'contains a non-finite number at $path',
    );
  }
  if (value is List) {
    if (!active.add(value)) {
      throw ArgumentError.value(value, 'details', 'contains a cycle at $path');
    }
    try {
      return List<Object?>.unmodifiable(
        value.indexed.map(
          (entry) =>
              _freezeDiagnosticValue(entry.$2, active, '$path[${entry.$1}]'),
        ),
      );
    } finally {
      active.remove(value);
    }
  }
  if (value is Map) {
    return _freezeDiagnosticMap(value, active, path);
  }
  throw ArgumentError.value(
    value,
    'details',
    'contains a non-transferable value at $path',
  );
}
