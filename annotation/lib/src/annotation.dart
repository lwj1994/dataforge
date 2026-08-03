/// Configures generation for a Dataforge v1 value model.
final class Dataforge {
  /// Overrides the generated private implementation base name.
  final String name;

  /// Whether the model exposes strict JSON decoding.
  final bool includeFromJson;

  /// Whether the model exposes strict JSON encoding.
  final bool includeToJson;

  const Dataforge({
    this.name = '',
    this.includeFromJson = true,
    this.includeToJson = true,
  });
}

/// Declares a generated implementation default for a v1 factory parameter.
///
/// Dart does not allow a default directly on a redirecting factory parameter,
/// so Dataforge receives the value through resolved constant metadata.
///
/// ```dart
/// factory User({
///   @DataforgeDefault(<String>[]) List<String> tags,
/// }) = _User;
/// ```
///
/// [value] must be a compile-time constant that can be rendered losslessly.
final class DataforgeDefault {
  final Object? value;

  const DataforgeDefault(this.value);
}

/// Configures strict JSON names and inclusion for one factory parameter.
///
/// This class is metadata-only. In an annotation context Dart requires the
/// complete [alternateNames] object graph to be constant and immutable.
final class JsonKey {
  final String name;
  final List<String> alternateNames;
  final bool ignore;
  final bool? includeIfNull;

  const JsonKey({
    this.name = '',
    this.alternateNames = const [],
    this.ignore = false,
    this.includeIfNull,
  });
}
