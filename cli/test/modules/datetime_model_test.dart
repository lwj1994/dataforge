import 'package:test/test.dart';
import '../models/datetime_converter_model.model.dart';

void main() {
  group('DateTimeModel with DateTimeConverter', () {
    test('handles various datetime formats in fromJson', () {
      final now = DateTime.now();
      final millisTimestamp = now.millisecondsSinceEpoch;
      final secondsTimestamp = (millisTimestamp / 1000).floor();
      final isoString = now.toIso8601String();

      final json = {
        'timestamp': isoString,
        'millisTimestamp': millisTimestamp,
        'secondsTimestamp': secondsTimestamp,
        'isoDate': 'custom object',
      };

      final model = DateTimeModel.fromJson(json);

      // ISO string should be parsed correctly
      expect(model.timestamp?.year, equals(now.year));
      expect(model.timestamp?.month, equals(now.month));
      expect(model.timestamp?.day, equals(now.day));

      // Millisecond timestamp should be parsed correctly
      expect(model.millisTimestamp?.millisecondsSinceEpoch,
          equals(millisTimestamp));

      // Second timestamp should be padded to milliseconds
      expect(model.secondsTimestamp?.millisecondsSinceEpoch,
          equals(secondsTimestamp * 1000));

      // Non-parseable string should return null for that field
      final modelWithInvalidDate =
          DateTimeModel.fromJson({'isoDate': 'not a date'});
      expect(modelWithInvalidDate.isoDate, isNull);
    });

    test('handles toJson conversion', () {
      final now = DateTime.now();
      final model = DateTimeModel(
        timestamp: now,
        millisTimestamp: now,
        secondsTimestamp: now,
        isoDate: now,
      );

      final json = model.toJson();

      // All fields should be converted to millisecond timestamps as strings
      expect(json['timestamp'], equals(now.millisecondsSinceEpoch.toString()));
      expect(json['millisTimestamp'],
          equals(now.millisecondsSinceEpoch.toString()));
      expect(json['secondsTimestamp'],
          equals(now.millisecondsSinceEpoch.toString()));
      expect(json['isoDate'], equals(now.millisecondsSinceEpoch.toString()));
    });
  });
}
