/// Shared type parsing utilities for Dataforge code generation.
///
/// These utilities handle splitting and extracting generic type arguments
/// from Dart type strings like `Map<String, List<User>>`.
class TypeUtils {
  TypeUtils._();

  /// Common primitive and built-in types that do not need special
  /// serialization handling (no fromJson/toJson, not enums, not Dataforge).
  static const Set<String> primitiveTypes = {
    'String',
    'int',
    'double',
    'bool',
    'num',
    'dynamic',
    'void',
    'Object',
    'DateTime',
    'Duration',
    'Uri',
    'BigInt',
  };

  /// Splits a type arguments string at top-level commas, respecting nested
  /// generics, parentheses, braces, and brackets.
  ///
  /// For example, `'String, List<int>'` returns `['String', 'List<int>']`.
  static List<String> splitTopLevelTypeArguments(String typeArguments) {
    final parts = <String>[];
    var current = StringBuffer();
    int genericDepth = 0;
    int parenDepth = 0;
    int braceDepth = 0;
    int bracketDepth = 0;

    for (final char in typeArguments.split('')) {
      switch (char) {
        case '<':
          genericDepth++;
          current.write(char);
          break;
        case '>':
          genericDepth--;
          current.write(char);
          break;
        case '(':
          parenDepth++;
          current.write(char);
          break;
        case ')':
          parenDepth--;
          current.write(char);
          break;
        case '{':
          braceDepth++;
          current.write(char);
          break;
        case '}':
          braceDepth--;
          current.write(char);
          break;
        case '[':
          bracketDepth++;
          current.write(char);
          break;
        case ']':
          bracketDepth--;
          current.write(char);
          break;
        case ',':
          if (genericDepth == 0 &&
              parenDepth == 0 &&
              braceDepth == 0 &&
              bracketDepth == 0) {
            parts.add(current.toString().trim());
            current = StringBuffer();
          } else {
            current.write(char);
          }
          break;
        default:
          current.write(char);
      }
    }

    if (current.length > 0) {
      parts.add(current.toString().trim());
    }

    return parts;
  }

  /// Extracts the last type argument from a generic type string.
  ///
  /// For example:
  /// - `'Map<String, User>'` returns `'User'`
  /// - `'List<int>'` returns `'int'`
  /// - `'String'` returns `'String'` (no generics)
  static String extractLastTypeArgument(String type) {
    final genericStart = type.indexOf('<');
    final genericEnd = type.lastIndexOf('>');
    if (genericStart == -1 || genericEnd == -1 || genericEnd <= genericStart) {
      return type;
    }

    final typeArguments = type.substring(genericStart + 1, genericEnd);
    final parts = splitTopLevelTypeArguments(typeArguments);
    return parts.isEmpty ? typeArguments : parts.last;
  }
}
