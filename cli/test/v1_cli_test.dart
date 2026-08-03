import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dataforge_cli/dataforge_cli.dart';
import 'package:dataforge_cli/src/v1_pipeline.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final repositoryRoot = Directory.current.parent.absolute.path;

  group('v1 resolved CLI', () {
    late _Consumer consumer;

    setUp(() async {
      consumer = await _Consumer.create(repositoryRoot);
    });

    tearDown(() => consumer.dispose());

    test(
      'generates without editing source and check detects byte drift',
      () async {
        final source = await consumer.write('lib/model.dart', _v1Models);
        final before = await source.readAsBytes();
        final outputPath = consumer.path('lib/model.data.dart');
        final lockPath = consumer.path('.dart_tool/dataforge/generate.lock');

        await expectLater(
          generate(source.path, check: true),
          throwsA(isA<DataforgeCheckException>()),
        );
        expect(File(outputPath).existsSync(), isFalse);
        expect(File(lockPath).existsSync(), isFalse);
        expect(await source.readAsBytes(), before);

        final outputs = await generate(source.path);

        expect(outputs, hasLength(1));
        expect(await source.readAsBytes(), before);
        final output = File(outputs.single);
        final content = await output.readAsString();
        expect(
          content,
          startsWith('// GENERATED CODE - DO NOT MODIFY BY HAND'),
        );
        expect(content, contains('// dart format width=80'));
        expect(content, contains('// @dart=3.9'));
        expect(content, contains("part of 'model.dart';"));
        expect(content, contains('// DataforgeGenerator'));
        expect(content, contains('final class _Alpha extends Alpha'));
        expect(content, contains('final class _Beta extends Beta'));

        await generate(source.path, check: true);
        await output.writeAsString('$content\n// drift\n');
        final drifted = await output.readAsBytes();
        await expectLater(
          generate(source.path, check: true),
          throwsA(
            isA<DataforgeCheckException>().having(
              (error) => error.exitCode,
              'exitCode',
              4,
            ),
          ),
        );
        expect(await output.readAsBytes(), drifted);
        expect(await source.readAsBytes(), before);
      },
    );

    test(
      'check leaves an unfinished generation journal strictly untouched',
      () async {
        final source = await consumer.write('lib/model.dart', _v1Models);
        final output = await consumer.write(
          'lib/model.data.dart',
          '// partial transaction output\n',
        );
        final journal = await consumer.write(
          '.dart_tool/dataforge/generate-journal.json',
          '{"sentinel":"check must not recover this"}',
        );
        final sourceBefore = await source.readAsBytes();
        final outputBefore = await output.readAsBytes();
        final journalBefore = await journal.readAsBytes();

        await expectLater(
          generate(source.path, check: true),
          throwsA(
            isA<DataforgeCheckException>().having(
              (error) => error.exitCode,
              'exitCode',
              4,
            ),
          ),
        );

        expect(await source.readAsBytes(), sourceBefore);
        expect(await output.readAsBytes(), outputBefore);
        expect(await journal.readAsBytes(), journalBefore);
        expect(
          File(
            consumer.path('.dart_tool/dataforge/generate.lock'),
          ).existsSync(),
          isFalse,
        );
      },
    );

    test(
      'check rejects a dangling generation journal symlink without writes',
      () async {
        if (Platform.isWindows) return;
        final source = await consumer.write('lib/model.dart', _v1Models);
        final sourceBefore = await source.readAsBytes();
        final journalPath = consumer.path(
          '.dart_tool/dataforge/generate-journal.json',
        );
        final journalLink = Link(journalPath);
        final missingTarget = consumer.path('missing-generation-journal');
        await Directory(p.dirname(journalPath)).create(recursive: true);
        await journalLink.create(missingTarget);

        await expectLater(
          generate(source.path, check: true),
          throwsA(
            isA<DataforgeCheckException>().having(
              (error) => error.exitCode,
              'exitCode',
              4,
            ),
          ),
        );

        expect(await source.readAsBytes(), sourceBefore);
        expect(
          File(consumer.path('lib/model.data.dart')).existsSync(),
          isFalse,
        );
        expect(
          await FileSystemEntity.type(journalPath, followLinks: false),
          FileSystemEntityType.link,
        );
        expect(await journalLink.target(), missingTarget);
        expect(File(missingTarget).existsSync(), isFalse);
        expect(
          File(
            consumer.path('.dart_tool/dataforge/generate.lock'),
          ).existsSync(),
          isFalse,
        );
      },
    );

    test(
      'outer generation coordinates through the nested package transaction',
      () async {
        final nestedRoot = Directory(consumer.path('packages/nested'));
        await nestedRoot.create(recursive: true);
        await consumer.write('packages/nested/pubspec.yaml', '''
name: dataforge_nested_consumer
environment:
  sdk: '>=3.9.0 <4.0.0'
dependencies:
  dataforge_annotation:
    path: ${_yamlPath(p.join(repositoryRoot, 'annotation'))}
dependency_overrides:
  dataforge_annotation:
    path: ${_yamlPath(p.join(repositoryRoot, 'annotation'))}
  dataforge_base:
    path: ${_yamlPath(p.join(repositoryRoot, 'dataforge_base'))}
''');
        final pubGet = await Process.run(Platform.resolvedExecutable, [
          'pub',
          'get',
          '--offline',
        ], workingDirectory: nestedRoot.path);
        expect(
          pubGet.exitCode,
          0,
          reason: '${pubGet.stdout}\n${pubGet.stderr}',
        );

        final source = await consumer.write(
          'packages/nested/lib/model.dart',
          _nestedV1Model,
        );
        final output = File(
          consumer.path('packages/nested/lib/model.data.dart'),
        );
        await generate(source.path);
        final oldOutputBytes = await output.readAsBytes();
        final updatedSource = _nestedV1Model.replaceFirst(
          'required String id',
          'required String id, required int revision',
        );
        await source.writeAsString(updatedSource);
        final preparation = await const V1CliPipeline().prepare(
          candidateFiles: [source.path],
          projectRoot: nestedRoot.path,
          check: false,
          orphanScanRoot: null,
        );
        final newOutputBytes = preparation.outputs.single.bytes;
        expect(newOutputBytes, isNot(oldOutputBytes));

        final temporary = File(
          p.join(output.parent.path, '.model.data.dart.dataforge.test.0.tmp'),
        );
        final backup = File(
          p.join(output.parent.path, '.model.data.dart.dataforge.test.0.bak'),
        );
        final journal = File(
          p.join(
            nestedRoot.path,
            '.dart_tool',
            'dataforge',
            'generate-journal.json',
          ),
        );
        await temporary.writeAsBytes(newOutputBytes, flush: true);
        await journal.parent.create(recursive: true);
        await journal.writeAsString(
          '${jsonEncode({
            'version': 2,
            'entries': [
              {'targetPath': output.path, 'temporaryPath': temporary.path, 'backupPath': backup.path, 'originalHash': _sha256Bytes(oldOutputBytes), 'replacementHash': _sha256Bytes(newOutputBytes), 'deleteTarget': false, 'state': 'prepared'},
            ],
          })}\n',
          flush: true,
        );

        final sourceBeforeCheck = await source.readAsBytes();
        final targetBeforeCheck = await output.readAsBytes();
        final temporaryBeforeCheck = await temporary.readAsBytes();
        final journalBeforeCheck = await journal.readAsBytes();
        final nestedLock = File(
          p.join(nestedRoot.path, '.dart_tool', 'dataforge', 'generate.lock'),
        );
        final nestedLockBeforeCheck = await nestedLock.readAsBytes();
        final outerLock = File(
          consumer.path('.dart_tool/dataforge/generate.lock'),
        );
        expect(outerLock.existsSync(), isFalse);

        await expectLater(
          generate(consumer.root.path, check: true),
          throwsA(isA<DataforgeCheckException>()),
        );

        expect(await source.readAsBytes(), sourceBeforeCheck);
        expect(await output.readAsBytes(), targetBeforeCheck);
        expect(await temporary.readAsBytes(), temporaryBeforeCheck);
        expect(await journal.readAsBytes(), journalBeforeCheck);
        expect(await nestedLock.readAsBytes(), nestedLockBeforeCheck);
        expect(outerLock.existsSync(), isFalse);

        final outputs = await generate(consumer.root.path);

        expect(outputs, [output.path]);
        expect(await output.readAsBytes(), newOutputBytes);
        expect(temporary.existsSync(), isFalse);
        expect(backup.existsSync(), isFalse);
        expect(journal.existsSync(), isFalse);
        expect(nestedLock.existsSync(), isTrue);
        expect(outerLock.existsSync(), isFalse);
        await generate(nestedRoot.path, check: true);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'resolves an annotation constant and a model declared in a part',
      () async {
        final library = await consumer.write('lib/account.dart', r'''
import 'package:dataforge_annotation/dataforge_annotation.dart' as df;

part 'account_model.dart';
part 'account.data.dart';

const model = df.Dataforge();
''');
        final part = await consumer.write('lib/account_model.dart', r'''
part of 'account.dart';

@model
abstract final class Account with _$Account {
  const Account._();

  factory Account({required String id}) = _Account;

  factory Account.fromJson(Map<String, Object?> json) = _Account.fromJson;
}
''');
        final libraryBefore = await library.readAsBytes();
        final partBefore = await part.readAsBytes();

        final outputs = await generate(consumer.path('lib'));

        expect(outputs, hasLength(1));
        expect(outputs.single, consumer.path('lib/account.data.dart'));
        expect(await library.readAsBytes(), libraryBefore);
        expect(await part.readAsBytes(), partBefore);
        expect(
          await File(outputs.single).readAsString(),
          contains("part of 'account.dart';"),
        );
      },
    );

    test('prepares every v1 output before committing any file', () async {
      final valid = await consumer.write('lib/a_valid.dart', _singleV1Model);
      final invalid = await consumer.write('lib/z_invalid.dart', r'''
import 'package:dataforge_annotation/dataforge_annotation.dart' as df;

part 'z_invalid.data.dart';

@df.Dataforge()
abstract final class Invalid {
  const Invalid._();

  factory Invalid({required String id}) = _Invalid;

  factory Invalid.fromJson(Map<String, Object?> json) = _Invalid.fromJson;
}
''');
      final validBefore = await valid.readAsBytes();
      final invalidBefore = await invalid.readAsBytes();

      await expectLater(
        generate(consumer.path('lib')),
        throwsA(isA<DataforgeGenerationException>()),
      );

      expect(
        File(consumer.path('lib/a_valid.data.dart')).existsSync(),
        isFalse,
      );
      expect(
        File(consumer.path('lib/z_invalid.data.dart')).existsSync(),
        isFalse,
      );
      expect(await valid.readAsBytes(), validBefore);
      expect(await invalid.readAsBytes(), invalidBefore);
    });

    test('prepare 后源码变化时拒绝提交过期生成物', () async {
      final source = await consumer.write('lib/a_valid.dart', _singleV1Model);
      final preparation = await const V1CliPipeline().prepare(
        candidateFiles: [source.path],
        projectRoot: consumer.root.path,
        check: false,
        orphanScanRoot: null,
      );
      await source.writeAsString('$_singleV1Model\n// user saved\n');

      await expectLater(
        preparation.finish(check: false),
        throwsA(
          isA<DataforgeCheckException>()
              .having((error) => error.exitCode, 'exitCode', 4)
              .having(
                (error) => error.message,
                'message',
                contains('input changed'),
              ),
        ),
      );
      expect(
        File(consumer.path('lib/a_valid.data.dart')).existsSync(),
        isFalse,
      );
    });

    test('非 class 的 resolved Dataforge annotation 明确失败', () async {
      final source = await consumer.write('lib/not_class.dart', r'''
import 'package:dataforge_annotation/dataforge_annotation.dart' as df;

@df.Dataforge()
enum NotAClass { value }
''');

      await expectLater(
        generate(source.path),
        throwsA(
          isA<DataforgeGenerationException>()
              .having((error) => error.exitCode, 'exitCode', 3)
              .having(
                (error) => error.message,
                'message',
                contains('@Dataforge can only be applied to classes'),
              ),
        ),
      );
      expect(
        File(consumer.path('lib/not_class.data.dart')).existsSync(),
        isFalse,
      );
    });

    test('library 上的 resolved Dataforge annotation 同样明确失败', () async {
      final source = await consumer.write('lib/not_class_library.dart', r'''
@df.Dataforge()
library not_class_library;

import 'package:dataforge_annotation/dataforge_annotation.dart' as df;
''');

      await expectLater(
        generate(source.path),
        throwsA(
          isA<DataforgeGenerationException>()
              .having((error) => error.exitCode, 'exitCode', 3)
              .having(
                (error) => error.message,
                'message',
                contains('@Dataforge can only be applied to classes'),
              ),
        ),
      );
      expect(
        File(consumer.path('lib/not_class_library.data.dart')).existsSync(),
        isFalse,
      );
    });

    test('rejects analyzer parse errors before writing any output', () async {
      final valid = await consumer.write('lib/a_valid.dart', _singleV1Model);
      final invalid = await consumer.write('lib/z_invalid.dart', r'''
import 'package:dataforge_annotation/dataforge_annotation.dart' as df;

part 'z_invalid.data.dart';

@df.Dataforge()
abstract final class Invalid with _$Invalid {
  const Invalid._();

  factory Invalid({required String id}) = _Invalid

  factory Invalid.fromJson(Map<String, Object?> json) = _Invalid.fromJson;
}
''');
      final validBefore = await valid.readAsBytes();
      final invalidBefore = await invalid.readAsBytes();

      await expectLater(
        generate(consumer.path('lib')),
        throwsA(
          isA<DataforgeGenerationException>().having(
            (error) => error.exitCode,
            'exitCode',
            3,
          ),
        ),
      );

      expect(
        File(consumer.path('lib/a_valid.data.dart')).existsSync(),
        isFalse,
      );
      expect(
        File(consumer.path('lib/z_invalid.data.dart')).existsSync(),
        isFalse,
      );
      expect(await valid.readAsBytes(), validBefore);
      expect(await invalid.readAsBytes(), invalidBefore);
    });

    test(
      'rejects analyzer semantic errors before writing any output',
      () async {
        final valid = await consumer.write('lib/a_valid.dart', _singleV1Model);
        final invalid = await consumer.write('lib/z_invalid.dart', r'''
import 'package:dataforge_annotation/dataforge_annotation.dart' as df;

part 'z_invalid.data.dart';

const int invalidValue = 'not an int';

@df.Dataforge()
abstract final class Invalid with _$Invalid {
  const Invalid._();

  factory Invalid({required String id}) = _Invalid;

  factory Invalid.fromJson(Map<String, Object?> json) = _Invalid.fromJson;
}
''');
        final validBefore = await valid.readAsBytes();
        final invalidBefore = await invalid.readAsBytes();

        await expectLater(
          generate(consumer.path('lib')),
          throwsA(
            isA<DataforgeGenerationException>().having(
              (error) => error.exitCode,
              'exitCode',
              3,
            ),
          ),
        );

        expect(
          File(consumer.path('lib/a_valid.data.dart')).existsSync(),
          isFalse,
        );
        expect(
          File(consumer.path('lib/z_invalid.data.dart')).existsSync(),
          isFalse,
        );
        expect(await valid.readAsBytes(), validBefore);
        expect(await invalid.readAsBytes(), invalidBefore);
      },
    );

    test(
      'validates candidate generated bytes before committing any output',
      () async {
        final source = await consumer.write('lib/model.dart', r'''
import 'package:dataforge_annotation/dataforge_annotation.dart' as df;

part 'model.data.dart';

@df.Dataforge()
abstract final class Model with _$Model {
  const Model._();

  factory Model({required String id}) = _Model;

  factory Model.fromJson(Map<String, Object?> json) = _Model.fromJson;

  String toJson() => 'user-defined';
}
''');
        final sourceBefore = await source.readAsBytes();

        await expectLater(
          generate(source.path),
          throwsA(
            isA<DataforgeGenerationException>().having(
              (error) => error.exitCode,
              'exitCode',
              3,
            ),
          ),
        );

        expect(
          File(consumer.path('lib/model.data.dart')).existsSync(),
          isFalse,
        );
        expect(await source.readAsBytes(), sourceBefore);
      },
    );

    test('supports a custom implementation name on first generation', () async {
      final source = await consumer.write('lib/named.dart', r'''
import 'package:dataforge_annotation/dataforge_annotation.dart' as df;

part 'named.data.dart';

@df.Dataforge(name: 'StoredUser')
abstract final class User with _$StoredUser {
  const User._();

  factory User({required String id}) = _StoredUser;

  factory User.fromJson(Map<String, Object?> json) = _StoredUser.fromJson;
}
''');

      final outputs = await generate(source.path);

      expect(outputs, [consumer.path('lib/named.data.dart')]);
      final content = await File(outputs.single).readAsString();
      expect(content, contains(r'mixin _$StoredUser'));
      expect(content, contains('final class _StoredUser extends User'));
      await generate(source.path, check: true);
    });

    test(
      'does not exempt an unrelated generated-looking part diagnostic',
      () async {
        final source = await consumer.write(
          'lib/a_valid.dart',
          _singleV1Model.replaceFirst(
            "part 'a_valid.data.dart';",
            "part 'a_valid.data.dart';\npart 'bogus.data.dart';",
          ),
        );

        await expectLater(
          generate(source.path),
          throwsA(isA<DataforgeGenerationException>()),
        );

        expect(
          File(consumer.path('lib/a_valid.data.dart')).existsSync(),
          isFalse,
        );
      },
    );

    test(
      'blocks a referenced stale output and deletes it after part removal',
      () async {
        final source = await consumer.write('lib/a_valid.dart', _singleV1Model);
        final outputPath = consumer.path('lib/a_valid.data.dart');
        await generate(source.path);
        final orphanBytes = await File(outputPath).readAsBytes();

        await source.writeAsString(r'''
import 'package:dataforge_annotation/dataforge_annotation.dart' as df;

part 'a_valid.data.dart';
''');
        await expectLater(
          generate(source.path),
          throwsA(
            isA<DataforgeGenerationException>().having(
              (error) => error.exitCode,
              'exitCode',
              3,
            ),
          ),
        );
        expect(await File(outputPath).readAsBytes(), orphanBytes);

        await source.writeAsString('library a_valid;\n');
        final sourceBefore = await source.readAsBytes();
        await expectLater(
          generate(source.path, check: true),
          throwsA(isA<DataforgeCheckException>()),
        );
        expect(await File(outputPath).readAsBytes(), orphanBytes);

        expect(await generate(source.path), isEmpty);
        expect(File(outputPath).existsSync(), isFalse);
        expect(await source.readAsBytes(), sourceBefore);
        final analysis = await Process.run(Platform.resolvedExecutable, [
          'analyze',
        ], workingDirectory: consumer.root.path);
        expect(
          analysis.exitCode,
          0,
          reason: '${analysis.stdout}\n${analysis.stderr}',
        );
      },
    );

    test('never deletes an unowned file at the expected output path', () async {
      final source = await consumer.write('lib/model.dart', r'''
part 'model.data.dart';
''');
      final output = await consumer.write('lib/model.data.dart', r'''
part of 'model.dart';

const userOwnedValue = 1;
''');
      final before = await output.readAsBytes();

      expect(await generate(source.path), isEmpty);

      expect(await output.readAsBytes(), before);
    });

    test(
      'directory generation deletes source-less orphans only inside its scope',
      () async {
        final insideSource = await consumer.write(
          'lib/models/inside.dart',
          _singleV1Model
              .replaceFirst('a_valid.data.dart', 'inside.data.dart')
              .replaceAll('Valid', 'Inside'),
        );
        final outsideSource = await consumer.write(
          'lib/elsewhere/outside.dart',
          _singleV1Model
              .replaceFirst('a_valid.data.dart', 'outside.data.dart')
              .replaceAll('Valid', 'Outside'),
        );
        await generate(consumer.path('lib'));
        final insideOutput = File(consumer.path('lib/models/inside.data.dart'));
        final outsideOutput = File(
          consumer.path('lib/elsewhere/outside.data.dart'),
        );
        final insideBytes = await insideOutput.readAsBytes();
        final outsideBytes = await outsideOutput.readAsBytes();
        await insideSource.delete();
        await outsideSource.delete();

        await expectLater(
          generate(consumer.path('lib/models'), check: true),
          throwsA(isA<DataforgeCheckException>()),
        );
        expect(await insideOutput.readAsBytes(), insideBytes);
        expect(await outsideOutput.readAsBytes(), outsideBytes);

        expect(await generate(consumer.path('lib/models')), isEmpty);
        expect(insideOutput.existsSync(), isFalse);
        expect(await outsideOutput.readAsBytes(), outsideBytes);
      },
    );

    test('orphan prepare 后源码恢复时保留生成输出', () async {
      final source = await consumer.write('lib/a_valid.dart', _singleV1Model);
      final outputs = await generate(source.path);
      final output = File(outputs.single);
      final outputBefore = await output.readAsBytes();
      final sourceBefore = await source.readAsBytes();
      await source.delete();

      final preparation = await const V1CliPipeline().prepare(
        candidateFiles: const [],
        projectRoot: consumer.root.path,
        check: false,
        orphanScanRoot: consumer.path('lib'),
      );
      await source.writeAsBytes(sourceBefore);

      await expectLater(
        preparation.finish(check: false),
        throwsA(
          isA<DataforgeCheckException>().having(
            (error) => error.message,
            'message',
            contains('source file reappeared'),
          ),
        ),
      );
      expect(await output.readAsBytes(), outputBefore);
      expect(await source.readAsBytes(), sourceBefore);
    });

    test('rejects a non-v1 model before writing any output', () async {
      final v1 = await consumer.write(
        'lib/v1.dart',
        _singleV1Model.replaceFirst('a_valid.data.dart', 'v1.data.dart'),
      );
      final invalid = await consumer.write('lib/invalid.dart', r'''
import 'package:dataforge_annotation/dataforge_annotation.dart' as df;

@df.Dataforge()
class Invalid {
  final String id;
  const Invalid({required this.id});
}
''');
      final v1Before = await v1.readAsBytes();
      final invalidBefore = await invalid.readAsBytes();

      await expectLater(
        generate(consumer.path('lib')),
        throwsA(
          isA<DataforgeGenerationException>().having(
            (error) => error.message,
            'message',
            contains('must be declared as abstract final'),
          ),
        ),
      );

      expect(await v1.readAsBytes(), v1Before);
      expect(await invalid.readAsBytes(), invalidBefore);
      expect(File(consumer.path('lib/v1.data.dart')).existsSync(), isFalse);
      expect(
        File(consumer.path('lib/invalid.data.dart')).existsSync(),
        isFalse,
      );
    });

    test(
      'matches build_runner output byte for byte',
      () async {
        final source = await consumer.write(
          'lib/model.dart',
          _v1Models.replaceFirst(
            "part 'model.data.dart';",
            "part 'a_part.dart';\npart 'model.data.dart';",
          ),
        );
        await consumer.write('lib/a_part.dart', _partV1Model);

        final outputs = await generate(source.path);
        final output = File(outputs.single);
        final cliBytes = await output.readAsBytes();
        final cliContent = await output.readAsString();
        expect(
          cliContent.indexOf('final class _PartModel'),
          lessThan(cliContent.indexOf('final class _Alpha')),
        );
        await output.delete();

        final build = await Process.run(Platform.resolvedExecutable, [
          'run',
          'build_runner',
          'build',
        ], workingDirectory: consumer.root.path);
        expect(build.exitCode, 0, reason: '${build.stdout}\n${build.stderr}');
        final buildBytes = await output.readAsBytes();
        expect(
          buildBytes,
          cliBytes,
          reason: _byteDifference(cliBytes, buildBytes),
        );
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'bin supports generate/check and never post-processes v1 output',
      () async {
        final source = await consumer.write('lib/model.dart', _v1Models);
        final sourceBefore = await source.readAsBytes();
        final directOutputs = await generate(source.path);
        final output = File(directOutputs.single);
        final expectedBytes = await output.readAsBytes();
        await output.delete();

        final generated = await _runCli(repositoryRoot, consumer.root.path, [
          'generate',
          source.path,
        ]);
        expect(
          generated.exitCode,
          0,
          reason: '${generated.stdout}\n${generated.stderr}',
        );
        final generatedBytes = await output.readAsBytes();
        expect(
          generatedBytes,
          expectedBytes,
          reason: _byteDifference(expectedBytes, generatedBytes),
        );
        expect(await source.readAsBytes(), sourceBefore);

        final checked = await _runCli(repositoryRoot, consumer.root.path, [
          'check',
          source.path,
        ]);
        expect(checked.exitCode, 0, reason: checked.stderr.toString());

        await output.writeAsString(
          '${await output.readAsString()}\n// drift\n',
        );
        final drifted = await output.readAsBytes();
        final failedCheck = await _runCli(repositoryRoot, consumer.root.path, [
          'check',
          source.path,
        ]);
        expect(failedCheck.exitCode, 4);
        expect(await output.readAsBytes(), drifted);
        expect(await source.readAsBytes(), sourceBefore);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'bin requires an explicit supported command',
      () async {
        final missing = await _runCli(
          repositoryRoot,
          consumer.root.path,
          const [],
        );
        expect(missing.exitCode, 2);
        expect(missing.stderr, contains('Missing command'));

        final unknown = await _runCli(repositoryRoot, consumer.root.path, [
          'unsupported',
        ]);
        expect(unknown.exitCode, 2);
        expect(unknown.stderr, contains('Unknown command'));

        final removedCheckFlag = await _runCli(
          repositoryRoot,
          consumer.root.path,
          const ['generate', '--check'],
        );
        expect(removedCheckFlag.exitCode, 2);
        expect(removedCheckFlag.stderr, contains('Invalid arguments'));

        final help = await _runCli(repositoryRoot, consumer.root.path, const [
          '--help',
        ]);
        expect(help.exitCode, 0);
        expect(help.stdout, contains('dataforge generate'));
        expect(help.stdout, contains('dataforge check'));
        expect(help.stdout, isNot(contains('dataforge [path]')));
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'missing package config is a generation error and does not edit source',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'dataforge_no_config_',
        );
        addTearDown(() => root.delete(recursive: true));
        final source = File(p.join(root.path, 'model.dart'));
        await source.writeAsString(
          _singleV1Model.replaceFirst('a_valid.data.dart', 'model.data.dart'),
        );
        final before = await source.readAsBytes();

        await expectLater(
          generate(source.path),
          throwsA(
            isA<DataforgeGenerationException>().having(
              (error) => error.exitCode,
              'exitCode',
              3,
            ),
          ),
        );
        expect(await source.readAsBytes(), before);
        expect(
          File(p.join(root.path, 'model.data.dart')).existsSync(),
          isFalse,
        );
      },
    );

    test(
      'recognizes both v1 annotation forms without package configuration',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'dataforge_no_config_aliases_',
        );
        addTearDown(() => root.delete(recursive: true));
        const annotations = <String>['Dataforge', 'df.Dataforge'];

        for (var index = 0; index < annotations.length; index++) {
          final annotation = annotations[index];
          final source = File(p.join(root.path, 'model_$index.dart'));
          await source.writeAsString('''
@$annotation()
abstract final class Model$index {}
''');
          final before = await source.readAsBytes();
          final output = File(p.join(root.path, 'model_$index.data.dart'));

          await expectLater(
            generate(source.path),
            throwsA(
              isA<DataforgeGenerationException>()
                  .having((error) => error.exitCode, 'exitCode', 3)
                  .having(
                    (error) => error.message,
                    'message',
                    contains('DF2001'),
                  ),
            ),
            reason: annotation,
          );

          expect(await source.readAsBytes(), before, reason: annotation);
          expect(output.existsSync(), isFalse, reason: annotation);
        }
      },
    );

    test('obsolete annotation names are not v1 source markers', () async {
      final root = await Directory.systemTemp.createTemp(
        'dataforge_obsolete_markers_',
      );
      addTearDown(() => root.delete(recursive: true));

      for (final annotation in const ['dataforge', 'DataClass', 'dataClass']) {
        final source = File(p.join(root.path, '$annotation.dart'));
        await source.writeAsString('''
@$annotation()
abstract final class Model {}
''');
        final before = await source.readAsBytes();

        expect(await generate(source.path), isEmpty, reason: annotation);
        expect(await source.readAsBytes(), before, reason: annotation);
      }
    });
  });
}

Future<ProcessResult> _runCli(
  String repositoryRoot,
  String workingDirectory,
  List<String> arguments,
) {
  return Process.run(Platform.resolvedExecutable, [
    p.join(repositoryRoot, 'cli', 'bin', 'dataforge_cli.dart'),
    ...arguments,
  ], workingDirectory: workingDirectory);
}

String _sha256Bytes(List<int> bytes) => sha256.convert(bytes).toString();

String _yamlPath(String path) =>
    "'${path.replaceAll('\\', '/').replaceAll("'", "''")}'";

String _byteDifference(List<int> expected, List<int> actual) {
  final sharedLength = expected.length < actual.length
      ? expected.length
      : actual.length;
  var index = 0;
  while (index < sharedLength && expected[index] == actual[index]) {
    index++;
  }
  final start = index < 80 ? 0 : index - 80;
  final expectedEnd = index + 120 < expected.length
      ? index + 120
      : expected.length;
  final actualEnd = index + 120 < actual.length ? index + 120 : actual.length;
  return 'first byte difference at $index; '
      'expected=${utf8.decode(expected.sublist(start, expectedEnd))}; '
      'actual=${utf8.decode(actual.sublist(start, actualEnd))}';
}

const _singleV1Model = r'''
import 'package:dataforge_annotation/dataforge_annotation.dart' as df;

part 'a_valid.data.dart';

@df.Dataforge()
abstract final class Valid with _$Valid {
  const Valid._();

  factory Valid({required String id}) = _Valid;

  factory Valid.fromJson(Map<String, Object?> json) = _Valid.fromJson;
}
''';

const _nestedV1Model = r'''
import 'package:dataforge_annotation/dataforge_annotation.dart' as df;

part 'model.data.dart';

@df.Dataforge()
abstract final class NestedModel with _$NestedModel {
  const NestedModel._();

  factory NestedModel({required String id}) = _NestedModel;

  factory NestedModel.fromJson(Map<String, Object?> json) =
      _NestedModel.fromJson;
}
''';

const _v1Models = r'''
// @dart=3.9
import 'package:dataforge_annotation/dataforge_annotation.dart' as df;

part 'model.data.dart';

@df.Dataforge()
abstract final class Alpha with _$Alpha {
  const Alpha._();

  factory Alpha({required List<List<int?>> values}) = _Alpha;

  factory Alpha.fromJson(Map<String, Object?> json) = _Alpha.fromJson;
}

@df.Dataforge()
abstract final class Beta with _$Beta {
  const Beta._();

  factory Beta({required Map<String, Set<int?>> values}) = _Beta;

  factory Beta.fromJson(Map<String, Object?> json) = _Beta.fromJson;
}

@df.Dataforge()
abstract final class Gamma<T> with _$Gamma<T> {
  const Gamma._();

  factory Gamma({
    required df.DataforgeType<T> type,
    required T value,
  }) = _Gamma<T>;

  factory Gamma.fromJson(
    Map<String, Object?> json, {
    required df.DataforgeType<T> type,
  }) = _Gamma<T>.fromJson;
}
''';

const _partV1Model = r'''
// @dart=3.9
part of 'model.dart';

@df.Dataforge()
abstract final class PartModel with _$PartModel {
  const PartModel._();

  factory PartModel({required String id}) = _PartModel;

  factory PartModel.fromJson(Map<String, Object?> json) = _PartModel.fromJson;
}
''';

final class _Consumer {
  _Consumer(this.root);

  final Directory root;

  static Future<_Consumer> create(String repositoryRoot) async {
    final root = await Directory.systemTemp.createTemp('dataforge_v1_cli_');
    final consumer = _Consumer(root);
    await consumer.write('pubspec.yaml', '''
name: dataforge_v1_cli_consumer
environment:
  sdk: '>=3.9.0 <4.0.0'
dependencies:
  dataforge_annotation:
    path: ${_yamlPath(p.join(repositoryRoot, 'annotation'))}
dev_dependencies:
  build_runner: ^2.10.5
  dataforge:
    path: ${_yamlPath(p.join(repositoryRoot, 'generator'))}
dependency_overrides:
  dataforge_annotation:
    path: ${_yamlPath(p.join(repositoryRoot, 'annotation'))}
  dataforge_base:
    path: ${_yamlPath(p.join(repositoryRoot, 'dataforge_base'))}
''');
    final pubGet = await Process.run(Platform.resolvedExecutable, [
      'pub',
      'get',
      '--offline',
    ], workingDirectory: root.path);
    if (pubGet.exitCode != 0) {
      await root.delete(recursive: true);
      fail('dart pub get failed: ${pubGet.stdout}\n${pubGet.stderr}');
    }
    return consumer;
  }

  String path(String relativePath) =>
      p.normalize(p.join(root.path, relativePath));

  Future<File> write(String relativePath, String content) async {
    final file = File(path(relativePath));
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
    return file;
  }

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}
