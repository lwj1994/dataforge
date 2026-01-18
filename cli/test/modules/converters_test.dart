import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:test/test.dart';

/// Type converters test module
/// Contains: built-in converters, auto type matching tests
void runConvertersTests() {
  group('Converters Tests', () {
    group('Built-in Converters', () {
      group('DateTimeConverter', () {
        const converter = DefaultDateTimeConverter();

        test('should convert DateTime to milliseconds timestamp string', () {
          final dateTime = DateTime(2023, 12, 25, 10, 30, 45);
          final result = converter.toJson(dateTime);
          expect(result, equals(dateTime.millisecondsSinceEpoch.toString()));
        });

        test('should convert milliseconds timestamp string to DateTime', () {
          final timestamp = DateTime(2023, 12, 25, 10, 30, 45)
              .millisecondsSinceEpoch
              .toString();
          final result = converter.fromJson(timestamp);
          expect(result, equals(DateTime(2023, 12, 25, 10, 30, 45)));
        });

        test('should handle UTC DateTime', () {
          final dateTime = DateTime.utc(2023, 12, 25, 10, 30, 45);
          final isoString = converter.toJson(dateTime);
          final backToDateTime = converter.fromJson(isoString);
          // 使用 isDateTime 匹配器比较时间戳值而不是时区
          expect(backToDateTime?.millisecondsSinceEpoch,
              equals(dateTime.millisecondsSinceEpoch));
        });
      });
    });

    group('Converter Integration', () {
      test('DateTimeConverter should be available', () {
        const converter = DefaultDateTimeConverter();
        expect(converter, isNotNull);
        expect(converter.runtimeType.toString(),
            equals('DefaultDateTimeConverter'));
      });
    });
  });
}

/// Main function for standalone test execution
void main() {
  runConvertersTests();
}
