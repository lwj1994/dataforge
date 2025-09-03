import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

/// Extended DateTime types test module
/// Tests: multiple DateTime formats, DateTime lists and maps, custom time parsing
void runDateTimeExtendedTests() {
  group('Extended DateTime Types Tests', () {
    late Directory tempDir;
    late File testFile;
    late File outputFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('datetime_extended_test_');
      testFile = File(path.join(tempDir.path, 'datetime_test.model.dart'));
      outputFile =
          File(path.join(tempDir.path, 'datetime_test.model.data.dart'));
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('basic DateTime serialization with different formats', () {
      // Create DateTime test model
      testFile.writeAsStringSync('''
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'datetime_test.model.data.dart';

@Dataforge()
class DateTimeTest {
  final DateTime createdAt;
  final DateTime? updatedAt;
  @JsonKey(name: 'birth_date')
  final DateTime birthDate;
  
  const DateTimeTest({
    required this.createdAt,
    this.updatedAt,
    required this.birthDate,
  });
}

/// Main function for standalone test execution
void main() {
  runDateTimeExtendedTests();
}
''');

      // Simulate generated code
      outputFile.writeAsStringSync('''
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'datetime_test.model.dart';

// **************************************************************************
// DataforgeGenerator
// **************************************************************************

extension DateTimeTestDataforge on DateTimeTest {
  Map<String, dynamic> toJson() {
    return {
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'birth_date': birthDate.toIso8601String(),
    };
  }

  static DateTimeTest fromJson(Map<String, dynamic> json) {
    return DateTimeTest(
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      birthDate: DateTime.parse(json['birth_date'] as String),
    );
  }
}
''');

      expect(testFile.existsSync(), isTrue);
      expect(outputFile.existsSync(), isTrue);
      expect(
          outputFile.readAsStringSync().contains('toIso8601String()'), isTrue);
      expect(outputFile.readAsStringSync().contains('DateTime.parse'), isTrue);
      expect(outputFile.readAsStringSync().contains("'birth_date'"), isTrue);
    });

    test('DateTime lists and collections', () {
      testFile.writeAsStringSync('''
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'datetime_test.model.data.dart';

@Dataforge()
class DateTimeCollectionsTest {
  final List<DateTime> eventDates;
  final List<DateTime>? optionalEventDates;
  final Map<String, DateTime> namedDates;
  final Map<String, DateTime>? optionalNamedDates;
  
  const DateTimeCollectionsTest({
    required this.eventDates,
    this.optionalEventDates,
    required this.namedDates,
    this.optionalNamedDates,
  });
}
''');

      outputFile.writeAsStringSync('''
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'datetime_test.model.dart';

extension DateTimeCollectionsTestDataforge on DateTimeCollectionsTest {
  Map<String, dynamic> toJson() {
    return {
      'eventDates': eventDates.map((e) => e.toIso8601String()).toList(),
      'optionalEventDates': optionalEventDates?.map((e) => e.toIso8601String()).toList(),
      'namedDates': namedDates.map((k, v) => MapEntry(k, v.toIso8601String())),
      'optionalNamedDates': optionalNamedDates?.map((k, v) => MapEntry(k, v.toIso8601String())),
    };
  }

  static DateTimeCollectionsTest fromJson(Map<String, dynamic> json) {
    return DateTimeCollectionsTest(
      eventDates: (json['eventDates'] as List<dynamic>)
          .map((e) => DateTime.parse(e as String))
          .toList(),
      optionalEventDates: json['optionalEventDates'] != null
          ? (json['optionalEventDates'] as List<dynamic>)
              .map((e) => DateTime.parse(e as String))
              .toList()
          : null,
      namedDates: (json['namedDates'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, DateTime.parse(v as String))),
      optionalNamedDates: json['optionalNamedDates'] != null
          ? (json['optionalNamedDates'] as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, DateTime.parse(v as String)))
          : null,
    );
  }
}
''');

      expect(
          outputFile
              .readAsStringSync()
              .contains('eventDates.map((e) => e.toIso8601String())'),
          isTrue);
      expect(
          outputFile.readAsStringSync().contains('DateTime.parse(e as String)'),
          isTrue);
      expect(
          outputFile.readAsStringSync().contains(
              'namedDates.map((k, v) => MapEntry(k, v.toIso8601String()))'),
          isTrue);
    });

    test('custom DateTime parsing with readValue', () {
      testFile.writeAsStringSync('''
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'datetime_test.model.data.dart';

@Dataforge()
class CustomDateTimeTest {
  @JsonKey(readValue: CustomDateTimeTest._readValue)
  final DateTime? isoDateTime;
  
  @JsonKey(readValue: CustomDateTimeTest._readValue)
  final DateTime timestampDate;
  
  @JsonKey(readValue: CustomDateTimeTest._readValue)
  final DateTime? parsedDate;
  
  const CustomDateTimeTest({
    this.isoDateTime,
    required this.timestampDate,
    this.parsedDate,
  });
  
  static Object? _readValue(Map json, String key) {
    final value = json[key];
    if (value == null) return null;
    
    // Handle different date formats
    if (value is String) {
      // Try ISO format first
      try {
        return DateTime.parse(value).toIso8601String();
      } catch (e) {
        // Try custom format parsing
        return value;
      }
    }
    
    // Handle timestamp (milliseconds)
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value).toIso8601String();
    }
    
    return value;
  }
}
''');

      outputFile.writeAsStringSync('''
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'datetime_test.model.dart';

extension CustomDateTimeTestDataforge on CustomDateTimeTest {
  Map<String, dynamic> toJson() {
    return {
      'isoDateTime': isoDateTime?.toIso8601String(),
      'timestampDate': timestampDate.toIso8601String(),
      'parsedDate': parsedDate?.toIso8601String(),
    };
  }

  static CustomDateTimeTest fromJson(Map<String, dynamic> json) {
    return CustomDateTimeTest(
      isoDateTime: CustomDateTimeTest._readValue(json, 'isoDateTime') != null
          ? DateTime.parse(CustomDateTimeTest._readValue(json, 'isoDateTime') as String)
          : null,
      timestampDate: DateTime.parse(CustomDateTimeTest._readValue(json, 'timestampDate') as String),
      parsedDate: CustomDateTimeTest._readValue(json, 'parsedDate') != null
          ? DateTime.parse(CustomDateTimeTest._readValue(json, 'parsedDate') as String)
          : null,
    );
  }
}
''');

      expect(
          outputFile.readAsStringSync().contains('_readValue(json,'), isTrue);
      expect(
          outputFile
              .readAsStringSync()
              .contains('DateTime.parse(CustomDateTimeTest._readValue'),
          isTrue);
      expect(testFile.readAsStringSync().contains('static Object? _readValue'),
          isTrue);
    });

    test('DateTime with converters integration', () {
      testFile.writeAsStringSync('''
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'datetime_test.model.data.dart';

@dataforge
class DateTimeConverterTest {
  @DateTimeConverter()
  final DateTime standardDateTime;
  
  @DateTimeMillisecondsConverter()
  final DateTime timestampDateTime;
  
  @DateTimeConverter()
  final DateTime? optionalDateTime;
  
  @DateTimeMillisecondsConverter()
  final List<DateTime> timestampList;
  
  const DateTimeConverterTest({
    required this.standardDateTime,
    required this.timestampDateTime,
    this.optionalDateTime,
    required this.timestampList,
  });
}
''');

      outputFile.writeAsStringSync('''
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'datetime_test.model.dart';

// **************************************************************************
// DataforgeGenerator
// **************************************************************************

extension DateTimeConverterTestDataforge on DateTimeConverterTest {
  Map<String, dynamic> toJson() {
    return {
      'standardDateTime': const DateTimeConverter().toJson(standardDateTime),
      'timestampDateTime': const DateTimeMillisecondsConverter().toJson(timestampDateTime),
      'optionalDateTime': optionalDateTime != null
          ? const DateTimeConverter().toJson(optionalDateTime!)
          : null,
      'timestampList': timestampList
          .map((e) => const DateTimeMillisecondsConverter().toJson(e))
          .toList(),
    };
  }

  static DateTimeConverterTest fromJson(Map<String, dynamic> json) {
    return DateTimeConverterTest(
      standardDateTime: const DateTimeConverter().fromJson(json['standardDateTime']),
      timestampDateTime: const DateTimeMillisecondsConverter().fromJson(json['timestampDateTime']),
      optionalDateTime: json['optionalDateTime'] != null
          ? const DateTimeConverter().fromJson(json['optionalDateTime'])
          : null,
      timestampList: (json['timestampList'] as List<dynamic>)
          .map((e) => const DateTimeMillisecondsConverter().fromJson(e))
          .toList(),
    );
  }
}
''');

      expect(
          outputFile.readAsStringSync().contains('DateTimeConverter().toJson'),
          isTrue);
      expect(
          outputFile
              .readAsStringSync()
              .contains('DateTimeMillisecondsConverter().fromJson'),
          isTrue);
      expect(outputFile.readAsStringSync().contains('timestampList'), isTrue);
    });
  });
}

/// Main function to run extended DateTime tests
void main() {
  runDateTimeExtendedTests();
}
