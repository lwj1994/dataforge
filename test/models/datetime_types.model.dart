import 'package:collection/collection.dart';
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'datetime_types.model.data.dart';

@Dataforge()
class DateTimeTypes with _DateTimeTypes {
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  @override
  @JsonKey(name: 'birth_date')
  final DateTime birthDate;
  @override
  final List<DateTime> eventDates;
  @override
  final List<DateTime>? optionalEventDates;
  @override
  final Map<String, DateTime> namedDates;
  @override
  @JsonKey(readValue: DateTimeTypes._readValue)
  final DateTime? isoDateTime;
  @override
  @JsonKey(readValue: DateTimeTypes._readValue)
  final DateTime timestampDate;
  @override
  @JsonKey(readValue: DateTimeTypes._readValue)
  final DateTime? parsedDate;

  const DateTimeTypes({
    required this.createdAt,
    this.updatedAt,
    required this.birthDate,
    required this.eventDates,
    this.optionalEventDates,
    required this.namedDates,
    this.isoDateTime,
    required this.timestampDate,
    this.parsedDate,
  });

  factory DateTimeTypes.fromJson(Map<String, dynamic> json) {
    return _DateTimeTypes.fromJson(json);
  }

  static Object? _readValue(Map<dynamic, dynamic> map, String key) {
    final value = map[key];

    switch (key) {
      case 'isoDateTime':
        if (value == null) return null;
        if (value is String) {
          try {
            return DateTime.parse(value);
          } catch (e) {
            return null;
          }
        }
        if (value is int) {
          return DateTime.fromMillisecondsSinceEpoch(value);
        }
        return null;

      case 'timestampDate':
        if (value == null) return DateTime.now();
        if (value is int) {
          // Handle both seconds and milliseconds timestamps
          if (value > 1000000000000) {
            // Milliseconds
            return DateTime.fromMillisecondsSinceEpoch(value);
          } else {
            // Seconds
            return DateTime.fromMillisecondsSinceEpoch(value * 1000);
          }
        }
        if (value is double) {
          return DateTime.fromMillisecondsSinceEpoch((value * 1000).round());
        }
        if (value is String) {
          final timestamp = int.tryParse(value);
          if (timestamp != null) {
            if (timestamp > 1000000000000) {
              return DateTime.fromMillisecondsSinceEpoch(timestamp);
            } else {
              return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
            }
          }
          try {
            return DateTime.parse(value);
          } catch (e) {
            return DateTime.now();
          }
        }
        return DateTime.now();

      case 'parsedDate':
        if (value == null) return null;
        if (value is String) {
          // Handle various date formats
          final formats = [
            // ISO format
            RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}'),
            // Date only
            RegExp(r'^\d{4}-\d{2}-\d{2}$'),
            // US format
            RegExp(r'^\d{2}/\d{2}/\d{4}$'),
            // European format
            RegExp(r'^\d{2}\.\d{2}\.\d{4}$'),
          ];
          try {
            // Try ISO format first
            if (formats[0].hasMatch(value)) {
              return DateTime.parse(value);
            }
            // Try date only
            if (formats[1].hasMatch(value)) {
              return DateTime.parse('${value}T00:00:00.000Z');
            }
            // Try US format (MM/dd/yyyy)
            if (formats[2].hasMatch(value)) {
              final parts = value.split('/');
              return DateTime(int.parse(parts[2]), int.parse(parts[0]),
                  int.parse(parts[1]));
            }
            // Try European format (dd.MM.yyyy)
            if (formats[3].hasMatch(value)) {
              final parts = value.split('.');
              return DateTime(int.parse(parts[2]), int.parse(parts[1]),
                  int.parse(parts[0]));
            }
            // Fallback to parse
            return DateTime.parse(value);
          } catch (e) {
            return null;
          }
        }
        return null;

      case 'dateTimeList':
        if (value == null) return null;
        if (value is List) {
          final result = <DateTime>[];
          for (final item in value) {
            if (item is String) {
              try {
                result.add(DateTime.parse(item));
              } catch (e) {
                // Skip invalid dates
              }
            } else if (item is int) {
              if (item > 1000000000000) {
                result.add(DateTime.fromMillisecondsSinceEpoch(item));
              } else {
                result.add(DateTime.fromMillisecondsSinceEpoch(item * 1000));
              }
            }
          }
          return result;
        }
        if (value is String) {
          // Parse comma-separated date strings
          final dateStrings = value.split(',');
          final result = <DateTime>[];
          for (final dateStr in dateStrings) {
            try {
              result.add(DateTime.parse(dateStr.trim()));
            } catch (e) {
              // Skip invalid dates
            }
          }
          return result;
        }
        return null;

      case 'customDuration':
        if (value == null) return null;
        if (value is int) {
          // Assume milliseconds
          return Duration(milliseconds: value);
        }
        if (value is double) {
          // Assume seconds
          return Duration(milliseconds: (value * 1000).round());
        }
        if (value is String) {
          // Parse duration string like "1h 30m 45s" or "PT1H30M45S" (ISO 8601)
          if (value.startsWith('PT')) {
            // ISO 8601 duration format
            try {
              final regex =
                  RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+(?:\.\d+)?)S)?');
              final match = regex.firstMatch(value);
              if (match != null) {
                final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
                final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
                final seconds = double.tryParse(match.group(3) ?? '0') ?? 0;
                return Duration(
                  hours: hours,
                  minutes: minutes,
                  milliseconds: (seconds * 1000).round(),
                );
              }
            } catch (e) {
              return null;
            }
          } else {
            // Simple format like "1h 30m 45s"
            int totalMilliseconds = 0;
            final hourMatch = RegExp(r'(\d+)h').firstMatch(value);
            final minuteMatch = RegExp(r'(\d+)m').firstMatch(value);
            final secondMatch = RegExp(r'(\d+)s').firstMatch(value);
            if (hourMatch != null) {
              totalMilliseconds += (int.parse(hourMatch.group(1)!) * 3600000);
            }
            if (minuteMatch != null) {
              totalMilliseconds += (int.parse(minuteMatch.group(1)!) * 60000);
            }
            if (secondMatch != null) {
              totalMilliseconds += (int.parse(secondMatch.group(1)!) * 1000);
            }
            if (totalMilliseconds > 0) {
              return Duration(milliseconds: totalMilliseconds);
            }
          }
          // Try parsing as milliseconds
          final ms = int.tryParse(value);
          if (ms != null) {
            return Duration(milliseconds: ms);
          }
        }
        return null;

      default:
        return null;
    }
  }
}

@Dataforge()
class TimeZoneTest with _TimeZoneTest {
  @override
  final DateTime utcTime;
  @override
  final DateTime localTime;
  @override
  @JsonKey(readValue: TimeZoneTest._readValue)
  final DateTime? timeZoneAware;
  @override
  final List<DateTime> timeList;

  const TimeZoneTest({
    required this.utcTime,
    required this.localTime,
    this.timeZoneAware,
    required this.timeList,
  });

  factory TimeZoneTest.fromJson(Map<String, dynamic> json) {
    return _TimeZoneTest.fromJson(json);
  }

  static Object? _readValue(Map<dynamic, dynamic> map, String key) {
    final value = map[key];

    switch (key) {
      case 'timeZoneAware':
        if (value == null) return null;
        if (value is String) {
          try {
            // Parse and convert to UTC
            final dateTime = DateTime.parse(value);
            return dateTime.isUtc ? dateTime : dateTime.toUtc();
          } catch (e) {
            return null;
          }
        }
        return null;

      default:
        return null;
    }
  }
}
