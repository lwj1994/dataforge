import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'datetime_converter_model.model.data.dart';

@Dataforge()
class DateTimeModel with _DateTimeModel {
  // 使用 DateTimeConverter 处理各种类型的日期时间输入
  @override
  @JsonKey(converter: DefaultDateTimeConverter())
  final DateTime? timestamp;

  // 使用 DateTimeConverter 处理毫秒时间戳
  @override
  @JsonKey(converter: DefaultDateTimeConverter())
  final DateTime? millisTimestamp;

  // 使用 DateTimeConverter 处理秒级时间戳
  @override
  @JsonKey(converter: DefaultDateTimeConverter())
  final DateTime? secondsTimestamp;

  // 使用 DateTimeConverter 处理 ISO 格式字符串
  @override
  @JsonKey(converter: DefaultDateTimeConverter())
  final DateTime? isoDate;

  const DateTimeModel({
    this.timestamp,
    this.millisTimestamp,
    this.secondsTimestamp,
    this.isoDate,
  });

  factory DateTimeModel.fromJson(Map<String, dynamic> json) {
    return _DateTimeModel.fromJson(json);
  }
}
