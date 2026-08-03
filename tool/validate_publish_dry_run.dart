import 'dart:io';

import 'src/publish_dry_run_output.dart';

/// Runs pub publish dry-run with a narrow preview dependency allowlist.
Future<void> main(List<String> arguments) async {
  final allowedDependencies = arguments.toSet();
  if (allowedDependencies.length != arguments.length ||
      allowedDependencies.any(
        (name) => !RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name),
      )) {
    stderr.writeln('用法错误：参数必须是互不重复的 pub package 名。');
    exitCode = 64;
    return;
  }

  if (allowedDependencies.isNotEmpty) {
    const expectedDependencies = {
      'dataforge_annotation',
      'dataforge_base',
    };
    if (!_sameSet(allowedDependencies, expectedDependencies)) {
      stderr.writeln(
        '发布校验失败：预览 warning allowlist 只能且必须包含 '
        'dataforge_annotation 与 dataforge_base。',
      );
      exitCode = 64;
      return;
    }

    final pubspec = File('pubspec.yaml');
    if (!_isRegularFile(pubspec)) {
      stderr.writeln('发布校验失败：当前目录没有 pubspec.yaml。');
      exitCode = 64;
      return;
    }
    final source = pubspec.readAsStringSync();
    final packageName = _topLevelScalar(source, 'name');
    final version = _topLevelScalar(source, 'version');
    if (packageName != 'dataforge' && packageName != 'dataforge_cli') {
      stderr.writeln(
        '发布校验失败：只有 dataforge 与 dataforge_cli 可使用预览 warning allowlist。',
      );
      exitCode = 64;
      return;
    }
    if (version == null || !_isPrerelease(version)) {
      stderr.writeln('发布校验失败：稳定/GA 版本不得使用 warning allowlist。');
      exitCode = 64;
      return;
    }
    for (final dependency in expectedDependencies) {
      final constraint = _dependencyConstraint(source, dependency);
      if (constraint != version) {
        stderr.writeln(
          '发布校验失败：$dependency 必须精确锁定当前预览版本 $version，'
          '实际为 ${constraint ?? '缺失'}。',
        );
        exitCode = 64;
        return;
      }
      final siblingDirectory = switch (dependency) {
        'dataforge_annotation' => 'annotation',
        'dataforge_base' => 'dataforge_base',
        _ => throw StateError('unexpected internal dependency $dependency'),
      };
      final siblingPubspec = File('../$siblingDirectory/pubspec.yaml');
      final siblingVersion = _isRegularFile(siblingPubspec)
          ? _topLevelScalar(siblingPubspec.readAsStringSync(), 'version')
          : null;
      if (siblingVersion != version) {
        stderr.writeln(
          '发布校验失败：$dependency sibling 版本 '
          '${siblingVersion ?? '无法读取'} 与 $packageName $version 不一致。',
        );
        exitCode = 64;
        return;
      }
    }
  }

  final result = await Process.run(Platform.resolvedExecutable, const [
    'pub',
    'publish',
    '--dry-run',
  ]);
  stdout.write(result.stdout);
  stderr.write(result.stderr);

  final decision = validatePublishDryRunOutput(
    processExitCode: result.exitCode,
    output: '${result.stdout}\n${result.stderr}',
    allowedDependencies: allowedDependencies,
  );
  if (decision.message.isNotEmpty) {
    (decision.accepted ? stdout : stderr).writeln(decision.message);
  }
  exitCode = decision.exitCode;
}

bool _sameSet(Set<String> left, Set<String> right) =>
    left.length == right.length && left.containsAll(right);

bool _isRegularFile(File file) =>
    FileSystemEntity.typeSync(file.path, followLinks: false) ==
    FileSystemEntityType.file;

String? _topLevelScalar(String yaml, String key) {
  final match = RegExp(
    '^${RegExp.escape(key)}:[ \\t]*([^#\\r\\n]+)',
    multiLine: true,
  ).firstMatch(yaml);
  return match == null ? null : _unquote(match.group(1)!.trim());
}

String? _dependencyConstraint(String yaml, String packageName) {
  var inDependencies = false;
  for (final line in yaml.split(RegExp(r'\r?\n'))) {
    final trimmed = line.trim();
    if (!inDependencies) {
      if (trimmed == 'dependencies:' && !line.startsWith(RegExp(r'\s'))) {
        inDependencies = true;
      }
      continue;
    }
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    if (!line.startsWith(RegExp(r'\s'))) return null;
    final match = RegExp(
      '^  ${RegExp.escape(packageName)}:[ \\t]*([^#\\r\\n]+)',
    ).firstMatch(line);
    if (match != null) return _unquote(match.group(1)!.trim());
  }
  return null;
}

String _unquote(String value) {
  if (value.length >= 2 &&
      ((value.startsWith("'") && value.endsWith("'")) ||
          (value.startsWith('"') && value.endsWith('"')))) {
    return value.substring(1, value.length - 1);
  }
  return value;
}

bool _isPrerelease(String version) => RegExp(
      r'^\d+\.\d+\.\d+-[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*(?:\+[0-9A-Za-z.-]+)?$',
    ).hasMatch(version);
