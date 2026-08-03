import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:test/test.dart';

void main() {
  test('public v1 API 只暴露 resolved generation facade', () async {
    final result = await resolveFile(
      path: '${Directory.current.path}/lib/dataforge_base.dart',
    );
    expect(result, isA<ResolvedUnitResult>());

    final namespace =
        (result as ResolvedUnitResult).libraryElement.exportNamespace;
    for (final name in const [
      'V1ResolvedModelGenerator',
      'V1ResolvedGeneration',
      'GenerationDiagnostic',
      'SchemaId',
    ]) {
      expect(namespace.get2(name), isNotNull, reason: '$name 应为 public API');
    }
    for (final name in const [
      'ModelSchema',
      'TypeShape',
      'ModelSchemaWriter',
      'ModelSchemaWriterException',
      'V1ModelSchemaBuilder',
      'BuildResult',
    ]) {
      expect(namespace.get2(name), isNull, reason: '$name 必须保持 internal');
    }
  });
}
