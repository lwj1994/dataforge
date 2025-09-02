import 'package:test/test.dart';
import 'dart:io';
import 'package:dataforge/dataforge.dart';

void main() {
  group('Chained CopyWith Tests', () {
    setUpAll(() async {
      // Generate test models
      generate('test/models/chained_copywith_test.model.dart');
    });

    test('should generate chained copyWith when enabled', () {
      final generatedFile =
          File('test/models/chained_copywith_test.model.data.dart');
      expect(generatedFile.existsSync(), isTrue);

      final content = generatedFile.readAsStringSync();

      // Check for copyWith getter
      expect(content, contains('get copyWith =>'));

      // Check for helper class
      expect(content, contains('class _UserCopyWith'));

      // Check for field methods
      expect(content, contains('User name(String? value)'));
      expect(content, contains('User age(int? value)'));

      // Check for call method (traditional copyWith)
      expect(content, contains('User call({'));
    });

    test('should generate traditional copyWith when disabled', () {
      final generatedFile =
          File('test/models/traditional_copywith_test.model.data.dart');
      expect(generatedFile.existsSync(), isTrue);

      final content = generatedFile.readAsStringSync();

      // Check for traditional copyWith method
      expect(content, contains('User copyWith({'));

      // Should not contain chained copyWith elements
      expect(content, isNot(contains('get copyWith =>')));
      expect(content, isNot(contains('class _UserCopyWith')));
    });
  });
}
