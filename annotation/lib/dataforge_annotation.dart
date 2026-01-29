// @author luwenjie on 20/04/2025 15:41:25

import 'package:dataforge_annotation/src/config.dart';

export 'src/annotation.dart';
export 'src/converter.dart';
export 'src/config.dart' show DataforgeCopyWithErrorCallback;
export 'src/safe_type_converter.dart';

export 'package:collection/collection.dart';

/// to provide initialization method.
class DataforgeInit {
  /// Initialize Dataforge with global configuration.
  ///
  /// [onCopyWithError] is called whenever a type conversion error occurs during copyWith.
  /// This helps developers identify and debug type mismatch issues.
  ///
  /// Example:
  /// ```dart
  /// void main() {
  ///   DataforgeInit.init(
  ///     onCopyWithError: (fieldName, expectedType, actualValue, error, stackTrace) {
  ///       print('Error in field "$fieldName": expected $expectedType, got ${actualValue.runtimeType}');
  ///       print('Error: $error');
  ///     },
  ///   );
  /// }
  /// ```
  static void init({
    DataforgeCopyWithErrorCallback? onCopyWithError,
  }) {
    DataforgeConfig.copyWithErrorCallback = onCopyWithError;
  }
}
