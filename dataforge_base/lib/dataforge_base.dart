/// Resolved frontend and diagnostics for Dataforge v1 code generation.
///
/// Raw schemas and renderers remain internal so callers cannot bypass resolved
/// cross-model validation.
library dataforge_base;

export 'src/v1/diagnostics.dart';
export 'src/v1/resolved_generation.dart';
export 'src/v1/schema.dart' show SchemaId;
