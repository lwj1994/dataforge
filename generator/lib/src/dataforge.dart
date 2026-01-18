// @author luwenjie on 2026/01/17 14:37:53

import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:source_gen/source_gen.dart';

import 'parser.dart';
import 'writer.dart';

/// Generator for @Dataforge annotated classes
///
/// This generator scans for classes annotated with @Dataforge and generates
/// data class code including:
/// - copyWith methods (traditional or chained)
/// - fromJson/toJson methods
/// - equality operators (==, hashCode, toString)
class DataforgeGenerator extends GeneratorForAnnotation<Dataforge> {
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

    // Parse the class using our parser
    final parser = GeneratorParser(classElement, annotation);
    final parseResult = parser.parse();

    if (parseResult == null) {
      return '';
    }

    // Generate code using our writer
    final writer = GeneratorWriter(parseResult);
    final generatedCode = writer.generate();

    return generatedCode;
  }
}
