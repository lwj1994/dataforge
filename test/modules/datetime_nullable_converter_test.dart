import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:test/test.dart';

void main() {
  group('DateTimeConverter', () {
    final converter = const DefaultDateTimeConverter();
    final referenceDate = DateTime(2023, 1, 1, 12, 0, 0);
    final referenceTimestamp =
        referenceDate.millisecondsSinceEpoch; // 13 digits

    test('handles null input', () {
      expect(converter.fromJson(null), isNull);
    });

    test('handles int timestamp (13 digits)', () {
      final result = converter.fromJson(referenceTimestamp);
      expect(result, equals(referenceDate));
    });

    test('handles int timestamp with padding (10 digits - seconds)', () {
      // Convert to seconds (10 digits)
      final secondsTimestamp = (referenceTimestamp / 1000).floor();
      final result = converter.fromJson(secondsTimestamp);
      // Should pad to milliseconds
      expect(result,
          equals(DateTime.fromMillisecondsSinceEpoch(secondsTimestamp * 1000)));
    });

    test('handles string timestamp (13 digits)', () {
      final result = converter.fromJson(referenceTimestamp.toString());
      expect(result, equals(referenceDate));
    });

    test('handles string timestamp with padding (10 digits - seconds)', () {
      // Convert to seconds (10 digits)
      final secondsTimestamp = (referenceTimestamp / 1000).floor();
      final result = converter.fromJson(secondsTimestamp.toString());
      // Should pad to milliseconds
      expect(result,
          equals(DateTime.fromMillisecondsSinceEpoch(secondsTimestamp * 1000)));
    });

    test('handles ISO date string', () {
      final isoString = referenceDate.toIso8601String();
      final result = converter.fromJson(isoString);
      expect(result, equals(referenceDate));
    });

    test('handles custom object with toString', () {
      // Create a custom object that returns an ISO string when toString is called
      final customObject = _CustomDateObject(referenceDate);
      final result = converter.fromJson(customObject);
      expect(result, equals(referenceDate));
    });

    test('returns null for invalid input', () {
      expect(converter.fromJson('not a date'), isNull);
    });

    test('toJson returns milliseconds timestamp as string', () {
      final result = converter.toJson(referenceDate);
      expect(result, equals(referenceDate.millisecondsSinceEpoch.toString()));
    });

    test('toJson handles null', () {
      expect(converter.toJson(null), isNull);
    });
  });
}

/// Custom class for testing object conversion
class _CustomDateObject {
  final DateTime date;

  _CustomDateObject(this.date);

  @override
  String toString() => date.toIso8601String();
}
