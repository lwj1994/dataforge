import 'dart:async';

// Test for DefaultEnumConverter

import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:test/test.dart';

enum TestStatus { pending, active, completed, archived }

enum Color { red, green, blue }

void main() {
  group('DefaultEnumConverter', () {
    late DefaultEnumConverter<TestStatus> converter;

    setUp(() {
      converter = const DefaultEnumConverter(TestStatus.values);
    });

    group('fromJson', () {
      test('converts matching string to enum value', () {
        expect(converter.fromJson('pending'), equals(TestStatus.pending));
        expect(converter.fromJson('active'), equals(TestStatus.active));
        expect(converter.fromJson('completed'), equals(TestStatus.completed));
        expect(converter.fromJson('archived'), equals(TestStatus.archived));
      });

      test('returns null for non-matching string', () {
        expect(converter.fromJson('invalid'), isNull);
        expect(converter.fromJson('PENDING'), isNull);
        expect(converter.fromJson('Pending'), isNull);
      });

      test('does not write to stdout for non-matching string', () {
        final printedLines = <String>[];

        final result = runZoned(
          () => converter.fromJson('invalid'),
          zoneSpecification: ZoneSpecification(
            print: (self, parent, zone, line) {
              printedLines.add(line);
            },
          ),
        );

        expect(result, isNull);
        expect(printedLines, isEmpty);
      });

      test('returns null for null input', () {
        expect(converter.fromJson(null), isNull);
      });

      test('returns null for empty string', () {
        expect(converter.fromJson(''), isNull);
      });
    });

    group('toJson', () {
      test('converts enum value to string name', () {
        expect(converter.toJson(TestStatus.pending), equals('pending'));
        expect(converter.toJson(TestStatus.active), equals('active'));
        expect(converter.toJson(TestStatus.completed), equals('completed'));
        expect(converter.toJson(TestStatus.archived), equals('archived'));
      });

      test('returns null for null input', () {
        expect(converter.toJson(null), isNull);
      });
    });

    group('round-trip conversions', () {
      test('survives round-trip for all values', () {
        for (final status in TestStatus.values) {
          final json = converter.toJson(status);
          final backToEnum = converter.fromJson(json);
          expect(backToEnum, equals(status));
        }
      });
    });

    group('with different enum types', () {
      test('works with Color enum', () {
        final colorConverter = const DefaultEnumConverter(Color.values);

        expect(colorConverter.fromJson('red'), equals(Color.red));
        expect(colorConverter.fromJson('green'), equals(Color.green));
        expect(colorConverter.fromJson('blue'), equals(Color.blue));

        expect(colorConverter.toJson(Color.red), equals('red'));
        expect(colorConverter.toJson(Color.green), equals('green'));
        expect(colorConverter.toJson(Color.blue), equals('blue'));
      });
    });

    group('edge cases', () {
      test('handles whitespace in input', () {
        expect(converter.fromJson(' pending'), isNull);
        expect(converter.fromJson('pending '), isNull);
        expect(converter.fromJson(' pending '), isNull);
      });

      test('is case-sensitive', () {
        expect(converter.fromJson('PENDING'), isNull);
        expect(converter.fromJson('Pending'), isNull);
        expect(converter.fromJson('pEnDiNg'), isNull);
      });
    });
  });
}
