/// Custom exceptions for Dataforge code generation.
///
/// These exceptions provide detailed context for common errors during
/// code generation and parsing.

/// Base exception class for all Dataforge errors.
class DataforgeException implements Exception {
  /// The error message.
  final String message;

  /// Optional context about where the error occurred.
  final String? context;

  /// Creates a new [DataforgeException].
  const DataforgeException(this.message, {this.context});

  @override
  String toString() {
    if (context != null) {
      return 'DataforgeException: $message\nContext: $context';
    }
    return 'DataforgeException: $message';
  }
}

/// Exception thrown when an unsupported type is encountered during code generation.
///
/// This typically occurs when:
/// - A List contains an unsupported nested type
/// - A Map has a non-String key type
/// - A Map value has an unsupported nested type
class UnsupportedTypeException extends DataforgeException {
  /// The unsupported type that was encountered.
  final String unsupportedType;

  /// The field name where the unsupported type was found.
  final String fieldName;

  /// List of supported types for this context.
  final List<String> supportedTypes;

  /// Creates a new [UnsupportedTypeException].
  UnsupportedTypeException({
    required this.unsupportedType,
    required this.fieldName,
    required this.supportedTypes,
    String? context,
  }) : super(
          'Unsupported type "$unsupportedType" for field "$fieldName".',
          context: context,
        );

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln(
        'UnsupportedTypeException: Unsupported type "$unsupportedType" for field "$fieldName".');
    if (context != null) {
      buffer.writeln('Context: $context');
    }
    buffer.writeln('Supported types: ${supportedTypes.join(", ")}');
    return buffer.toString();
  }
}

/// Exception thrown when parsing fails due to invalid input or configuration.
///
/// This exception provides details about what was being parsed and why it failed.
class ParseException extends DataforgeException {
  /// The element or input that failed to parse.
  final String? element;

  /// Creates a new [ParseException].
  const ParseException(
    super.message, {
    this.element,
    super.context,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('ParseException: $message');
    if (element != null) {
      buffer.write('\nElement: $element');
    }
    if (context != null) {
      buffer.write('\nContext: $context');
    }
    return buffer.toString();
  }
}
