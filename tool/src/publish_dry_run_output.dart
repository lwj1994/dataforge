final class PublishDryRunDecision {
  const PublishDryRunDecision({
    required this.accepted,
    required this.exitCode,
    required this.message,
  });

  final bool accepted;
  final int exitCode;
  final String message;
}

PublishDryRunDecision validatePublishDryRunOutput({
  required int processExitCode,
  required String output,
  required Set<String> allowedDependencies,
}) {
  final summary = RegExp(
    r'Package has (\d+) warnings?(?: and (\d+) hints?)?\.',
  ).firstMatch(output);
  final warningCount = summary == null ? null : int.parse(summary.group(1)!);
  final hintCount =
      summary?.group(2) == null ? 0 : int.parse(summary!.group(2)!);
  var allowedWarningCount = 0;

  for (final dependency in allowedDependencies) {
    final marker =
        '* Your dependency on "$dependency" should allow more than one version.';
    final occurrences = marker.allMatches(output).length;
    if (occurrences != 1) {
      return PublishDryRunDecision(
        accepted: false,
        exitCode: _failureExitCode(processExitCode),
        message: '发布校验失败：预期恰好一条 $dependency 精确锁版本 warning，实际为 '
            '$occurrences 条。',
      );
    }
    allowedWarningCount += occurrences;
  }

  const overrideHint =
      '* Non-dev dependencies are overridden in pubspec_overrides.yaml.';
  final overrideHintCount = overrideHint.allMatches(output).length;
  final hintsAreAllowed = hintCount == 0 ||
      (allowedDependencies.isNotEmpty &&
          hintCount == allowedDependencies.length &&
          overrideHintCount == hintCount);

  if (summary != null &&
      processExitCode == 0 &&
      warningCount == 0 &&
      hintsAreAllowed) {
    return const PublishDryRunDecision(
      accepted: true,
      exitCode: 0,
      message: '',
    );
  }

  if (summary != null &&
      allowedDependencies.isNotEmpty &&
      processExitCode == 65 &&
      warningCount == allowedWarningCount &&
      hintsAreAllowed) {
    return PublishDryRunDecision(
      accepted: true,
      exitCode: 0,
      message: '已接受 $allowedWarningCount 条预览期内部依赖精确锁版本 warning；'
          '未发现其他 warning。',
    );
  }

  return PublishDryRunDecision(
    accepted: false,
    exitCode: _failureExitCode(processExitCode),
    message: '发布校验失败：warning 总数为 ${warningCount ?? '无法解析'}，'
        'allowlist 仅匹配 $allowedWarningCount 条；hint 总数为 $hintCount，'
        '其中已识别 override hint $overrideHintCount 条。',
  );
}

int _failureExitCode(int processExitCode) =>
    processExitCode == 0 ? 65 : processExitCode;
