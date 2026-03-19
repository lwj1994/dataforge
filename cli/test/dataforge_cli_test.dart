import 'dart:async';
import 'dart:io';

import 'package:dataforge_base/dataforge_base.dart';
import 'package:dataforge_cli/dataforge_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('generate', () {
    test('throws for missing explicit paths', () async {
      final missingPath =
          p.join(Directory.systemTemp.path, 'dataforge_missing_${DateTime.now().microsecondsSinceEpoch}.dart');

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

    test('detects imported enums across sibling directories', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('dataforge_cli_test_');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final roleFile = File(p.join(tempDir.path, 'lib', 'models', 'role.dart'));
      await roleFile.create(recursive: true);
      await roleFile.writeAsString('''
enum Role { admin, user }
''');

      final userFile = File(p.join(tempDir.path, 'lib', 'features', 'user.dart'));
      await userFile.create(recursive: true);
      await userFile.writeAsString('''
import 'package:dataforge_annotation/dataforge_annotation.dart';
import '../models/role.dart';

@Dataforge()
class User {
  final Role role;

  const User({required this.role});
}
''');

      final generatedFiles = await _runSilently(() => generate(userFile.path));
      final generatedFile = File(generatedFiles.single);
      final generated = await generatedFile.readAsString();

      expect(generated, contains('DefaultEnumConverter(Role.values).toJson(role)'));
      expect(
        generated,
        contains('DefaultEnumConverter(Role.values).fromJson('),
      );
      expect(generated, isNot(contains('Role.fromJson(')));
    });

    test('does not treat plain custom collection element types as Dataforge',
        () async {
      final tempDir =
          await Directory.systemTemp.createTemp('dataforge_cli_test_');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final itemFile =
          File(p.join(tempDir.path, 'lib', 'models', 'plain_item.dart'));
      await itemFile.create(recursive: true);
      await itemFile.writeAsString('''
class PlainItem {
  final String id;

  const PlainItem(this.id);
}
''');

      final wrapperFile =
          File(p.join(tempDir.path, 'lib', 'models', 'wrapper.dart'));
      await wrapperFile.create(recursive: true);
      await wrapperFile.writeAsString('''
import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'plain_item.dart';

@Dataforge()
class Wrapper {
  final List<PlainItem> items;

  const Wrapper({this.items = const []});
}
''');

      await expectLater(_runSilently(() => generate(wrapperFile.path)),
          throwsA(isA<UnsupportedTypeException>()));
    });

    test('inserts collection imports and part declarations in directive order',
        () async {
      final tempDir =
          await Directory.systemTemp.createTemp('dataforge_cli_test_');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final sourceFile =
          File(p.join(tempDir.path, 'lib', 'sample', 'example.dart'));
      await sourceFile.create(recursive: true);
      await sourceFile.writeAsString('''
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
      final tempDir =
          await Directory.systemTemp.createTemp('dataforge_cli_test_');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final sourceFile =
          File(p.join(tempDir.path, 'lib', 'sample', 'example.dart'));
      await sourceFile.create(recursive: true);
      await sourceFile.writeAsString('''
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
