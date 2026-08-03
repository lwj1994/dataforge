import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test(
    'v1 clean consumer 可从零生成、分析并执行完整值语义',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'dataforge_v1_consumer_',
      );
      addTearDown(() => temporary.delete(recursive: true));

      final repositoryRoot = Directory.current.parent.absolute.path;
      await _write(temporary, 'pubspec.yaml', '''
name: dataforge_v1_consumer
publish_to: none
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
      await _write(temporary, 'lib/models.dart', _modelSource);
      await _write(temporary, 'bin/main.dart', _mainSource);

      await _expectProcess(temporary, ['pub', 'get', '--offline']);
      await _expectProcess(temporary, [
        'run',
        'build_runner',
        'build',
      ], timeout: const Duration(minutes: 2));

      final generated = File(p.join(temporary.path, 'lib', 'models.data.dart'));
      expect(await generated.exists(), isTrue);
      final generatedSource = await generated.readAsString();
      expect(generatedSource, contains('final class _Profile'));
      expect(generatedSource, contains('mixin _\$Profile'));
      expect(generatedSource, contains('DataforgeTypes.list('));
      expect(generatedSource, contains('DataforgeTypes.duration'));

      await _expectProcess(temporary, ['analyze', '--fatal-infos']);
      final run = await _expectProcess(temporary, ['run', 'bin/main.dart']);
      expect(run.stdout.toString(), contains('v1 clean consumer ok'));
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

Future<File> _write(Directory root, String relativePath, String content) async {
  final file = File(p.join(root.path, relativePath));
  await file.parent.create(recursive: true);
  await file.writeAsString(content);
  return file;
}

Future<ProcessResult> _expectProcess(
  Directory workingDirectory,
  List<String> arguments, {
  Duration timeout = const Duration(minutes: 1),
}) async {
  final process = await Process.run(
    Platform.resolvedExecutable,
    arguments,
    workingDirectory: workingDirectory.path,
  ).timeout(timeout);
  expect(
    process.exitCode,
    0,
    reason:
        '''
command: dart ${arguments.join(' ')}
stdout:
${process.stdout}
stderr:
${process.stderr}
''',
  );
  return process;
}

String _yamlPath(String path) => "'${path.replaceAll("'", "''")}'";

const _modelSource = r'''
import 'package:dataforge_annotation/dataforge_annotation.dart' as df;

part 'models.data.dart';

enum State { ready, done }

@df.Dataforge()
abstract final class Profile with _$Profile {
  const Profile._();

  factory Profile({
    required String name,
    @df.DataforgeDefault(<List<int>>[]) List<List<int>> scores,
    @df.DataforgeDefault(<String, Set<int?>>{})
    Map<String, Set<int?>> groups,
    required State state,
    required Duration elapsed,
  }) = _Profile;

  factory Profile.fromJson(Map<String, Object?> json) = _Profile.fromJson;
}

@df.Dataforge()
abstract final class Box<T> with _$Box<T> {
  const Box._();

  factory Box({
    required df.DataforgeType<T> type,
    required T value,
  }) = _Box<T>;

  factory Box.fromJson(
    Map<String, Object?> json, {
    required df.DataforgeType<T> type,
  }) = _Box<T>.fromJson;
}
''';

const _mainSource = r'''
import 'package:dataforge_annotation/dataforge_annotation.dart' as df;
import 'package:dataforge_v1_consumer/models.dart';

Never fail(String message) => throw StateError(message);

void main() {
  final scores = <List<int>>[
    <int>[1],
  ];
  final groups = <String, Set<int?>>{
    'a': <int?>{1, null},
  };
  final profile = Profile(
    name: 'milu',
    scores: scores,
    groups: groups,
    state: State.ready,
    elapsed: const Duration(microseconds: 5),
  );

  scores.first.add(2);
  scores.add(<int>[3]);
  groups['a']!.add(9);
  groups['b'] = <int?>{2};
  if (profile.scores.length != 1 || profile.scores.single.length != 1) {
    fail('nested List was not detached');
  }
  if (profile.groups.length != 1 || profile.groups['a']!.contains(9)) {
    fail('nested Map/Set was not detached');
  }
  try {
    profile.groups['a']!.add(4);
    fail('nested Set is mutable');
  } on UnsupportedError {
    // expected
  }

  if (!identical(profile.copyWith(), profile)) {
    fail('no-op copyWith did not return this');
  }
  if (!identical(
    profile.copyWith(scores: <List<int>>[<int>[1]]),
    profile,
  )) {
    fail('value-equal copyWith did not return this');
  }
  final renamed = profile.copyWith(name: 'new');
  if (!identical(renamed.scores, profile.scores) ||
      !identical(renamed.groups, profile.groups)) {
    fail('unchanged frozen subtrees were not shared');
  }

  final equal = Profile(
    name: 'milu',
    scores: <List<int>>[<int>[1]],
    groups: <String, Set<int?>>{
      'a': <int?>{null, 1},
    },
    state: State.ready,
    elapsed: const Duration(microseconds: 5),
  );
  if (profile != equal || profile.hashCode != equal.hashCode) {
    fail('deep equality/hash mismatch');
  }

  final defaults = Profile.fromJson(<String, Object?>{
    'name': 'defaulted',
    'state': 'done',
    'elapsed': 7,
  });
  if (defaults.scores.isNotEmpty || defaults.groups.isNotEmpty) {
    fail('DataforgeDefault was not applied');
  }
  try {
    Profile.fromJson(<String, Object?>{
      'name': 'bad',
      'state': 'ready',
      'elapsed': 1,
      'unknown': true,
    });
    fail('unknown JSON key was accepted');
  } on df.DataforgeDecodeException catch (error) {
    if (error.path != r'$.unknown') fail('wrong unknown-key path');
  }

  final json = profile.toJson();
  try {
    json['name'] = 'mutated';
    fail('toJson result is mutable');
  } on UnsupportedError {
    // expected
  }

  final firstType = df.DataforgeTypes.intType;
  final box = Box<int>(type: firstType, value: 1);
  final boxType = $BoxType<int>(firstType);
  final boxTypeIdentity = boxType as df.DataforgeTypeIdentity;
  try {
    boxTypeIdentity.dataforgeTypeArguments.add(firstType);
    fail('generated witness type arguments are mutable');
  } on UnsupportedError {
    // expected
  }
  if (!identical(box.copyWith(), box)) fail('generic no-op copy failed');
  final decoded = Box<int>.fromJson(
    <String, Object?>{'value': 2},
    type: firstType,
  );
  if (decoded.value != 2) fail('generic strict decode failed');

  print('v1 clean consumer ok');
}
''';
