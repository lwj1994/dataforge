import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:test/test.dart';

part 'datetime_nullable_auto_match_test.data.dart';

/// Test class for DateTime? auto-matching to DateTimeConverter
@Dataforge()
class DateTimeNullableAutoMatchTest with _DateTimeNullableAutoMatchTest {
  /// Nullable DateTime field that should auto-match to DateTimeNullableConverter
  @override
  final DateTime? createdAt;

  /// Non-nullable DateTime field that should auto-match to DateTimeConverter
  @override
  final DateTime updatedAt;

  /// Regular string field for comparison
  @override
  final String name;

  const DateTimeNullableAutoMatchTest({
    this.createdAt,
    required this.updatedAt,
    required this.name,
  });
  factory DateTimeNullableAutoMatchTest.fromJson(Map<String, dynamic> json) {
    return _DateTimeNullableAutoMatchTest.fromJson(json);
  }
}

void main() {
  group('DateTimeNullableAutoMatchTest', () {
    test('should auto-match DateTime? to DateTimeNullableConverter', () {
      // Use millisecond precision to avoid precision loss in JSON serialization
      final now = DateTime.fromMillisecondsSinceEpoch(
          DateTime.now().millisecondsSinceEpoch);
      final testData = DateTimeNullableAutoMatchTest(
        createdAt: now,
        updatedAt: now,
        name: 'test',
      );

      final json = testData.toJson();
      expect(json['createdAt'], isA<String>());
      expect(json['updatedAt'], isA<String>());
      expect(json['name'], equals('test'));

      final fromJson = DateTimeNullableAutoMatchTest.fromJson(json);
      expect(fromJson.createdAt, equals(now));
      expect(fromJson.updatedAt, equals(now));
      expect(fromJson.name, equals('test'));
    });

    test('should handle null DateTime?', () {
      final now = DateTime.fromMillisecondsSinceEpoch(
          DateTime.now().millisecondsSinceEpoch);
      final testData = DateTimeNullableAutoMatchTest(
        createdAt: null,
        updatedAt: now,
        name: 'test',
      );

      final json = testData.toJson();
      expect(json['createdAt'], isNull);
      expect(json['updatedAt'], isA<String>());

      final fromJson = DateTimeNullableAutoMatchTest.fromJson(json);
      expect(fromJson.createdAt, isNull);
      expect(fromJson.updatedAt, equals(now));
    });

    test('should handle empty string for DateTime?', () {
      final now = DateTime.fromMillisecondsSinceEpoch(
          DateTime.now().millisecondsSinceEpoch);
      final json = {
        'createdAt': '',
        'updatedAt': now.millisecondsSinceEpoch,
        'name': 'test',
      };

      final fromJson = DateTimeNullableAutoMatchTest.fromJson(json);
      expect(fromJson.createdAt, isNull);
      expect(fromJson.updatedAt, equals(now));
    });

    test('should handle "0" for DateTime?', () {
      final now = DateTime.fromMillisecondsSinceEpoch(
          DateTime.now().millisecondsSinceEpoch);
      final json = {
        'createdAt': '0',
        'updatedAt': now.millisecondsSinceEpoch,
        'name': 'test',
      };

      final fromJson = DateTimeNullableAutoMatchTest.fromJson(json);
      expect(fromJson.createdAt, isNotNull);
      expect(fromJson.updatedAt, equals(now));
    });
  });
}
