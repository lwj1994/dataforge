import 'package:dataforge_base/dataforge_base.dart';
import 'package:test/test.dart';

void main() {
  group('DataforgeException', () {
    test('toString without context', () {
      const ex = DataforgeException('something failed');
      expect(ex.toString(), 'DataforgeException: something failed');
      expect(ex.message, 'something failed');
      expect(ex.context, isNull);
    });

    test('toString with context', () {
      const ex = DataforgeException('failed', context: 'parsing User');
      final str = ex.toString();
      expect(str, contains('failed'));
      expect(str, contains('Context: parsing User'));
    });

    test('implements Exception', () {
      const ex = DataforgeException('test');
      expect(ex, isA<Exception>());
    });
  });

  group('UnsupportedTypeException', () {
    test('stores all fields', () {
      final ex = UnsupportedTypeException(
        unsupportedType: 'CustomWidget',
        fieldName: 'widget',
        supportedTypes: ['String', 'int', 'Enum', 'Dataforge'],
      );

      expect(ex.unsupportedType, 'CustomWidget');
      expect(ex.fieldName, 'widget');
      expect(ex.supportedTypes, contains('String'));
      expect(ex.supportedTypes, hasLength(4));
    });

    test('toString includes type and field info', () {
      final ex = UnsupportedTypeException(
        unsupportedType: 'Widget',
        fieldName: 'items',
        supportedTypes: ['String', 'int'],
      );

      final str = ex.toString();
      expect(str, contains('Widget'));
      expect(str, contains('items'));
      expect(str, contains('String, int'));
    });

    test('toString includes context when provided', () {
      final ex = UnsupportedTypeException(
        unsupportedType: 'Widget',
        fieldName: 'items',
        supportedTypes: ['String'],
        context: 'List<Widget> in class Wrapper',
      );

      expect(ex.toString(), contains('Context: List<Widget> in class Wrapper'));
    });

    test('extends DataforgeException', () {
      final ex = UnsupportedTypeException(
        unsupportedType: 'X',
        fieldName: 'f',
        supportedTypes: [],
      );
      expect(ex, isA<DataforgeException>());
      expect(ex, isA<Exception>());
    });
  });

  group('ParseException', () {
    test('toString without element', () {
      const ex = ParseException('parse failed');
      expect(ex.toString(), contains('parse failed'));
      expect(ex.element, isNull);
    });

    test('toString with element and context', () {
      const ex = ParseException(
        'invalid annotation',
        element: '@BadAnnotation',
        context: 'class User',
      );

      final str = ex.toString();
      expect(str, contains('invalid annotation'));
      expect(str, contains('Element: @BadAnnotation'));
      expect(str, contains('Context: class User'));
    });

    test('extends DataforgeException', () {
      const ex = ParseException('test');
      expect(ex, isA<DataforgeException>());
    });
  });
}
