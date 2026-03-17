// Test for SafeCasteUtil

import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:test/test.dart';

void main() {
  group('SafeCasteUtil', () {
    group('safeCast', () {
      group('String conversions', () {
        test('returns String as-is', () {
          expect(SafeCasteUtil.safeCast<String>('hello'), equals('hello'));
        });

        test('converts int to String', () {
          expect(SafeCasteUtil.safeCast<String>(42), equals('42'));
        });

        test('converts double to String', () {
          expect(SafeCasteUtil.safeCast<String>(3.14), equals('3.14'));
        });

        test('converts bool to String', () {
          expect(SafeCasteUtil.safeCast<String>(true), equals('true'));
        });

        test('returns null for null input', () {
          expect(SafeCasteUtil.safeCast<String>(null), isNull);
        });

        test('returns null for Map input', () {
          expect(SafeCasteUtil.safeCast<String>({'key': 'value'}), isNull);
        });

        test('returns null for List input', () {
          expect(SafeCasteUtil.safeCast<String>([1, 2, 3]), isNull);
        });
      });

      group('int conversions', () {
        test('returns int as-is', () {
          expect(SafeCasteUtil.safeCast<int>(42), equals(42));
        });

        test('converts double to int', () {
          expect(SafeCasteUtil.safeCast<int>(3.7), equals(3));
        });

        test('converts String to int', () {
          expect(SafeCasteUtil.safeCast<int>('42'), equals(42));
        });

        test('returns null for invalid String', () {
          expect(SafeCasteUtil.safeCast<int>('not a number'), isNull);
        });

        test('returns null for null input', () {
          expect(SafeCasteUtil.safeCast<int>(null), isNull);
        });
      });

      group('double conversions', () {
        test('returns double as-is', () {
          expect(SafeCasteUtil.safeCast<double>(3.14), equals(3.14));
        });

        test('converts int to double', () {
          expect(SafeCasteUtil.safeCast<double>(42), equals(42.0));
        });

        test('converts String to double', () {
          expect(SafeCasteUtil.safeCast<double>('3.14'), equals(3.14));
        });

        test('returns null for invalid String', () {
          expect(SafeCasteUtil.safeCast<double>('not a number'), isNull);
        });

        test('returns null for null input', () {
          expect(SafeCasteUtil.safeCast<double>(null), isNull);
        });
      });

      group('bool conversions', () {
        test('returns bool as-is', () {
          expect(SafeCasteUtil.safeCast<bool>(true), isTrue);
          expect(SafeCasteUtil.safeCast<bool>(false), isFalse);
        });

        test('converts String "true" to bool', () {
          expect(SafeCasteUtil.safeCast<bool>('true'), isTrue);
          expect(SafeCasteUtil.safeCast<bool>('TRUE'), isTrue);
          expect(SafeCasteUtil.safeCast<bool>('True'), isTrue);
        });

        test('converts String "false" to bool', () {
          expect(SafeCasteUtil.safeCast<bool>('false'), isFalse);
          expect(SafeCasteUtil.safeCast<bool>('FALSE'), isFalse);
        });

        test('converts String "1" to true', () {
          expect(SafeCasteUtil.safeCast<bool>('1'), isTrue);
        });

        test('converts String "0" to false', () {
          expect(SafeCasteUtil.safeCast<bool>('0'), isFalse);
        });

        test('converts String "yes" to true', () {
          expect(SafeCasteUtil.safeCast<bool>('yes'), isTrue);
          expect(SafeCasteUtil.safeCast<bool>('y'), isTrue);
        });

        test('converts String "no" to false', () {
          expect(SafeCasteUtil.safeCast<bool>('no'), isFalse);
          expect(SafeCasteUtil.safeCast<bool>('n'), isFalse);
        });

        test('converts num 1 to true', () {
          expect(SafeCasteUtil.safeCast<bool>(1), isTrue);
          expect(SafeCasteUtil.safeCast<bool>(1.0), isTrue);
        });

        test('converts num 0 to false', () {
          expect(SafeCasteUtil.safeCast<bool>(0), isFalse);
          expect(SafeCasteUtil.safeCast<bool>(0.0), isFalse);
        });

        test('returns null for null input', () {
          expect(SafeCasteUtil.safeCast<bool>(null), isNull);
        });
      });

      group('DateTime conversions', () {
        test('returns DateTime as-is', () {
          final now = DateTime.now();
          expect(SafeCasteUtil.safeCast<DateTime>(now), equals(now));
        });

        test('converts milliseconds timestamp to DateTime', () {
          final result = SafeCasteUtil.safeCast<DateTime>(1737619200000);
          expect(result, isNotNull);
          expect(result!.millisecondsSinceEpoch, equals(1737619200000));
        });

        test('converts seconds timestamp to DateTime', () {
          final result = SafeCasteUtil.safeCast<DateTime>(1737619200);
          expect(result, isNotNull);
          expect(result!.millisecondsSinceEpoch, equals(1737619200000));
        });

        test('converts ISO 8601 string to DateTime', () {
          final result = SafeCasteUtil.safeCast<DateTime>('2026-01-23');
          expect(result, isNotNull);
          expect(result!.year, equals(2026));
        });

        test('returns null for null input', () {
          expect(SafeCasteUtil.safeCast<DateTime>(null), isNull);
        });
      });

      group('Map conversions', () {
        test('casts Map to Map<String, dynamic>', () {
          final input = {'key': 'value', 'num': 42};
          final result = SafeCasteUtil.safeCast<Map<String, dynamic>>(input);
          expect(result, equals(input));
        });

        test('returns null for null input', () {
          expect(SafeCasteUtil.safeCast<Map<String, dynamic>>(null), isNull);
        });
      });

      group('List conversions', () {
        test('converts List to List<String>', () {
          final result = SafeCasteUtil.safeCast<List<String>>([1, 2, 3]);
          expect(result, equals(['1', '2', '3']));
        });

        test('converts List to List<int>', () {
          final result = SafeCasteUtil.safeCast<List<int>>(['1', '2', '3']);
          expect(result, equals([1, 2, 3]));
        });

        test('converts List to List<double>', () {
          final result =
              SafeCasteUtil.safeCast<List<double>>(['1.1', '2.2', '3.3']);
          expect(result, equals([1.1, 2.2, 3.3]));
        });

        test('returns null for null input', () {
          expect(SafeCasteUtil.safeCast<List<String>>(null), isNull);
        });
      });
    });

    group('readValue', () {
      test('reads existing key from map', () {
        final map = {'name': 'John', 'age': 30};
        expect(SafeCasteUtil.readValue<String>(map, 'name'), equals('John'));
        expect(SafeCasteUtil.readValue<int>(map, 'age'), equals(30));
      });

      test('returns null for missing key', () {
        final map = {'name': 'John'};
        expect(SafeCasteUtil.readValue<String>(map, 'missing'), isNull);
      });

      test('returns null for null map', () {
        expect(SafeCasteUtil.readValue<String>(null, 'key'), isNull);
      });

      test('converts types when reading', () {
        final map = {'value': '42'};
        expect(SafeCasteUtil.readValue<int>(map, 'value'), equals(42));
      });
    });

    group('readRequiredValue', () {
      test('reads existing key from map', () {
        final map = {'name': 'John', 'age': 30};
        expect(SafeCasteUtil.readRequiredValue<String>(map, 'name'),
            equals('John'));
      });

      test('throws ArgumentError for missing key', () {
        final map = {'name': 'John'};
        expect(
          () => SafeCasteUtil.readRequiredValue<String>(map, 'missing'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for null value', () {
        final map = <String, dynamic>{'name': null};
        expect(
          () => SafeCasteUtil.readRequiredValue<String>(map, 'name'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError with descriptive message', () {
        // Use a value that cannot be converted to the target type
        final map = <String, dynamic>{
          'items': [1, 2, 3]
        };
        try {
          SafeCasteUtil.readRequiredValue<String>(map, 'items');
          fail('Expected ArgumentError');
        } catch (e) {
          expect(e, isA<ArgumentError>());
          expect(e.toString(), contains('items'));
          expect(e.toString(), contains('String'));
          expect(e.toString(), isNot(contains('[1, 2, 3]')));
        }
      });
    });

    group('readObject', () {
      test('parses nested object', () {
        final json = {
          'name': 'Test',
          'value': 42,
        };
        final result = SafeCasteUtil.readObject(
          json,
          (m) => _TestModel(m['name'] as String, m['value'] as int),
        );
        expect(result, isNotNull);
        expect(result!.name, equals('Test'));
        expect(result.value, equals(42));
      });

      test('returns null for null input', () {
        final result = SafeCasteUtil.readObject(
          null,
          (m) => _TestModel(m['name'] as String, m['value'] as int),
        );
        expect(result, isNull);
      });

      test('returns null for non-Map input', () {
        final result = SafeCasteUtil.readObject(
          'not a map',
          (m) => _TestModel(m['name'] as String, m['value'] as int),
        );
        expect(result, isNull);
      });
    });

    group('readRequiredObject', () {
      test('parses nested object', () {
        final json = {'name': 'Test', 'value': 42};
        final result = SafeCasteUtil.readRequiredObject(
          json,
          (m) => _TestModel(m['name'] as String, m['value'] as int),
        );
        expect(result.name, equals('Test'));
      });

      test('throws ArgumentError for null input', () {
        expect(
          () => SafeCasteUtil.readRequiredObject(
            null,
            (m) => _TestModel(m['name'] as String, m['value'] as int),
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for non-Map input', () {
        expect(
          () => SafeCasteUtil.readRequiredObject(
            'not a map',
            (m) => _TestModel(m['name'] as String, m['value'] as int),
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('does not include raw payload in error message', () {
        try {
          SafeCasteUtil.readRequiredObject(
            'secret-token',
            (m) => _TestModel(m['name'] as String, m['value'] as int),
          );
          fail('Expected ArgumentError');
        } catch (e) {
          expect(e, isA<ArgumentError>());
          expect(e.toString(), contains('Expected: Map<String, dynamic>'));
          expect(e.toString(), isNot(contains('secret-token')));
        }
      });
    });

    group('readObjectList', () {
      test('parses list of objects', () {
        final json = [
          {'name': 'A', 'value': 1},
          {'name': 'B', 'value': 2},
        ];
        final result = SafeCasteUtil.readObjectList(
          json,
          (m) => _TestModel(m['name'] as String, m['value'] as int),
        );
        expect(result, isNotNull);
        expect(result!.length, equals(2));
        expect(result[0].name, equals('A'));
        expect(result[1].name, equals('B'));
      });

      test('returns null for null input', () {
        final result = SafeCasteUtil.readObjectList(
          null,
          (m) => _TestModel(m['name'] as String, m['value'] as int),
        );
        expect(result, isNull);
      });

      test('filters out non-Map items', () {
        final json = [
          {'name': 'A', 'value': 1},
          'invalid',
          {'name': 'B', 'value': 2},
        ];
        final result = SafeCasteUtil.readObjectList(
          json,
          (m) => _TestModel(m['name'] as String, m['value'] as int),
        );
        expect(result, isNotNull);
        expect(result!.length, equals(2));
      });
    });

    group('copyWithCast', () {
      test('returns value when type matches', () {
        expect(
          SafeCasteUtil.copyWithCast<String>('hello', 'field', 'default'),
          equals('hello'),
        );
      });

      test('returns default for undefined sentinel', () {
        expect(
          SafeCasteUtil.copyWithCast<String>(
              dataforgeUndefined, 'field', 'default'),
          equals('default'),
        );
      });

      test('returns default for type mismatch', () {
        expect(
          SafeCasteUtil.copyWithCast<String>(123, 'field', 'default'),
          equals('default'),
        );
      });

      test('converts num to double', () {
        expect(
          SafeCasteUtil.copyWithCast<double>(42, 'field', 0.0),
          equals(42.0),
        );
      });
    });

    group('copyWithCastNullable', () {
      test('returns value when type matches', () {
        expect(
          SafeCasteUtil.copyWithCastNullable<String>('hello', 'field'),
          equals('hello'),
        );
      });

      test('returns original for undefined sentinel', () {
        expect(
          SafeCasteUtil.copyWithCastNullable<String>(
              dataforgeUndefined, 'field', 'original'),
          equals('original'),
        );
      });

      test('returns null for null input', () {
        expect(
          SafeCasteUtil.copyWithCastNullable<String>(null, 'field'),
          isNull,
        );
      });

      test('returns original for type mismatch', () {
        expect(
          SafeCasteUtil.copyWithCastNullable<String>(123, 'field', 'original'),
          equals('original'),
        );
      });
    });
  });
}

class _TestModel {
  final String name;
  final int value;
  _TestModel(this.name, this.value);
}
