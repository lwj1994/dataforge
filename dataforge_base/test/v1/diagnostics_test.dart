import 'package:dataforge_base/src/v1/diagnostics.dart';
import 'package:dataforge_base/src/v1/schema.dart';
import 'package:test/test.dart';

const modelId = SchemaId(libraryUri: 'package:example/user.dart', name: 'User');

void main() {
  group('GenerationDiagnosticCode', () {
    test('内建 code 值稳定，自定义 code 必须匹配 DFdddd', () {
      expect(GenerationDiagnosticCode.mutableField.value, 'DF1002');
      expect(GenerationDiagnosticCode('DF9001').value, 'DF9001');
      expect(
        () => GenerationDiagnosticCode('mutable-field'),
        throwsArgumentError,
      );
    });
  });

  group('GenerationDiagnostic', () {
    test('完整信息支持版本化 round-trip 与 equality/hash', () {
      final diagnostic = GenerationDiagnostic(
        code: GenerationDiagnosticCode.mutableField,
        severity: GenerationDiagnosticSeverity.error,
        message: '字段必须是 final。',
        schemaId: modelId,
        target: 'fields.name',
        location: const GenerationSourceLocation(
          uri: 'package:example/user.dart',
          offset: 42,
          length: 4,
          line: 3,
          column: 9,
        ),
        details: const {
          'expected': 'final String',
          'actual': 'String',
          'path': ['User', 'name'],
        },
      );

      final map = diagnostic.toMap();
      final restored = GenerationDiagnostic.fromMap(map);

      expect(map['formatVersion'], GenerationDiagnostic.currentFormatVersion);
      expect(restored, diagnostic);
      expect(restored.hashCode, diagnostic.hashCode);
      expect(restored.toMap(), map);
      expect(restored.toString(), contains('DF1002/error'));
      expect(restored.toString(), contains('fields.name'));
    });

    test('stableId 不受 message、位置偏移和 details 变化影响', () {
      final first = GenerationDiagnostic(
        code: GenerationDiagnosticCode.constructorMismatch,
        severity: GenerationDiagnosticSeverity.error,
        message: '旧文案',
        schemaId: modelId,
        target: 'constructors.new',
        location: const GenerationSourceLocation(
          uri: 'package:example/user.dart',
          offset: 10,
          length: 3,
          line: 2,
          column: 1,
        ),
        details: const {'parameter': 'name'},
      );
      final second = GenerationDiagnostic(
        code: GenerationDiagnosticCode.constructorMismatch,
        severity: GenerationDiagnosticSeverity.error,
        message: '调整后的文案',
        schemaId: modelId,
        target: 'constructors.new',
        location: const GenerationSourceLocation(
          uri: 'package:example/user.dart',
          offset: 200,
          length: 3,
          line: 20,
          column: 5,
        ),
        details: const {'parameter': 'age'},
      );

      expect(first, isNot(second));
      expect(first.stableId, second.stableId);
      expect(
        first.stableId,
        'DF1003|package:example/user.dart::User|constructors.new',
      );
    });

    test('排序稳定地按 error、warning、info 和 code 排列', () {
      final diagnostics = [
        GenerationDiagnostic(
          code: GenerationDiagnosticCode.invalidModel,
          severity: GenerationDiagnosticSeverity.info,
          message: 'info',
        ),
        GenerationDiagnostic(
          code: GenerationDiagnosticCode.unsupportedType,
          severity: GenerationDiagnosticSeverity.error,
          message: 'error 2',
        ),
        GenerationDiagnostic(
          code: GenerationDiagnosticCode.invalidModel,
          severity: GenerationDiagnosticSeverity.error,
          message: 'error 1',
        ),
        GenerationDiagnostic(
          code: GenerationDiagnosticCode.mutableField,
          severity: GenerationDiagnosticSeverity.warning,
          message: 'warning',
        ),
      ]..sort();

      expect(diagnostics.map((item) => item.severity), [
        GenerationDiagnosticSeverity.error,
        GenerationDiagnosticSeverity.error,
        GenerationDiagnosticSeverity.warning,
        GenerationDiagnosticSeverity.info,
      ]);
      expect(diagnostics.first.code, GenerationDiagnosticCode.invalidModel);
      expect(diagnostics[1].code, GenerationDiagnosticCode.unsupportedType);
    });

    test('details 在构造时递归快照并对外不可变', () {
      final nested = <Object?>[
        <String, Object?>{
          'path': <Object?>['User', 'name'],
        },
      ];
      final input = <String, Object?>{'field': 'name', 'nested': nested};
      final diagnostic = GenerationDiagnostic(
        code: GenerationDiagnosticCode.mutableField,
        severity: GenerationDiagnosticSeverity.error,
        message: 'mutable',
        details: input,
      );

      input['field'] = 'age';
      (nested.single! as Map<String, Object?>)['path'] = <Object?>['changed'];
      expect(diagnostic.details['field'], 'name');
      final frozenNested = diagnostic.details['nested']! as List<Object?>;
      final frozenMap = frozenNested.single! as Map<String, Object?>;
      final frozenPath = frozenMap['path']! as List<Object?>;
      expect(frozenPath, <Object?>['User', 'name']);
      expect(() => diagnostic.details['extra'] = true, throwsUnsupportedError);
      expect(() => frozenNested.add('extra'), throwsUnsupportedError);
      expect(() => frozenMap['extra'] = true, throwsUnsupportedError);
      expect(() => frozenPath.add('extra'), throwsUnsupportedError);
    });

    test('details 拒绝循环、非 String key 与非可传输值', () {
      final cyclic = <Object?>[];
      cyclic.add(cyclic);

      GenerationDiagnostic build(Object? value) => GenerationDiagnostic(
        code: GenerationDiagnosticCode.invalidModel,
        severity: GenerationDiagnosticSeverity.error,
        message: 'invalid',
        details: <String, Object?>{'value': value},
      );

      expect(() => build(cyclic), throwsArgumentError);
      expect(() => build(<Object?, Object?>{1: 'value'}), throwsArgumentError);
      expect(() => build(Object()), throwsArgumentError);
      expect(() => build(double.infinity), throwsArgumentError);
    });

    test('拒绝未知诊断 wire format', () {
      final diagnostic = GenerationDiagnostic(
        code: GenerationDiagnosticCode.invalidModel,
        severity: GenerationDiagnosticSeverity.error,
        message: 'invalid',
      );
      final map = diagnostic.toMap()..['formatVersion'] = 9;

      expect(
        () => GenerationDiagnostic.fromMap(map),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('format version 9'),
          ),
        ),
      );
    });
  });
}
