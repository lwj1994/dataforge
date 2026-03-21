import 'package:dataforge_base/dataforge_base.dart';
import 'package:test/test.dart';

void main() {
  group('TypeUtils.splitTopLevelTypeArguments', () {
    test('splits simple pair', () {
      expect(
        TypeUtils.splitTopLevelTypeArguments('String, int'),
        equals(['String', 'int']),
      );
    });

    test('single type returns one element', () {
      expect(
        TypeUtils.splitTopLevelTypeArguments('String'),
        equals(['String']),
      );
    });

    test('empty string returns empty list', () {
      expect(
        TypeUtils.splitTopLevelTypeArguments(''),
        equals([]),
      );
    });

    test('respects nested generics', () {
      expect(
        TypeUtils.splitTopLevelTypeArguments('String, List<int>'),
        equals(['String', 'List<int>']),
      );
    });

    test('respects deeply nested generics', () {
      expect(
        TypeUtils.splitTopLevelTypeArguments(
          'String, Map<String, List<int>>',
        ),
        equals(['String', 'Map<String, List<int>>']),
      );
    });

    test('handles three type arguments', () {
      expect(
        TypeUtils.splitTopLevelTypeArguments('String, int, bool'),
        equals(['String', 'int', 'bool']),
      );
    });

    test('respects parentheses (function types)', () {
      expect(
        TypeUtils.splitTopLevelTypeArguments(
          'void Function(int, String), bool',
        ),
        equals(['void Function(int, String)', 'bool']),
      );
    });

    test('respects braces', () {
      expect(
        TypeUtils.splitTopLevelTypeArguments(
          'Map<String, ({int a, int b})>, bool',
        ),
        equals(['Map<String, ({int a, int b})>', 'bool']),
      );
    });

    test('respects brackets', () {
      expect(
        TypeUtils.splitTopLevelTypeArguments(
          'List<List<int>>, Map<String, [int]>',
        ),
        equals(['List<List<int>>', 'Map<String, [int]>']),
      );
    });

    test('trims whitespace', () {
      expect(
        TypeUtils.splitTopLevelTypeArguments('  String  ,  int  '),
        equals(['String', 'int']),
      );
    });

    test('handles nullable types', () {
      expect(
        TypeUtils.splitTopLevelTypeArguments('String?, int?'),
        equals(['String?', 'int?']),
      );
    });

    test('handles complex nested Map', () {
      expect(
        TypeUtils.splitTopLevelTypeArguments(
          'String, Map<String, Map<String, List<int>>>',
        ),
        equals(['String', 'Map<String, Map<String, List<int>>>']),
      );
    });
  });

  group('TypeUtils.extractLastTypeArgument', () {
    test('extracts from Map<String, User>', () {
      expect(TypeUtils.extractLastTypeArgument('Map<String, User>'), 'User');
    });

    test('extracts from List<int>', () {
      expect(TypeUtils.extractLastTypeArgument('List<int>'), 'int');
    });

    test('returns type as-is when no generics', () {
      expect(TypeUtils.extractLastTypeArgument('String'), 'String');
    });

    test('extracts from Set<String>', () {
      expect(TypeUtils.extractLastTypeArgument('Set<String>'), 'String');
    });

    test('extracts from Map<String, List<int>>', () {
      expect(
        TypeUtils.extractLastTypeArgument('Map<String, List<int>>'),
        'List<int>',
      );
    });

    test('extracts from Map<String, Map<String, User>>', () {
      expect(
        TypeUtils.extractLastTypeArgument('Map<String, Map<String, User>>'),
        'Map<String, User>',
      );
    });

    test('handles nullable generic', () {
      expect(TypeUtils.extractLastTypeArgument('List<String?>'), 'String?');
    });

    test('handles nullable outer type', () {
      // The outer ? is not inside <>, so it stays as-is
      expect(TypeUtils.extractLastTypeArgument('List<int>?'), 'int');
    });

    test('returns full type for empty generics edge case', () {
      // Malformed but shouldn't crash
      expect(TypeUtils.extractLastTypeArgument('List<>'), '');
    });
  });

  group('TypeUtils.isDataClassAnnotation', () {
    test('recognizes Dataforge', () {
      expect(TypeUtils.isDataClassAnnotation('Dataforge'), isTrue);
    });

    test('recognizes dataforge', () {
      expect(TypeUtils.isDataClassAnnotation('dataforge'), isTrue);
    });

    test('recognizes DataClass', () {
      expect(TypeUtils.isDataClassAnnotation('DataClass'), isTrue);
    });

    test('recognizes dataClass', () {
      expect(TypeUtils.isDataClassAnnotation('dataClass'), isTrue);
    });

    test('recognizes prefixed df.Dataforge', () {
      expect(TypeUtils.isDataClassAnnotation('df.Dataforge'), isTrue);
    });

    test('recognizes prefixed alias.DataClass', () {
      expect(TypeUtils.isDataClassAnnotation('alias.DataClass'), isTrue);
    });

    test('rejects unrelated annotations', () {
      expect(TypeUtils.isDataClassAnnotation('JsonKey'), isFalse);
      expect(TypeUtils.isDataClassAnnotation('override'), isFalse);
      expect(TypeUtils.isDataClassAnnotation('immutable'), isFalse);
    });

    test('rejects partial matches', () {
      expect(TypeUtils.isDataClassAnnotation('MyDataforge'), isFalse);
      expect(TypeUtils.isDataClassAnnotation('DataforgeExtra'), isFalse);
    });
  });
}
