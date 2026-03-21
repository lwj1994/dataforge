// Test for parser-related data structures and model parsing

import 'package:dataforge_base/dataforge_base.dart';
import 'package:test/test.dart';

void main() {
  group('ParseResult', () {
    test('creates ParseResult with all fields', () {
      final classInfo = const ClassInfo(
        name: 'User',
        mixinName: '_\$User',
        fields: [],
      );

      final result = ParseResult(
        '/path/to/output.dart',
        'test_library',
        [classInfo],
        [],
        primaryClassName: 'User',
      );

      expect(result.outputPath, equals('/path/to/output.dart'));
      expect(result.partOf, equals('test_library'));
      expect(result.classes.length, equals(1));
      expect(result.primaryClassName, equals('User'));
    });

    test('toString returns meaningful representation', () {
      final result = ParseResult(
        '/path/to/output.dart',
        'test_library',
        [],
        [],
      );

      expect(result.toString(), contains('ParseResult'));
      expect(result.toString(), contains('/path/to/output.dart'));
    });
  });

  group('ClassInfo', () {
    test('creates ClassInfo with required fields', () {
      final classInfo = const ClassInfo(
        name: 'User',
        mixinName: '_\$User',
        fields: [],
      );

      expect(classInfo.name, equals('User'));
      expect(classInfo.mixinName, equals('_\$User'));
      expect(classInfo.includeFromJson, isTrue);
      expect(classInfo.includeToJson, isTrue);
      expect(classInfo.deepCopyWith, isTrue);
    });

    test('creates ClassInfo with custom options', () {
      final classInfo = const ClassInfo(
        name: 'User',
        mixinName: '_\$User',
        fields: [],
        includeFromJson: false,
        includeToJson: false,
        deepCopyWith: false,
        dataforgePrefix: 'df',
      );

      expect(classInfo.includeFromJson, isFalse);
      expect(classInfo.includeToJson, isFalse);
      expect(classInfo.deepCopyWith, isFalse);
      expect(classInfo.dataforgePrefix, equals('df'));
    });

    test('copyWith creates new instance with updated fields', () {
      final original = const ClassInfo(
        name: 'User',
        mixinName: '_\$User',
        fields: [],
      );

      final updated = original.copyWith(
        name: 'Person',
        includeFromJson: false,
      );

      expect(updated.name, equals('Person'));
      expect(updated.mixinName, equals('_\$User'));
      expect(updated.includeFromJson, isFalse);
    });

    test('toMap and fromMap round-trip', () {
      final original = const ClassInfo(
        name: 'User',
        mixinName: '_\$User',
        fields: [
          FieldInfo(
            name: 'name',
            type: 'String',
            isFinal: true,
            isFunction: false,
            isRecord: false,
            defaultValue: '',
          ),
        ],
        includeFromJson: true,
        includeToJson: false,
        deepCopyWith: true,
        genericParameters: [GenericParameter('T', 'Object')],
      );

      final map = original.toMap();
      final restored = ClassInfo.fromMap(map);

      expect(restored.name, equals(original.name));
      expect(restored.mixinName, equals(original.mixinName));
      expect(restored.fields.length, equals(original.fields.length));
      expect(restored.includeFromJson, equals(original.includeFromJson));
      expect(restored.includeToJson, equals(original.includeToJson));
      expect(restored.deepCopyWith, equals(original.deepCopyWith));
    });

    test('equality compares all fields', () {
      final a = const ClassInfo(
        name: 'User',
        mixinName: '_\$User',
        fields: [],
      );

      final b = const ClassInfo(
        name: 'User',
        mixinName: '_\$User',
        fields: [],
      );

      final c = const ClassInfo(
        name: 'Person',
        mixinName: '_\$User',
        fields: [],
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('equality includes dataforgePrefix', () {
      final a = const ClassInfo(
        name: 'User',
        mixinName: '_\$User',
        fields: [],
        dataforgePrefix: 'df',
      );

      final b = const ClassInfo(
        name: 'User',
        mixinName: '_\$User',
        fields: [],
        dataforgePrefix: null,
      );

      expect(a, isNot(equals(b)));
    });

    test('equality includes deepCopyWith', () {
      final a = const ClassInfo(
        name: 'User',
        mixinName: '_\$User',
        fields: [],
        deepCopyWith: true,
      );

      final b = const ClassInfo(
        name: 'User',
        mixinName: '_\$User',
        fields: [],
        deepCopyWith: false,
      );

      expect(a, isNot(equals(b)));
    });

    test('hashCode is consistent with equality', () {
      final a = const ClassInfo(
        name: 'User',
        mixinName: '_\$User',
        fields: [],
      );

      final b = const ClassInfo(
        name: 'User',
        mixinName: '_\$User',
        fields: [],
      );

      expect(a.hashCode, equals(b.hashCode));
    });

    test('fromMap handles missing optional fields', () {
      final info = ClassInfo.fromMap({
        'name': 'Test',
        'mixinName': '_Test',
      });

      expect(info.name, 'Test');
      expect(info.fields, isEmpty);
      expect(info.includeFromJson, isTrue);
      expect(info.includeToJson, isTrue);
      expect(info.deepCopyWith, isTrue);
      expect(info.genericParameters, isEmpty);
      expect(info.dataforgePrefix, isNull);
    });

    test('fromMap handles legacy fromMap field', () {
      final info = ClassInfo.fromMap({
        'name': 'Test',
        'mixinName': '_Test',
        'fromMap': false,
      });

      expect(info.includeFromJson, isFalse);
      expect(info.includeToJson, isFalse);
    });

    test('toString includes name and fields', () {
      const info = ClassInfo(
        name: 'User',
        mixinName: '_User',
        fields: [],
      );

      expect(info.toString(), contains('User'));
      expect(info.toString(), contains('_User'));
    });
  });

  group('FieldInfo', () {
    test('creates FieldInfo with required fields', () {
      final field = const FieldInfo(
        name: 'name',
        type: 'String',
        isFinal: true,
        isFunction: false,
        isRecord: false,
        defaultValue: '',
      );

      expect(field.name, equals('name'));
      expect(field.type, equals('String'));
      expect(field.isFinal, isTrue);
      expect(field.isFunction, isFalse);
      expect(field.isEnum, isFalse);
      expect(field.isDataforge, isFalse);
    });

    test('creates FieldInfo with all optional fields', () {
      final field = const FieldInfo(
        name: 'status',
        type: 'Status',
        isFinal: true,
        isFunction: false,
        isRecord: false,
        defaultValue: 'Status.active',
        isEnum: true,
        isRequired: true,
        jsonKey: JsonKeyInfo(
          name: 'user_status',
          alternateNames: ['status_code'],
          readValue: '',
          ignore: false,
        ),
      );

      expect(field.isEnum, isTrue);
      expect(field.isRequired, isTrue);
      expect(field.defaultValue, equals('Status.active'));
      expect(field.jsonKey?.name, equals('user_status'));
    });

    test('copyWith creates new instance with updated fields', () {
      final original = const FieldInfo(
        name: 'name',
        type: 'String',
        isFinal: true,
        isFunction: false,
        isRecord: false,
        defaultValue: '',
      );

      final updated = original.copyWith(
        type: 'String?',
        isRequired: true,
      );

      expect(updated.name, equals('name'));
      expect(updated.type, equals('String?'));
      expect(updated.isRequired, isTrue);
    });

    test('toMap and fromMap round-trip', () {
      final original = const FieldInfo(
        name: 'id',
        type: 'int',
        isFinal: true,
        isFunction: false,
        isRecord: false,
        defaultValue: '0',
        isRequired: true,
        jsonKey: JsonKeyInfo(
          name: 'user_id',
          alternateNames: ['id', 'uid'],
          readValue: '',
          ignore: false,
        ),
      );

      final map = original.toMap();
      final restored = FieldInfo.fromMap(map);

      expect(restored.name, equals(original.name));
      expect(restored.type, equals(original.type));
      expect(restored.defaultValue, equals(original.defaultValue));
      expect(restored.isRequired, equals(original.isRequired));
      expect(restored.jsonKey?.name, equals(original.jsonKey?.name));
    });

    test('equality compares all fields', () {
      final a = const FieldInfo(
        name: 'name',
        type: 'String',
        isFinal: true,
        isFunction: false,
        isRecord: false,
        defaultValue: '',
      );

      final b = const FieldInfo(
        name: 'name',
        type: 'String',
        isFinal: true,
        isFunction: false,
        isRecord: false,
        defaultValue: '',
      );

      final c = const FieldInfo(
        name: 'name',
        type: 'String?',
        isFinal: true,
        isFunction: false,
        isRecord: false,
        defaultValue: '',
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('asserts name must not be empty', () {
      expect(
        () => FieldInfo(
          name: '',
          type: 'String',
          isFinal: true,
          isFunction: false,
          isRecord: false,
          defaultValue: '',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('asserts type must not be empty', () {
      expect(
        () => FieldInfo(
          name: 'x',
          type: '',
          isFinal: true,
          isFunction: false,
          isRecord: false,
          defaultValue: '',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('asserts isEnum and isDataforge are mutually exclusive', () {
      expect(
        () => FieldInfo(
          name: 'x',
          type: 'Status',
          isFinal: true,
          isFunction: false,
          isRecord: false,
          defaultValue: '',
          isEnum: true,
          isDataforge: true,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('asserts isInnerEnum and isInnerDataforge are mutually exclusive', () {
      expect(
        () => FieldInfo(
          name: 'x',
          type: 'List<Status>',
          isFinal: true,
          isFunction: false,
          isRecord: false,
          defaultValue: '',
          isInnerEnum: true,
          isInnerDataforge: true,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('fromMap uses sensible defaults', () {
      final field = FieldInfo.fromMap({
        'name': 'test',
        'type': 'int',
      });

      expect(field.isFinal, isFalse);
      expect(field.isFunction, isFalse);
      expect(field.isRecord, isFalse);
      expect(field.isEnum, isFalse);
      expect(field.isDataforge, isFalse);
      expect(field.isRequired, isFalse);
      expect(field.isInnerEnum, isFalse);
      expect(field.isInnerDataforge, isFalse);
      expect(field.defaultValue, isEmpty);
      expect(field.jsonKey, isNull);
    });

    test('fromMap restores jsonKey', () {
      final field = FieldInfo.fromMap({
        'name': 'test',
        'type': 'String',
        'jsonKey': {
          'name': 'test_name',
          'alternateNames': ['tn'],
          'readValue': '',
          'ignore': false,
        },
      });

      expect(field.jsonKey, isNotNull);
      expect(field.jsonKey!.name, 'test_name');
      expect(field.jsonKey!.alternateNames, ['tn']);
    });

    test('hashCode differs for different fields', () {
      const a = FieldInfo(
        name: 'a',
        type: 'String',
        isFinal: true,
        isFunction: false,
        isRecord: false,
        defaultValue: '',
      );

      const b = FieldInfo(
        name: 'b',
        type: 'String',
        isFinal: true,
        isFunction: false,
        isRecord: false,
        defaultValue: '',
      );

      expect(a.hashCode, isNot(equals(b.hashCode)));
    });
  });

  group('JsonKeyInfo', () {
    test('creates JsonKeyInfo with required fields', () {
      final jsonKey = const JsonKeyInfo(
        name: 'user_name',
        alternateNames: [],
        readValue: '',
        ignore: false,
      );

      expect(jsonKey.name, equals('user_name'));
      expect(jsonKey.alternateNames, isEmpty);
      expect(jsonKey.ignore, isFalse);
    });

    test('creates JsonKeyInfo with all optional fields', () {
      final jsonKey = const JsonKeyInfo(
        name: 'user_name',
        alternateNames: ['userName', 'username'],
        readValue: 'customReader',
        ignore: false,
        converter: 'CustomConverter',
        includeIfNull: false,
        fromJson: 'parseUserName',
        toJson: 'serializeUserName',
      );

      expect(jsonKey.alternateNames, contains('userName'));
      expect(jsonKey.readValue, equals('customReader'));
      expect(jsonKey.converter, equals('CustomConverter'));
      expect(jsonKey.includeIfNull, isFalse);
      expect(jsonKey.fromJson, equals('parseUserName'));
      expect(jsonKey.toJson, equals('serializeUserName'));
    });

    test('copyWith creates new instance with updated fields', () {
      final original = const JsonKeyInfo(
        name: 'name',
        alternateNames: [],
        readValue: '',
        ignore: false,
      );

      final updated = original.copyWith(
        name: 'user_name',
        ignore: true,
      );

      expect(updated.name, equals('user_name'));
      expect(updated.ignore, isTrue);
    });

    test('toMap and fromMap round-trip', () {
      final original = const JsonKeyInfo(
        name: 'user_name',
        alternateNames: ['name', 'userName'],
        readValue: 'readUser',
        ignore: false,
        converter: 'UserConverter',
        includeIfNull: true,
        fromJson: 'parseUser',
        toJson: 'serializeUser',
      );

      final map = original.toMap();
      final restored = JsonKeyInfo.fromMap(map);

      expect(restored.name, equals(original.name));
      expect(restored.alternateNames, equals(original.alternateNames));
      expect(restored.readValue, equals(original.readValue));
      expect(restored.ignore, equals(original.ignore));
      expect(restored.converter, equals(original.converter));
      expect(restored.includeIfNull, equals(original.includeIfNull));
      expect(restored.fromJson, equals(original.fromJson));
      expect(restored.toJson, equals(original.toJson));
    });

    test('equality compares all fields', () {
      final a = const JsonKeyInfo(
        name: 'name',
        alternateNames: ['n'],
        readValue: '',
        ignore: false,
      );

      final b = const JsonKeyInfo(
        name: 'name',
        alternateNames: ['n'],
        readValue: '',
        ignore: false,
      );

      final c = const JsonKeyInfo(
        name: 'name',
        alternateNames: ['n', 'nm'],
        readValue: '',
        ignore: false,
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('GenericParameter', () {
    test('creates GenericParameter without bound', () {
      final param = const GenericParameter('T');

      expect(param.name, equals('T'));
      expect(param.bound, isNull);
      expect(param.toString(), equals('T'));
    });

    test('creates GenericParameter with bound', () {
      final param = const GenericParameter('T', 'num');

      expect(param.name, equals('T'));
      expect(param.bound, equals('num'));
      expect(param.toString(), equals('T extends num'));
    });

    test('equality compares name and bound', () {
      final a = const GenericParameter('T', 'num');
      final b = const GenericParameter('T', 'num');
      final c = const GenericParameter('T', 'Object');
      final d = const GenericParameter('T');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a, isNot(equals(d)));
    });

    test('hashCode is consistent with equality', () {
      final a = const GenericParameter('T', 'num');
      final b = const GenericParameter('T', 'num');

      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('ImportInfo', () {
    test('creates ImportInfo with required fields', () {
      final importInfo = const ImportInfo(uri: 'package:test/test.dart');

      expect(importInfo.uri, equals('package:test/test.dart'));
      expect(importInfo.alias, isNull);
      expect(importInfo.isDeferred, isFalse);
    });

    test('creates ImportInfo with alias', () {
      final importInfo = const ImportInfo(
        uri: 'package:test/test.dart',
        alias: 'tst',
      );

      expect(importInfo.alias, equals('tst'));
    });

    test('creates ImportInfo with show/hide combinators', () {
      final importInfo = const ImportInfo(
        uri: 'package:test/test.dart',
        showCombinators: ['Test', 'expect'],
        hideCombinators: ['skip'],
      );

      expect(importInfo.showCombinators, contains('Test'));
      expect(importInfo.hideCombinators, contains('skip'));
    });

    test('equality compares all fields', () {
      final a = const ImportInfo(
        uri: 'package:test/test.dart',
        alias: 'tst',
      );

      final b = const ImportInfo(
        uri: 'package:test/test.dart',
        alias: 'tst',
      );

      final c = const ImportInfo(
        uri: 'package:test/test.dart',
        alias: 'test',
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('asserts uri must not be empty', () {
      expect(
        () => ImportInfo(uri: ''),
        throwsA(isA<AssertionError>()),
      );
    });

    test('hashCode is consistent with equality', () {
      const a = ImportInfo(uri: 'package:a/a.dart', alias: 'a');
      const b = ImportInfo(uri: 'package:a/a.dart', alias: 'a');
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString includes all info', () {
      const info = ImportInfo(
        uri: 'package:test/test.dart',
        alias: 'tst',
        isDeferred: true,
      );
      final str = info.toString();
      expect(str, contains('package:test/test.dart'));
      expect(str, contains('tst'));
      expect(str, contains('true'));
    });
  });

  group('ParseResult', () {
    test('equality compares all fields', () {
      final a = ParseResult('out.dart', 'lib', [], []);
      final b = ParseResult('out.dart', 'lib', [], []);
      final c = ParseResult('other.dart', 'lib', [], []);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('equality includes primaryClassName', () {
      final a = ParseResult('out.dart', 'lib', [], [],
          primaryClassName: 'User');
      final b = ParseResult('out.dart', 'lib', [], [],
          primaryClassName: 'Post');

      expect(a, isNot(equals(b)));
    });

    test('hashCode is consistent with equality', () {
      final a = ParseResult('out.dart', 'lib', [], []);
      final b = ParseResult('out.dart', 'lib', [], []);
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('ClassInfo asserts', () {
    test('name must not be empty', () {
      expect(
        () => ClassInfo(name: '', mixinName: '_X', fields: []),
        throwsA(isA<AssertionError>()),
      );
    });

    test('mixinName must not be empty', () {
      expect(
        () => ClassInfo(name: 'X', mixinName: '', fields: []),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('GenericParameter asserts', () {
    test('name must not be empty', () {
      expect(
        () => GenericParameter(''),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
