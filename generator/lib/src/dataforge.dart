import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:dataforge_base/dataforge_base.dart'
    show GenerationDiagnostic, V1ResolvedGeneration, V1ResolvedModelGenerator;
import 'package:source_gen/source_gen.dart';

/// Generates deeply immutable Dataforge models from resolved analyzer elements.
///
/// Every annotated class must satisfy the abstract-final redirecting-factory
/// contract.
final class DataforgeGenerator extends GeneratorForAnnotation<Dataforge> {
  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    final annotatedElements =
        library
            .annotatedWith(typeChecker, throwOnUnresolved: throwOnUnresolved)
            .toList()
          ..sort(_compareAnnotatedElements);
    final buildResults = <ClassElement, V1ResolvedGeneration>{};

    for (final annotated in annotatedElements) {
      final element = annotated.element;
      if (element is! ClassElement) continue;
      final result = const V1ResolvedModelGenerator().generate(element);
      buildResults[element] = result;
    }

    final values = <String>{};
    for (final annotated in annotatedElements) {
      final element = annotated.element;
      final generated = element is ClassElement
          ? _generateClass(element, buildResults[element]!)
          : await generateForAnnotatedElement(
              element,
              annotated.annotation,
              buildStep,
            );
      final normalized = generated.trim();
      if (normalized.isNotEmpty) values.add(normalized);
    }
    return values.join('\n\n');
  }

  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    // Only process class elements
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@Dataforge can only be applied to classes.',
        element: element,
      );
    }

    final classElement = element;
    return _generateClass(
      classElement,
      const V1ResolvedModelGenerator().generate(classElement),
    );
  }

  String _generateClass(
    ClassElement classElement,
    V1ResolvedGeneration v1Result,
  ) {
    if (v1Result.hasErrors || v1Result.source == null) {
      throw InvalidGenerationSourceError(
        _diagnosticsMessage(v1Result.diagnostics),
        element: classElement,
      );
    }
    return v1Result.source!;
  }
}

int _compareAnnotatedElements(AnnotatedElement left, AnnotatedElement right) {
  final leftFragment = left.element.firstFragment;
  final rightFragment = right.element.firstFragment;
  final leftUri =
      leftFragment.libraryFragment?.source.uri.toString() ??
      left.element.library?.uri.toString() ??
      '';
  final rightUri =
      rightFragment.libraryFragment?.source.uri.toString() ??
      right.element.library?.uri.toString() ??
      '';
  final uriOrder = leftUri.compareTo(rightUri);
  if (uriOrder != 0) return uriOrder;
  final offsetOrder = leftFragment.offset.compareTo(rightFragment.offset);
  if (offsetOrder != 0) return offsetOrder;
  return left.element.displayName.compareTo(right.element.displayName);
}

String _diagnosticsMessage(List<GenerationDiagnostic> diagnostics) {
  if (diagnostics.isEmpty) {
    return 'Dataforge v1 generation failed without a diagnostic.';
  }
  return diagnostics.map((diagnostic) => diagnostic.toString()).join('\n');
}
