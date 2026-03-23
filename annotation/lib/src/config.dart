/// Global configuration for Dataforge.
///
/// Set [copyWithErrorCallback] to handle type conversion errors in copyWith.
/// By default, errors are printed to stdout (using `print()` to avoid a
/// `dart:io` dependency in the annotation package). Override this callback
/// to route errors to stderr or a logging framework.
class DataforgeConfig {
  DataforgeConfig._();

  static DataforgeCopyWithErrorCallback copyWithErrorCallback =
      _defaultCopyWithErrorCallback;

  static void _defaultCopyWithErrorCallback(
    String fieldName,
    String expectedType,
    Object? actualValue,
    Object error,
    StackTrace stackTrace,
  ) {
    // ignore: avoid_print
    print(
        'Dataforge copyWith error: field "$fieldName" expected $expectedType, '
        'got ${actualValue.runtimeType} ($error)');
  }

  /// Internal method to report an error.
  static void reportCopyWithError(
    String fieldName,
    String expectedType,
    Object? actualValue,
    Object error,
    StackTrace stackTrace,
  ) {
    copyWithErrorCallback.call(
        fieldName, expectedType, actualValue, error, stackTrace);
  }
}

/// Callback type for handling errors during copyWith type conversion.
///
/// [fieldName] is the name of the field being converted.
/// [expectedType] is the expected type of the field.
/// [actualValue] is the actual value that was passed.
/// [error] is the error that occurred during conversion.
/// [stackTrace] is the stack trace of the error.
typedef DataforgeCopyWithErrorCallback = void Function(
  String fieldName,
  String expectedType,
  Object? actualValue,
  Object error,
  StackTrace stackTrace,
);
