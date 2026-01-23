// Test for DateTime converter

import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultDateTimeConverter', () {
    late DefaultDateTimeConverter converter;

    setUp(() {
      converter = const DefaultDateTimeConverter();
    });

    group('fromJson - milliseconds timestamps (13 digits)', () {
      test('converts 13-digit milliseconds timestamp correctly', () {
        final timestamp = 1737619200000; // 2026-01-23 08:00:00.000Z
        final result = converter.fromJson(timestamp);

        expect(result, isNotNull);
        expect(result!.millisecondsSinceEpoch, equals(1737619200000));
      });

      test('converts 13-digit string timestamp', () {
        final result = converter.fromJson('1737619200000');

        expect(result, isNotNull);
        expect(result!.millisecondsSinceEpoch, equals(1737619200000));
      });
    });

    group('fromJson - seconds timestamps (10 digits)', () {
      test('converts 10-digit seconds timestamp to milliseconds', () {
        final timestamp = 1737619200; // 2026-01-23 08:00:00.000Z in seconds
        final result = converter.fromJson(timestamp);

        expect(result, isNotNull);
        expect(result!.millisecondsSinceEpoch, equals(1737619200000));
      });

      test('converts 10-digit string timestamp', () {
        final result = converter.fromJson('1737619200');

        expect(result, isNotNull);
        expect(result!.millisecondsSinceEpoch, equals(1737619200000));
      });
    });

    group('fromJson - ISO 8601 date strings', () {
      test('parses ISO 8601 date string', () {
        final result = converter.fromJson('2026-01-23T08:00:00.000Z');

        expect(result, isNotNull);
        expect(result!.year, equals(2026));
        expect(result.month, equals(1));
        expect(result.day, equals(23));
      });

      test('parses date-only string', () {
        final result = converter.fromJson('2026-01-23');

        expect(result, isNotNull);
        expect(result!.year, equals(2026));
        expect(result.month, equals(1));
        expect(result.day, equals(23));
      });
    });

    group('fromJson - edge cases', () {
      test('returns null for null input', () {
        final result = converter.fromJson(null);
        expect(result, isNull);
      });

      test('returns DateTime as-is', () {
        final now = DateTime.now();
        final result = converter.fromJson(now);
        expect(result, equals(now));
      });

      test('returns null for invalid date string', () {
        final result = converter.fromJson('not a date');
        expect(result, isNull);
      });

      test('throws FormatException for ambiguous timestamp (1 digit)', () {
        expect(
          () => converter.fromJson(1),
          throwsFormatException,
        );
      });

      test('throws FormatException for ambiguous timestamp (3 digits)', () {
        expect(
          () => converter.fromJson(123),
          throwsFormatException,
        );
      });

      test('throws FormatException for ambiguous timestamp (9 digits)', () {
        expect(
          () => converter.fromJson(123456789),
          throwsFormatException,
        );
      });

      test('throws FormatException for ambiguous timestamp (12 digits)', () {
        expect(
          () => converter.fromJson(123456789012),
          throwsFormatException,
        );
      });

      test('throws FormatException for ambiguous timestamp (14+ digits)', () {
        expect(
          () => converter.fromJson(12345678901234),
          throwsFormatException,
        );
      });
    });

    group('toJson', () {
      test('converts DateTime to milliseconds timestamp string', () {
        final date = DateTime.fromMillisecondsSinceEpoch(1737619200000);
        final result = converter.toJson(date);

        expect(result, equals('1737619200000'));
      });

      test('returns null for null input', () {
        final result = converter.toJson(null);
        expect(result, isNull);
      });
    });

    group('round-trip conversions', () {
      test('milliseconds timestamp survives round-trip', () {
        final original = 1737619200000;
        final dateTime = converter.fromJson(original);
        final backToString = converter.toJson(dateTime);

        expect(backToString, equals(original.toString()));
      });

      test('seconds timestamp converts to milliseconds in round-trip', () {
        final originalSeconds = 1737619200;
        final dateTime = converter.fromJson(originalSeconds);
        final backToString = converter.toJson(dateTime);

        // Result should be in milliseconds
        expect(backToString, equals('1737619200000'));
      });

      test('ISO 8601 string converts to milliseconds timestamp', () {
        final isoString = '2026-01-23T08:00:00.000Z';
        final dateTime = converter.fromJson(isoString);
        final backToString = converter.toJson(dateTime);

        // Result should be milliseconds timestamp
        expect(backToString, isNotNull);
        expect(int.tryParse(backToString!), isNotNull);
      });
    });
  });
}
