/// Stable base class for expected CLI failures.
sealed class DataforgeCliException implements Exception {
  const DataforgeCliException(
    this.message, {
    required this.exitCode,
    this.cause,
  });

  final String message;
  final int exitCode;
  final Object? cause;

  @override
  String toString() => message;
}

/// Invalid arguments, paths, or configuration.
final class DataforgeInputException extends DataforgeCliException {
  const DataforgeInputException(String message, {Object? cause})
    : super(message, exitCode: 2, cause: cause);
}

/// Dart resolution, model validation, or code generation failure.
final class DataforgeGenerationException extends DataforgeCliException {
  const DataforgeGenerationException(String message, {Object? cause})
    : super(message, exitCode: 3, cause: cause);
}

/// Missing or drifted output detected by the `check` command.
final class DataforgeCheckException extends DataforgeCliException {
  const DataforgeCheckException(String message, {Object? cause})
    : super(message, exitCode: 4, cause: cause);
}

/// Output, formatting, or transaction I/O failure.
final class DataforgeIoException extends DataforgeCliException {
  const DataforgeIoException(String message, {Object? cause})
    : super(message, exitCode: 5, cause: cause);
}
