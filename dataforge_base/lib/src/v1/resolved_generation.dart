import 'package:analyzer/dart/element/element.dart';

import 'analyzer_schema_builder.dart';
import 'diagnostics.dart';
import 'writer.dart';

/// Public v1 result produced by the resolved Analyzer frontend and renderer.
///
/// Its constructor is library-private so callers cannot forge a validated
/// generation result.
final class V1ResolvedGeneration {
  V1ResolvedGeneration._({
    required this.modelName,
    required this.source,
    required List<GenerationDiagnostic> diagnostics,
  }) : diagnostics = List<GenerationDiagnostic>.unmodifiable(
         [...diagnostics]..sort(),
       );

  /// Resolved model name used only for deterministic sorting and diagnostics.
  final String modelName;

  /// Generated source, present only when schema validation and rendering pass.
  final String? source;

  final List<GenerationDiagnostic> diagnostics;

  bool get hasErrors => diagnostics.any(
    (diagnostic) => diagnostic.severity == GenerationDiagnosticSeverity.error,
  );
}

/// The only public entry point for generating one Dataforge v1 model.
///
/// Callers provide a resolved [ClassElement]. Schema construction, cross-model
/// validation, symbol resolution, and rendering remain inside this boundary;
/// the public API accepts neither caller-built schemas nor a raw writer.
final class V1ResolvedModelGenerator {
  const V1ResolvedModelGenerator();

  static const String dataforgeAnnotationLibraryUri =
      'package:dataforge_annotation/src/annotation.dart';
  static const String dataforgeAnnotationName = 'Dataforge';

  V1ResolvedGeneration generate(ClassElement classElement) {
    final built = const V1ModelSchemaBuilder().build(classElement);
    final diagnostics = <GenerationDiagnostic>[...built.diagnostics];
    String? source;

    if (!built.hasErrors && built.schema != null) {
      try {
        source = ModelSchemaWriter(
          symbolNameResolver: built.resolveSymbol,
          runtimePrefix: built.annotationPrefix ?? '',
        ).write(built.schema!);
      } on ModelSchemaWriterException catch (error) {
        diagnostics.add(_withResolvedLocation(error.diagnostic, classElement));
      }
    }

    return V1ResolvedGeneration._(
      modelName: classElement.name ?? '<unnamed>',
      source: source,
      diagnostics: diagnostics,
    );
  }

  static GenerationDiagnostic _withResolvedLocation(
    GenerationDiagnostic diagnostic,
    ClassElement classElement,
  ) {
    if (diagnostic.location != null) return diagnostic;
    final element = _elementForWriterTarget(classElement, diagnostic.target);
    return GenerationDiagnostic(
      formatVersion: diagnostic.formatVersion,
      code: diagnostic.code,
      severity: diagnostic.severity,
      message: diagnostic.message,
      schemaId: diagnostic.schemaId,
      target: diagnostic.target,
      location: _location(element),
      details: diagnostic.details,
    );
  }

  static Element _elementForWriterTarget(
    ClassElement classElement,
    String? target,
  ) {
    if (target != null) {
      ConstructorElement? valueFactory;
      for (final constructor in classElement.constructors) {
        if (constructor.name == 'new' && constructor.isFactory) {
          valueFactory = constructor;
          break;
        }
      }
      for (final parameter
          in valueFactory?.formalParameters ??
              const <FormalParameterElement>[]) {
        if (parameter.name == target) return parameter;
      }
      for (final parameter in classElement.typeParameters) {
        if (parameter.name == target) return parameter;
      }
    }
    return classElement;
  }

  static GenerationSourceLocation _location(Element element) {
    final fragment = element.firstFragment;
    final libraryFragment =
        fragment.libraryFragment ?? element.library!.firstFragment;
    final offset = fragment.offset;
    final characterLocation = libraryFragment.lineInfo.getLocation(offset);
    return GenerationSourceLocation(
      uri: libraryFragment.source.uri.toString(),
      offset: offset,
      length: element.name?.length ?? 0,
      line: characterLocation.lineNumber,
      column: characterLocation.columnNumber,
    );
  }
}
