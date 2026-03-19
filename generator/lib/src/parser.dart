import 'package:analyzer/dart/element/element.dart';
import 'package:dataforge_base/src/model.dart';
import 'package:dataforge_base/src/parser.dart';
import 'package:source_gen/source_gen.dart';

/// Parser for extracting class information from Dart analyzer elements
class GeneratorParser extends BaseParser {
  GeneratorParser(ClassElement classElement, ConstantReader annotation)
      : super(classElement, annotation.objectValue);
}
