import 'package:dataforge_base/dataforge_base.dart';
import 'package:test/test.dart';

void main() {
  group('DataforgeLogger', () {
    tearDown(() {
      DataforgeLogger.debugEnabled = false;
    });

    test('debugEnabled defaults to false', () {
      expect(DataforgeLogger.debugEnabled, isFalse);
    });

    test('debug does not throw when disabled', () {
      DataforgeLogger.debugEnabled = false;
      expect(() => DataforgeLogger.debug('msg'), returnsNormally);
    });

    test('debug does not throw when enabled', () {
      DataforgeLogger.debugEnabled = true;
      expect(() => DataforgeLogger.debug('msg'), returnsNormally);
    });

    test('info does not throw', () {
      expect(() => DataforgeLogger.info('msg'), returnsNormally);
    });

    test('warning does not throw', () {
      expect(() => DataforgeLogger.warning('msg'), returnsNormally);
    });

    test('error does not throw', () {
      expect(() => DataforgeLogger.error('msg'), returnsNormally);
    });

    test('error with exception does not throw', () {
      expect(
        () => DataforgeLogger.error('msg', Exception('test')),
        returnsNormally,
      );
    });

    test('error with exception and stack trace does not throw', () {
      expect(
        () => DataforgeLogger.error(
          'msg',
          Exception('test'),
          StackTrace.current,
        ),
        returnsNormally,
      );
    });
  });

  group('LogLevel', () {
    test('has all expected values', () {
      expect(LogLevel.values, hasLength(4));
      expect(LogLevel.values, contains(LogLevel.debug));
      expect(LogLevel.values, contains(LogLevel.info));
      expect(LogLevel.values, contains(LogLevel.warning));
      expect(LogLevel.values, contains(LogLevel.error));
    });
  });
}
