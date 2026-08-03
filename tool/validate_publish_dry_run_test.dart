import 'src/publish_dry_run_output.dart';

void main() {
  const dependencies = {'dataforge_annotation', 'dataforge_base'};
  const annotationWarning =
      '* Your dependency on "dataforge_annotation" should allow more than one version.';
  const baseWarning =
      '* Your dependency on "dataforge_base" should allow more than one version.';
  const overrideHint =
      '* Non-dev dependencies are overridden in pubspec_overrides.yaml.';

  _expectAccepted(
    validatePublishDryRunOutput(
      processExitCode: 0,
      output: 'Package has 0 warnings.',
      allowedDependencies: const {},
    ),
  );
  _expectAccepted(
    validatePublishDryRunOutput(
      processExitCode: 65,
      output: '$annotationWarning\n$baseWarning\n$overrideHint\n$overrideHint\n'
          'Package has 2 warnings and 2 hints.',
      allowedDependencies: dependencies,
    ),
  );
  _expectRejected(
    validatePublishDryRunOutput(
      processExitCode: 0,
      output: '$annotationWarning\nPackage has 0 warnings.',
      allowedDependencies: dependencies,
    ),
  );
  _expectRejected(
    validatePublishDryRunOutput(
      processExitCode: 65,
      output: '$annotationWarning\n$annotationWarning\n$baseWarning\n'
          'Package has 3 warnings.',
      allowedDependencies: dependencies,
    ),
  );
  _expectRejected(
    validatePublishDryRunOutput(
      processExitCode: 0,
      output: 'Package validation completed.',
      allowedDependencies: const {},
    ),
  );
  _expectRejected(
    validatePublishDryRunOutput(
      processExitCode: 65,
      output: 'Package has 0 warnings.',
      allowedDependencies: const {},
    ),
  );
  _expectRejected(
    validatePublishDryRunOutput(
      processExitCode: 65,
      output: '$annotationWarning\n$baseWarning\nUnexpected warning\n'
          'Package has 3 warnings.',
      allowedDependencies: dependencies,
    ),
  );
  _expectRejected(
    validatePublishDryRunOutput(
      processExitCode: 65,
      output: '$annotationWarning\n$baseWarning\nUnexpected hint\n'
          'Package has 2 warnings and 1 hint.',
      allowedDependencies: dependencies,
    ),
  );

  print('publish dry-run output validation tests passed');
}

void _expectAccepted(PublishDryRunDecision decision) {
  if (!decision.accepted || decision.exitCode != 0) {
    throw StateError('Expected acceptance, got ${decision.message}');
  }
}

void _expectRejected(PublishDryRunDecision decision) {
  if (decision.accepted || decision.exitCode == 0) {
    throw StateError('Expected a non-zero rejection, got ${decision.message}');
  }
}
