import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:dataforge_annotation/src/config.dart';
import 'package:test/test.dart';

void main() {
  group('DataforgeInit', () {
    test('init should set the copyWithErrorCallback', () {
      bool called = false;
      String? reportedField;

      DataforgeInit.init(
        onCopyWithError:
            (fieldName, expectedType, actualValue, error, stackTrace) {
          called = true;
          reportedField = fieldName;
        },
      );

      // Trigger an error using SafeCasteUtil
      // Trying to cast a String to int should fail
      SafeCasteUtil.copyWithCastNullable<int>('not an int', 'testField', 1);

      expect(called, isTrue);
      expect(reportedField, equals('testField'));

      // Reset after test - restore default callback
      DataforgeInit.init(
        onCopyWithError: (f, e, a, err, s) {},
      );
    });

    test('init with null should keep existing callback', () {
      final customCallback =
          (String f, String e, Object? a, Object err, StackTrace s) {};
      DataforgeInit.init(onCopyWithError: customCallback);
      expect(DataforgeConfig.copyWithErrorCallback, equals(customCallback));

      // Passing null should not change the callback
      DataforgeInit.init(onCopyWithError: null);
      expect(DataforgeConfig.copyWithErrorCallback, equals(customCallback));
    });
  });
}
