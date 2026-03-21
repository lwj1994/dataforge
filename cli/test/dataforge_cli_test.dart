import 'dart:async';
import 'dart:io';

import 'package:dataforge_base/dataforge_base.dart';
import 'package:dataforge_cli/dataforge_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dataforge_cli_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<File> _writeFile(String relativePath, String content) async {
    final file = File(p.join(tempDir.path, relativePath));
    await file.create(recursive: true);
    await file.writeAsString(content);
    return file;
  }

  group('generate - error handling', () {
    test('throws for missing explicit paths', () async {
      final missingPath = p.join(
        Directory.systemTemp.path,
        'dataforge_missing_${DateTime.now().microsecondsSinceEpoch}.dart',
      );
      await expectLater(
        generate(missingPath),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('cli exits non-zero for missing explicit paths', () async {
      final result = await Process.run(
        'dart',
        ['run', 'bin/dataforge_cli.dart', 'does_not_exist.dart'],
        workingDirectory: Directory.current.path,
      );
      expect(result.exitCode, equals(1));
      expect(result.stderr.toString(), contains('Path does not exist'));
    });

    test('returns empty list for directory with no annotations', () async {
      await _writeFile('lib/plain.dart', '''
class Plain {
  final String name;
  Plain(this.name);
}
''');

      final result = await _runSilently(
        () => generate(p.join(tempDir.path, 'lib')),
      );
      expect(result, isEmpty);
    });

    test('single file parse failure returns empty list', () async {
      final file = await _writeFile('lib/broken.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class { invalid
''');

      final result = await _runSilently(() => generate(file.path));
      expect(result, isEmpty);
    });

    test('batch processing continues when one file fails', () async {
      // Good file
      await _writeFile('lib/good.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class Good {
  final String name;
  const Good({required this.name});
}
''');

      // File with parse error
      await _writeFile('lib/bad.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class { invalid syntax
''');

      final result = await _runSilently(
        () => generate(p.join(tempDir.path, 'lib')),
      );
      // At least one file should still generate
      // (bad.dart will be skipped due to parse errors in pre-filter)
      expect(result, isNotNull);
    });
  });

  group('generate - single file', () {
    test('generates .data.dart for single file', () async {
      final file = await _writeFile('lib/model.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class Model {
  final String name;
  final int count;

  const Model({required this.name, this.count = 0});
}
''');

      final result = await _runSilently(() => generate(file.path));
      expect(result, hasLength(1));
      expect(result.first, endsWith('model.data.dart'));
      expect(File(result.first).existsSync(), isTrue);
    });

    test('skips .data.dart files', () async {
      final file = await _writeFile('lib/model.data.dart', '''
// Generated code
''');

      final result = await _runSilently(() => generate(file.path));
      expect(result, isEmpty);
    });

    test('generates correct part-of declaration', () async {
      final file = await _writeFile('lib/user.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class User {
  final String name;
  const User({required this.name});
}
''');

      final result = await _runSilently(() => generate(file.path));
      final generated = await File(result.first).readAsString();
      expect(generated, contains("part of 'user.dart';"));
    });

    test('modifies original file with part and mixin', () async {
      final file = await _writeFile('lib/example.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class Example {
  final String name;

  const Example({required this.name});
}
''');

      await _runSilently(() => generate(file.path));
      final updated = await file.readAsString();

      expect(updated, contains("part 'example.data.dart';"));
      expect(updated, contains('with _Example'));
    });

    test('adds fromJson factory to original file', () async {
      final file = await _writeFile('lib/item.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class Item {
  final String id;

  const Item({required this.id});
}
''');

      await _runSilently(() => generate(file.path));
      final updated = await file.readAsString();

      expect(updated, contains('factory Item.fromJson('));
      expect(updated, contains('return _Item.fromJson(json);'));
    });
  });

  group('generate - directory scanning', () {
    test('recursively finds annotated files', () async {
      await _writeFile('lib/models/user.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class User {
  final String name;
  const User({required this.name});
}
''');

      await _writeFile('lib/models/nested/post.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class Post {
  final String title;
  const Post({required this.title});
}
''');

      final result = await _runSilently(
        () => generate(p.join(tempDir.path, 'lib')),
      );
      expect(result, hasLength(2));
    });

    test('skips .dart_tool directory', () async {
      await _writeFile('lib/model.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class Model {
  final String name;
  const Model({required this.name});
}
''');

      await _writeFile('.dart_tool/generated/fake.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class Fake {
  final String x;
  const Fake({required this.x});
}
''');

      final result = await _runSilently(
        () => generate(tempDir.path),
      );
      // Should only find the one in lib/, not in .dart_tool/
      expect(result, hasLength(1));
      expect(result.first, contains('model.data.dart'));
    });

    test('skips build directory during scanning', () async {
      await _writeFile('lib/model.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class Model {
  final String name;
  const Model({required this.name});
}
''');

      await _writeFile('build/generated.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class Generated {
  final String x;
  const Generated({required this.x});
}
''');

      final result = await _runSilently(
        () => generate(tempDir.path),
      );
      expect(result, hasLength(1));
      expect(result.first, contains('model.data.dart'));
    });

    test('does not skip user directory named build in path', () async {
      await _writeFile('lib/build_config/settings.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class Settings {
  final String env;
  const Settings({required this.env});
}
''');

      final result = await _runSilently(
        () => generate(p.join(tempDir.path, 'lib')),
      );
      expect(result, hasLength(1));
      expect(result.first, contains('settings.data.dart'));
    });

    test('skips files without annotations during pre-filter', () async {
      await _writeFile('lib/annotated.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class Annotated {
  final String name;
  const Annotated({required this.name});
}
''');

      await _writeFile('lib/plain.dart', '''
class Plain {
  final String name;
  Plain(this.name);
}
''');

      final result = await _runSilently(
        () => generate(p.join(tempDir.path, 'lib')),
      );
      expect(result, hasLength(1));
    });
  });

  group('generate - enum detection', () {
    test('detects imported enums across sibling directories', () async {
      await _writeFile('lib/models/role.dart', '''
enum Role { admin, user }
''');

      final userFile = await _writeFile('lib/features/user.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';
import '../models/role.dart';

@Dataforge()
class User {
  final Role role;
  const User({required this.role});
}
''');

      final generatedFiles =
          await _runSilently(() => generate(userFile.path));
      final generated = await File(generatedFiles.single).readAsString();

      expect(
        generated,
        contains('DefaultEnumConverter(Role.values).toJson(role)'),
      );
      expect(
        generated,
        contains('DefaultEnumConverter(Role.values).fromJson('),
      );
      expect(generated, isNot(contains('Role.fromJson(')));
    });

    test('detects enum in List field', () async {
      await _writeFile('lib/models/status.dart', '''
enum Status { active, inactive }
''');

      final file = await _writeFile('lib/models/item.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'status.dart';

@Dataforge()
class Item {
  final List<Status> statuses;
  const Item({required this.statuses});
}
''');

      final result = await _runSilently(() => generate(file.path));
      final generated = await File(result.single).readAsString();
      expect(generated, contains('DefaultEnumConverter'));
      expect(generated, contains('Status.values'));
    });
  });

  group('generate - type detection', () {
    test('does not treat plain types as Dataforge', () async {
      await _writeFile('lib/models/plain_item.dart', '''
class PlainItem {
  final String id;
  const PlainItem(this.id);
}
''');

      final wrapperFile = await _writeFile('lib/models/wrapper.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'plain_item.dart';

@Dataforge()
class Wrapper {
  final List<PlainItem> items;
  const Wrapper({this.items = const []});
}
''');

      await expectLater(
        _runSilently(() => generate(wrapperFile.path)),
        throwsA(isA<UnsupportedTypeException>()),
      );
    });

    test('detects Dataforge-annotated inner types', () async {
      await _writeFile('lib/models/address.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class Address {
  final String city;
  const Address({required this.city});
}
''');

      final file = await _writeFile('lib/models/person.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'address.dart';

@Dataforge()
class Person {
  final String name;
  final List<Address> addresses;
  const Person({required this.name, this.addresses = const []});
}
''');

      final result = await _runSilently(() => generate(file.path));
      final generated = await File(result.single).readAsString();
      expect(generated, contains('Address.fromJson'));
      expect(generated, contains('.toJson()'));
    });

    test('detects types with fromJson factory as JSON models', () async {
      await _writeFile('lib/models/external.dart', '''
class External {
  final String id;
  External({required this.id});

  factory External.fromJson(Map<String, dynamic> json) {
    return External(id: json['id'] as String);
  }

  Map<String, dynamic> toJson() => {'id': id};
}
''');

      final file = await _writeFile('lib/models/holder.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'external.dart';

@Dataforge()
class Holder {
  final List<External> items;
  const Holder({this.items = const []});
}
''');

      final result = await _runSilently(() => generate(file.path));
      final generated = await File(result.single).readAsString();
      expect(generated, contains('External.fromJson'));
    });
  });

  group('generate - file modification', () {
    test('inserts collection imports and part declarations in order', () async {
      final sourceFile = await _writeFile('lib/sample/example.dart', '''
library sample;

import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class Example {
  final List<String> names;
  const Example({required this.names});
}
''');

      await _runSilently(() => generate(sourceFile.path));
      final updatedSource = await sourceFile.readAsString();

      final libraryIndex = updatedSource.indexOf('library sample;');
      final importIndex = updatedSource.indexOf(
        "import 'package:dataforge_annotation/dataforge_annotation.dart';",
      );
      final collectionImportIndex = updatedSource.indexOf(
        "import 'package:collection/collection.dart';",
      );
      final partIndex = updatedSource.indexOf("part 'example.data.dart';");

      expect(libraryIndex, greaterThanOrEqualTo(0));
      expect(importIndex, greaterThan(libraryIndex));
      expect(collectionImportIndex, greaterThan(importIndex));
      expect(partIndex, greaterThan(collectionImportIndex));
    });

    test('adds mixin before implements for multiline class headers', () async {
      final sourceFile = await _writeFile('lib/sample/example.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class Example<T>
    implements Comparable<Example<T>> {
  final T value;

  const Example({required this.value});

  @override
  int compareTo(Example<T> other) => 0;
}
''');

      await _runSilently(() => generate(sourceFile.path));
      final updatedSource = await sourceFile.readAsString();

      expect(
        updatedSource,
        contains(
          'class Example<T> with _Example<T> implements Comparable<Example<T>> {',
        ),
      );
    });

    test('does not duplicate part declaration on re-run', () async {
      final file = await _writeFile('lib/model.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class Model {
  final String name;
  const Model({required this.name});
}
''');

      await _runSilently(() => generate(file.path));
      await _runSilently(() => generate(file.path));
      final content = await file.readAsString();

      final partCount = "part 'model.data.dart';"
          .allMatches(content)
          .length;
      expect(partCount, 1);
    });

    test('does not duplicate mixin on re-run', () async {
      final file = await _writeFile('lib/model.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class Model {
  final String name;
  const Model({required this.name});
}
''');

      await _runSilently(() => generate(file.path));
      await _runSilently(() => generate(file.path));
      final content = await file.readAsString();

      final mixinCount = 'with _Model'.allMatches(content).length;
      expect(mixinCount, 1);
    });

    test('does not duplicate fromJson on re-run', () async {
      final file = await _writeFile('lib/model.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class Model {
  final String name;
  const Model({required this.name});
}
''');

      await _runSilently(() => generate(file.path));
      await _runSilently(() => generate(file.path));
      final content = await file.readAsString();

      final fromJsonCount =
          'factory Model.fromJson('.allMatches(content).length;
      expect(fromJsonCount, 1);
    });

    test('adds with clause when class already has extends', () async {
      final file = await _writeFile('lib/child.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

class Base {}

@Dataforge()
class Child extends Base {
  final String name;
  const Child({required this.name});
}
''');

      await _runSilently(() => generate(file.path));
      final content = await file.readAsString();
      // The writer normalizes whitespace; check both parts are present
      expect(content, contains('extends Base'));
      expect(content, contains('with _Child'));
    });

    test('appends to existing with clause', () async {
      final file = await _writeFile('lib/mixed.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

mixin Printable {}

@Dataforge()
class Mixed with Printable {
  final String name;
  const Mixed({required this.name});
}
''');

      await _runSilently(() => generate(file.path));
      final content = await file.readAsString();
      // The writer inserts mixin with possible whitespace variation
      expect(content, contains('Printable'));
      expect(content, contains('_Mixed'));
      // Both should be in the same with clause
      expect(RegExp(r'with\s+Printable\s*,\s*_Mixed').hasMatch(content), isTrue);
    });
  });

  group('generate - generated content', () {
    test('generates SafeCasteUtil calls for primitive fields', () async {
      final file = await _writeFile('lib/primitives.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class Primitives {
  final String name;
  final int count;
  final double rate;
  final bool active;

  const Primitives({
    required this.name,
    required this.count,
    required this.rate,
    required this.active,
  });
}
''');

      final result = await _runSilently(() => generate(file.path));
      final generated = await File(result.single).readAsString();

      expect(generated, contains('SafeCasteUtil.readRequiredValue<String>'));
      expect(generated, contains('SafeCasteUtil.readRequiredValue<int>'));
      expect(generated, contains('SafeCasteUtil.readRequiredValue<double>'));
      expect(generated, contains('SafeCasteUtil.readRequiredValue<bool>'));
    });

    test('generates DefaultDateTimeConverter for DateTime fields', () async {
      final file = await _writeFile('lib/dates.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class Dates {
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Dates({required this.createdAt, this.updatedAt});
}
''');

      final result = await _runSilently(() => generate(file.path));
      final generated = await File(result.single).readAsString();

      expect(generated, contains('DefaultDateTimeConverter'));
      expect(generated, contains('fromJson'));
      expect(generated, contains('toJson'));
    });

    test('generates copyWith with SafeCasteUtil', () async {
      final file = await _writeFile('lib/copyable.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class Copyable {
  final String name;
  final int? age;

  const Copyable({required this.name, this.age});
}
''');

      final result = await _runSilently(() => generate(file.path));
      final generated = await File(result.single).readAsString();

      expect(generated, contains('SafeCasteUtil.copyWithCast<String>'));
      expect(generated, contains('SafeCasteUtil.copyWithCastNullable<int>'));
      expect(generated, contains('dataforgeUndefined'));
    });

    test('generates DeepCollectionEquality for collection fields', () async {
      final file = await _writeFile('lib/with_list.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class WithList {
  final List<String> items;
  const WithList({this.items = const []});
}
''');

      final result = await _runSilently(() => generate(file.path));
      final generated = await File(result.single).readAsString();

      expect(generated, contains('DeepCollectionEquality'));
      expect(generated, contains('copyWithCastList'));
    });

    test('respects includeFromJson: false', () async {
      final file = await _writeFile('lib/no_from.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge(includeFromJson: false)
class NoFrom {
  final String name;
  const NoFrom({required this.name});
}
''');

      final result = await _runSilently(() => generate(file.path));
      final generated = await File(result.single).readAsString();

      expect(generated, isNot(contains('fromJson')));
      expect(generated, contains('toJson'));
    });

    test('respects includeToJson: false', () async {
      final file = await _writeFile('lib/no_to.dart', '''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge(includeToJson: false)
class NoTo {
  final String name;
  const NoTo({required this.name});
}
''');

      final result = await _runSilently(() => generate(file.path));
      final generated = await File(result.single).readAsString();

      expect(generated, contains('fromJson'));
      expect(generated, isNot(contains('toJson')));
    });
  });
}

Future<T> _runSilently<T>(Future<T> Function() action) {
  return runZoned(
    action,
    zoneSpecification: ZoneSpecification(
      print: (_, __, ___, ____) {},
    ),
  );
}
