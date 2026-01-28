/// Global configuration for Dataforge.
///
/// Use [Dataforge.init] to configure error handling and other global settings.
class DataforgeConfig {
  static DataforgeCopyWithErrorCallback? copyWithErrorCallback;

  /// Internal method to report an error.
  static void reportCopyWithError(
    String fieldName,
    String expectedType,
    Object? actualValue,
    Object error,
    StackTrace stackTrace,
  ) {
    copyWithErrorCallback?.call(
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
