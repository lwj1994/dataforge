// Test file for built-in type converters

import 'package:test/test.dart';
import 'package:dataforge_annotation/dataforge_annotation.dart';

void main() {
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
      const duration = Duration(hours: 1, minutes: 30, seconds: 45);
      final result = converter.toJson(duration);
      expect(result, equals(duration.inMicroseconds));
    });

    test('should convert microseconds to Duration', () {
      const microseconds = 5445000000; // 1h 30m 45s in microseconds
      final result = converter.fromJson(microseconds);
      expect(
          result, equals(const Duration(hours: 1, minutes: 30, seconds: 45)));
    });
  });

  group('DurationMillisecondsConverter', () {
    const converter = DurationMillisecondsConverter();

    test('should convert Duration to milliseconds', () {
      const duration = Duration(hours: 1, minutes: 30, seconds: 45);
      final result = converter.toJson(duration);
      expect(result, equals(duration.inMilliseconds));
    });

    test('should convert milliseconds to Duration', () {
      const milliseconds = 5445000; // 1h 30m 45s in milliseconds
      final result = converter.fromJson(milliseconds);
      expect(
          result, equals(const Duration(hours: 1, minutes: 30, seconds: 45)));
    });
  });

  group('EnumConverter', () {
    test('should convert enum to string name', () {
      const converter = EnumConverter(TestEnum.values);
      final result = converter.toJson(TestEnum.second);
      expect(result, equals('second'));
    });

    test('should convert string name to enum', () {
      const converter = EnumConverter(TestEnum.values);
      final result = converter.fromJson('first');
      expect(result, equals(TestEnum.first));
    });

    test('should throw error for unknown enum value', () {
      const converter = EnumConverter(TestEnum.values);
      expect(
        () => converter.fromJson('unknown'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('EnumIndexConverter', () {
    test('should convert enum to index', () {
      const converter = EnumIndexConverter(TestEnum.values);
      final result = converter.toJson(TestEnum.third);
      expect(result, equals(2));
    });

    test('should convert index to enum', () {
      const converter = EnumIndexConverter(TestEnum.values);
      final result = converter.fromJson(1);
      expect(result, equals(TestEnum.second));
    });

    test('should throw error for out of range index', () {
      const converter = EnumIndexConverter(TestEnum.values);
      expect(
        () => converter.fromJson(10),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw error for negative index', () {
      const converter = EnumIndexConverter(TestEnum.values);
      expect(
        () => converter.fromJson(-1),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

// Test enum for converter testing
enum TestEnum {
  first,
  second,
  third,
}
