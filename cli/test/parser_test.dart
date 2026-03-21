import 'dart:async';
import 'dart:io';

import 'package:dataforge_cli/src/parser.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dataforge_parser_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<File> _writeSource(String filename, String content) async {
    final file = File('${tempDir.path}/$filename');
    await file.writeAsString(content);
    return file;
  }

  group('Parser', () {
    test('parseDartFile does not write debug output for valid files', () async {
      final file = await _writeSource('user.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class User {
  final String name;
  final int age;

  const User({required this.name, required this.age});
}
''');

      final output = <String>[];
      final result = await runZoned(
        () async => Parser(file.path).parseDartFile(),
        zoneSpecification: ZoneSpecification(
          print: (_, __, ___, String line) => output.add(line),
        ),
      );

      expect(result, isNotNull);
      expect(result!.classes, hasLength(1));
      expect(result.classes.single.fields, hasLength(2));
      expect(result.classes.single.fields[0].isRequired, isTrue);
      expect(result.classes.single.fields[1].isRequired, isTrue);
      expect(output, isEmpty);
    });

    test('marks positional constructor parameters as required', () async {
      final file = await _writeSource('user.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class User {
  final String name;
  final int age;

  const User(this.name, this.age);
}
''');

      final result = Parser(file.path).parseDartFile();
      expect(result, isNotNull);
      expect(result!.classes.single.fields[0].isRequired, isTrue);
      expect(result.classes.single.fields[1].isRequired, isTrue);
    });

    test('returns null for .data.dart files', () async {
      final file = await _writeSource('user.data.dart', '''
// Generated code
''');
      expect(Parser(file.path).parseDartFile(), isNull);
    });

    test('returns null for non-existent files', () {
      final result = runZoned(
        () => Parser('${tempDir.path}/nonexistent.dart').parseDartFile(),
        zoneSpecification: ZoneSpecification(
          print: (_, __, ___, ____) {},
        ),
      );
      expect(result, isNull);
    });

    test('returns null for files without Dataforge annotations', () async {
      final file = await _writeSource('plain.dart', '''
class Plain {
  final String name;
  Plain(this.name);
}
''');
      expect(Parser(file.path).parseDartFile(), isNull);
    });

    test('returns null for files with parse errors', () async {
      final file = await _writeSource('broken.dart', '''
class { invalid dart syntax
''');
      final result = runZoned(
        () => Parser(file.path).parseDartFile(),
        zoneSpecification: ZoneSpecification(
          print: (_, __, ___, ____) {},
        ),
      );
      expect(result, isNull);
    });

    test('parses multiple classes in one file', () async {
      final file = await _writeSource('multi.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class UserA {
  final String name;
  const UserA({required this.name});
}

@Dataforge()
class UserB {
  final int id;
  const UserB({required this.id});
}
''');

      final result = Parser(file.path).parseDartFile();
      expect(result, isNotNull);
      expect(result!.classes, hasLength(2));
      expect(result.classes[0].name, 'UserA');
      expect(result.classes[1].name, 'UserB');
    });

    test('skips static fields', () async {
      final file = await _writeSource('fields.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class Item {
  final String name;
  static const String type = 'item';

  const Item({required this.name});
}
''');

      final result = Parser(file.path).parseDartFile();
      expect(result, isNotNull);
      // static and const fields are skipped
      expect(result!.classes.single.fields, hasLength(1));
      expect(result.classes.single.fields[0].name, 'name');
    });

    test('detects default values from constructor', () async {
      final file = await _writeSource('defaults.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class Config {
  final String host;
  final int port;
  final bool enabled;

  const Config({
    this.host = 'localhost',
    this.port = 8080,
    this.enabled = true,
  });
}
''');

      final result = Parser(file.path).parseDartFile();
      expect(result, isNotNull);
      final fields = result!.classes.single.fields;
      expect(fields[0].defaultValue, "'localhost'");
      expect(fields[1].defaultValue, '8080');
      expect(fields[2].defaultValue, 'true');
    });

    test('detects nullable fields', () async {
      final file = await _writeSource('nullable.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class Profile {
  final String? bio;
  final int? age;
  final String name;

  const Profile({this.bio, this.age, required this.name});
}
''');

      final result = Parser(file.path).parseDartFile();
      expect(result, isNotNull);
      final fields = result!.classes.single.fields;
      expect(fields[0].type, 'String?');
      expect(fields[0].isRequired, isFalse);
      expect(fields[1].type, 'int?');
      expect(fields[2].type, 'String');
      expect(fields[2].isRequired, isTrue);
    });

    test('detects DateTime fields', () async {
      final file = await _writeSource('dates.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class Event {
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Event({required this.createdAt, this.updatedAt});
}
''');

      final result = Parser(file.path).parseDartFile();
      expect(result, isNotNull);
      final fields = result!.classes.single.fields;
      expect(fields[0].isDateTime, isTrue);
      expect(fields[0].type, 'DateTime');
      expect(fields[1].isDateTime, isTrue);
      expect(fields[1].type, 'DateTime?');
    });

    test('parses generic type parameters', () async {
      final file = await _writeSource('generic.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class Container<T, U extends num> {
  final T data;
  final U count;

  const Container({required this.data, required this.count});
}
''');

      final result = Parser(file.path).parseDartFile();
      expect(result, isNotNull);
      final params = result!.classes.single.genericParameters;
      expect(params, hasLength(2));
      expect(params[0].name, 'T');
      expect(params[0].bound, isNull);
      expect(params[1].name, 'U');
      expect(params[1].bound, 'num');
    });

    test('parses @JsonKey name annotation', () async {
      final file = await _writeSource('json_key.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class ApiUser {
  @JsonKey(name: 'user_name')
  final String name;
  @JsonKey(name: 'user_id')
  final int id;

  const ApiUser({required this.name, required this.id});
}
''');

      final result = Parser(file.path).parseDartFile();
      expect(result, isNotNull);
      final fields = result!.classes.single.fields;
      expect(fields[0].jsonKey, isNotNull);
      expect(fields[0].jsonKey!.name, 'user_name');
      expect(fields[1].jsonKey!.name, 'user_id');
    });

    test('parses @JsonKey ignore', () async {
      final file = await _writeSource('ignore.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class Partial {
  final String name;
  @JsonKey(ignore: true)
  final String? secret;

  const Partial({required this.name, this.secret});
}
''');

      final result = Parser(file.path).parseDartFile();
      expect(result, isNotNull);
      final fields = result!.classes.single.fields;
      expect(fields[0].jsonKey, isNull);
      expect(fields[1].jsonKey, isNotNull);
      expect(fields[1].jsonKey!.ignore, isTrue);
    });

    test('parses @JsonKey alternateNames', () async {
      final file = await _writeSource('alt_names.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class Flexible {
  @JsonKey(alternateNames: ['userName', 'user_name'])
  final String name;

  const Flexible({required this.name});
}
''');

      final result = Parser(file.path).parseDartFile();
      expect(result, isNotNull);
      final jsonKey = result!.classes.single.fields[0].jsonKey!;
      expect(jsonKey.alternateNames, hasLength(2));
      expect(jsonKey.alternateNames, contains('userName'));
      expect(jsonKey.alternateNames, contains('user_name'));
    });

    test('parses @JsonKey converter', () async {
      final file = await _writeSource('converter.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

class MyConverter extends JsonTypeConverter<DateTime, String> {
  const MyConverter();
  @override
  DateTime? fromJson(String? json) => null;
  @override
  String? toJson(DateTime? object) => null;
}

@Dataforge()
class WithConverter {
  @JsonKey(converter: MyConverter())
  final DateTime? date;

  const WithConverter({this.date});
}
''');

      final result = Parser(file.path).parseDartFile();
      expect(result, isNotNull);
      final jsonKey = result!.classes.single.fields[0].jsonKey!;
      expect(jsonKey.converter, isNotEmpty);
      expect(jsonKey.converter, contains('MyConverter'));
    });

    test('parses @JsonKey includeIfNull', () async {
      final file = await _writeSource('include_null.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class NullControl {
  @JsonKey(includeIfNull: false)
  final String? name;
  @JsonKey(includeIfNull: true)
  final int? count;

  const NullControl({this.name, this.count});
}
''');

      final result = Parser(file.path).parseDartFile();
      expect(result, isNotNull);
      final fields = result!.classes.single.fields;
      expect(fields[0].jsonKey!.includeIfNull, isFalse);
      expect(fields[1].jsonKey!.includeIfNull, isTrue);
    });

    test('parses @Dataforge options', () async {
      final file = await _writeSource('options.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge(includeFromJson: false, includeToJson: false, deepCopyWith: false)
class NoJson {
  final String name;
  const NoJson({required this.name});
}
''');

      final result = Parser(file.path).parseDartFile();
      expect(result, isNotNull);
      final cls = result!.classes.single;
      expect(cls.includeFromJson, isFalse);
      expect(cls.includeToJson, isFalse);
      expect(cls.deepCopyWith, isFalse);
    });

    test('parses custom mixin name', () async {
      final file = await _writeSource('mixin_name.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge(name: 'CustomMixin')
class Named {
  final String value;
  const Named({required this.value});
}
''');

      final result = Parser(file.path).parseDartFile();
      expect(result, isNotNull);
      expect(result!.classes.single.mixinName, 'CustomMixin');
    });

    test('parses collection fields', () async {
      final file = await _writeSource('collections.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class WithCollections {
  final List<String> names;
  final Map<String, int> scores;
  final Set<double> values;

  const WithCollections({
    this.names = const [],
    this.scores = const {},
    this.values = const {},
  });
}
''');

      final result = Parser(file.path).parseDartFile();
      expect(result, isNotNull);
      final fields = result!.classes.single.fields;
      expect(fields, hasLength(3));
      expect(fields[0].type, 'List<String>');
      expect(fields[1].type, 'Map<String, int>');
      expect(fields[2].type, 'Set<double>');
    });

    test('parses imports with aliases', () async {
      final file = await _writeSource('aliased.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart' as df;

@df.Dataforge()
class Aliased {
  final String name;
  const Aliased({required this.name});
}
''');

      final result = Parser(file.path).parseDartFile();
      expect(result, isNotNull);
      expect(result!.imports, isNotEmpty);
      final dfImport = result.imports.firstWhere(
        (i) => i.uri == 'package:dataforge_annotation/dataforge_annotation.dart',
      );
      expect(dfImport.alias, 'df');
    });

    test('handles legacy @DataClass annotation', () async {
      final file = await _writeSource('legacy.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@DataClass()
class Legacy {
  final String name;
  const Legacy({required this.name});
}
''');

      final result = Parser(file.path).parseDartFile();
      // DataClass is recognized by _isDataClassAnnotation
      expect(result, isNotNull);
      expect(result!.classes, hasLength(1));
      expect(result.classes.single.name, 'Legacy');
    });

    test('generates correct output path', () async {
      final file = await _writeSource('model.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class Model {
  final String name;
  const Model({required this.name});
}
''');

      final result = Parser(file.path).parseDartFile();
      expect(result, isNotNull);
      expect(result!.outputPath, endsWith('model.data.dart'));
      expect(result.outputPath, isNot(contains('.dart.data.dart')));
    });

    test('generates correct output path with custom directory', () async {
      final file = await _writeSource('model.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class Model {
  final String name;
  const Model({required this.name});
}
''');

      final outDir = '${tempDir.path}/generated';
      final result = Parser(file.path, outputDirectory: outDir).parseDartFile();
      expect(result, isNotNull);
      expect(result!.outputPath, startsWith(outDir));
      expect(result.outputPath, endsWith('model.data.dart'));
    });

    test('generates correct partOf declaration', () async {
      final file = await _writeSource('model.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class Model {
  final String name;
  const Model({required this.name});
}
''');

      final result = Parser(file.path).parseDartFile();
      expect(result, isNotNull);
      expect(result!.partOf, "part of 'model.dart';");
    });

    test('warns for non-nullable ignored field without default', () async {
      final file = await _writeSource('bad_ignore.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class BadIgnore {
  final String name;
  @JsonKey(ignore: true)
  final int count;

  const BadIgnore({required this.name, required this.count});
}
''');

      final output = <String>[];
      runZoned(
        () => Parser(file.path).parseDartFile(),
        zoneSpecification: ZoneSpecification(
          print: (_, __, ___, String line) => output.add(line),
        ),
      );

      expect(
        output.any((s) => s.contains('ignore') && s.contains('count')),
        isTrue,
      );
    });

    test('mixed required, optional, and default fields', () async {
      final file = await _writeSource('mixed.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class Mixed {
  final String required;
  final String? optional;
  final int defaulted;
  final bool? nullableDefault;

  const Mixed({
    required this.required,
    this.optional,
    this.defaulted = 42,
    this.nullableDefault = true,
  });
}
''');

      final result = Parser(file.path).parseDartFile();
      expect(result, isNotNull);
      final fields = result!.classes.single.fields;
      expect(fields, hasLength(4));

      expect(fields[0].name, 'required');
      expect(fields[0].isRequired, isTrue);
      expect(fields[0].type, 'String');

      expect(fields[1].name, 'optional');
      expect(fields[1].isRequired, isFalse);
      expect(fields[1].type, 'String?');

      expect(fields[2].name, 'defaulted');
      expect(fields[2].isRequired, isFalse);
      expect(fields[2].defaultValue, '42');

      expect(fields[3].name, 'nullableDefault');
      expect(fields[3].isRequired, isFalse);
      expect(fields[3].defaultValue, 'true');
    });
  });
}
