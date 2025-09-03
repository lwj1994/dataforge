import 'package:test/test.dart';
import 'package:dataforge_annotation/dataforge_annotation.dart';

/// Type converters test module
/// Contains: built-in converters, auto type matching tests
void runConvertersTests() {
  group('Converters Tests', () {
    group('Built-in Converters', () {
      group('DateTimeConverter', () {
        const converter = DateTimeConverter();

        test('should convert DateTime to ISO 8601 string', () {
          final dateTime = DateTime(2023, 12, 25, 10, 30, 45);
          final result = converter.toJson(dateTime);
          expect(result, equals('2023-12-25T10:30:45.000'));
        });

        test('should convert ISO 8601 string to DateTime', () {
          const isoString = '2023-12-25T10:30:45.000';
          final result = converter.fromJson(isoString);
          expect(result, equals(DateTime(2023, 12, 25, 10, 30, 45)));
        });

        test('should handle UTC DateTime', () {
          final dateTime = DateTime.utc(2023, 12, 25, 10, 30, 45);
          final jsonString = converter.toJson(dateTime);
          final backToDateTime = converter.fromJson(jsonString);
          expect(backToDateTime, equals(dateTime));
        });
      });

      group('DateTimeMillisecondsConverter', () {
        const converter = DateTimeMillisecondsConverter();

        test('should convert DateTime to milliseconds timestamp', () {
          final dateTime = DateTime(2023, 12, 25, 10, 30, 45);
          final result = converter.toJson(dateTime);
          expect(result, equals(dateTime.millisecondsSinceEpoch));
        });

        test('should convert milliseconds timestamp to DateTime', () {
          final timestamp =
              DateTime(2023, 12, 25, 10, 30, 45).millisecondsSinceEpoch;
          final result = converter.fromJson(timestamp);
          expect(result, equals(DateTime(2023, 12, 25, 10, 30, 45)));
        });
      });

      group('DurationConverter', () {
        const converter = DurationConverter();

        test('should convert Duration to microseconds', () {
          const duration = Duration(hours: 2, minutes: 30, seconds: 45);
          final result = converter.toJson(duration);
          expect(result, equals(duration.inMicroseconds));
        });

        test('should convert microseconds to Duration', () {
          const duration = Duration(hours: 2, minutes: 30, seconds: 45);
          final microseconds = duration.inMicroseconds;
          final result = converter.fromJson(microseconds);
          expect(result, equals(duration));
        });

        test('should handle zero duration', () {
          const duration = Duration.zero;
          final microseconds = converter.toJson(duration);
          final backToDuration = converter.fromJson(microseconds);
          expect(backToDuration, equals(Duration.zero));
        });
      });
    });

    group('Converter Integration', () {
      test('DateTimeConverter should be available', () {
        const converter = DateTimeConverter();
        expect(converter, isNotNull);
        expect(converter.runtimeType.toString(), equals('DateTimeConverter'));
      });

      test('DateTimeMillisecondsConverter should be available', () {
        const converter = DateTimeMillisecondsConverter();
        expect(converter, isNotNull);
        expect(converter.runtimeType.toString(),
            equals('DateTimeMillisecondsConverter'));
      });

      test('DurationConverter should be available', () {
        const converter = DurationConverter();
        expect(converter, isNotNull);
        expect(converter.runtimeType.toString(), equals('DurationConverter'));
      });
    });
  });
}

/// Main function for standalone test execution
void main() {
  runConvertersTests();
}
