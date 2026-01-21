import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:source_gen_test/annotations.dart';

@ShouldGenerate(r'''
mixin _DateTimeExample {
  abstract final DateTime? dateTime;
  @pragma('vm:prefer-inline')
  _DateTimeExampleCopyWith<DateTimeExample> get copyWith =>
      _DateTimeExampleCopyWith<DateTimeExample>._(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DateTimeExample) return false;

    return other.dateTime == dateTime;
  }

  @override
  int get hashCode => Object.hashAll([dateTime]);

  @override
  String toString() => 'DateTimeExample(dateTime: $dateTime)';

  Map<String, dynamic> toJson() {
    return {'dateTime': const DefaultDateTimeConverter().toJson(dateTime)};
  }

  static DateTimeExample fromJson(Map<String, dynamic> json) {
    return DateTimeExample(
      dateTime: SafeCasteUtil.readValue<DateTime>(json, 'dateTime'),
    );
  }
}

class _DateTimeExampleCopyWith<R> {
  final _DateTimeExample _instance;
  final R Function(DateTimeExample)? _then;
  _DateTimeExampleCopyWith._(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({Object? dateTime = dataforgeUndefined}) {
    final res = DateTimeExample(
      dateTime: (dateTime == dataforgeUndefined
          ? _instance.dateTime
          : dateTime as DateTime?),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R dateTime(DateTime? value) {
    final res = DateTimeExample(dateTime: value);
    return (_then != null ? _then!(res) : res as R);
  }
}
''')
@Dataforge()
class DateTimeExample {
  final DateTime? dateTime;
  DateTimeExample({this.dateTime});
}

@ShouldGenerate(r'''
mixin _RequiredDateTimeExample {
  abstract final DateTime createdAt;
  abstract final DateTime updatedAt;
  @pragma('vm:prefer-inline')
  _RequiredDateTimeExampleCopyWith<RequiredDateTimeExample> get copyWith =>
      _RequiredDateTimeExampleCopyWith<RequiredDateTimeExample>._(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RequiredDateTimeExample) return false;

    return other.createdAt == createdAt && other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hashAll([createdAt, updatedAt]);

  @override
  String toString() =>
      'RequiredDateTimeExample(createdAt: $createdAt, updatedAt: $updatedAt)';

  Map<String, dynamic> toJson() {
    return {
      'createdAt': const DefaultDateTimeConverter().toJson(createdAt),
      'updatedAt': const DefaultDateTimeConverter().toJson(updatedAt),
    };
  }

  static RequiredDateTimeExample fromJson(Map<String, dynamic> json) {
    return RequiredDateTimeExample(
      createdAt:
          (SafeCasteUtil.readValue<DateTime>(json, 'createdAt') ??
          DateTime.fromMillisecondsSinceEpoch(0)),
      updatedAt:
          (SafeCasteUtil.readValue<DateTime>(json, 'updatedAt') ??
          DateTime.fromMillisecondsSinceEpoch(0)),
    );
  }
}

class _RequiredDateTimeExampleCopyWith<R> {
  final _RequiredDateTimeExample _instance;
  final R Function(RequiredDateTimeExample)? _then;
  _RequiredDateTimeExampleCopyWith._(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({
    Object? createdAt = dataforgeUndefined,
    Object? updatedAt = dataforgeUndefined,
  }) {
    final res = RequiredDateTimeExample(
      createdAt: (createdAt == dataforgeUndefined
          ? _instance.createdAt
          : createdAt as DateTime),
      updatedAt: (updatedAt == dataforgeUndefined
          ? _instance.updatedAt
          : updatedAt as DateTime),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R createdAt(DateTime value) {
    final res = RequiredDateTimeExample(
      createdAt: value,
      updatedAt: _instance.updatedAt,
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R updatedAt(DateTime value) {
    final res = RequiredDateTimeExample(
      createdAt: _instance.createdAt,
      updatedAt: value,
    );
    return (_then != null ? _then!(res) : res as R);
  }
}
''')
@Dataforge()
class RequiredDateTimeExample {
  final DateTime createdAt;
  final DateTime updatedAt;

  RequiredDateTimeExample({
    required this.createdAt,
    required this.updatedAt,
  });
}

@ShouldGenerate(r'''
mixin _ListDateTimeExample {
  abstract final List<DateTime> timestamps;
  @pragma('vm:prefer-inline')
  _ListDateTimeExampleCopyWith<ListDateTimeExample> get copyWith =>
      _ListDateTimeExampleCopyWith<ListDateTimeExample>._(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ListDateTimeExample) return false;

    if (!const DeepCollectionEquality().equals(timestamps, other.timestamps)) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hashAll([const DeepCollectionEquality().hash(timestamps)]);

  @override
  String toString() => 'ListDateTimeExample(timestamps: $timestamps)';

  Map<String, dynamic> toJson() {
    return {'timestamps': timestamps};
  }

  static ListDateTimeExample fromJson(Map<String, dynamic> json) {
    return ListDateTimeExample(
      timestamps:
          (((SafeCasteUtil.readValue<List<dynamic>>(json, 'timestamps')
              ?.map(
                (e) =>
                    (SafeCasteUtil.safeCast<DateTime>(e) ??
                    DateTime.fromMillisecondsSinceEpoch(0)),
              )
              .toList())) ??
          (const [])),
    );
  }
}

class _ListDateTimeExampleCopyWith<R> {
  final _ListDateTimeExample _instance;
  final R Function(ListDateTimeExample)? _then;
  _ListDateTimeExampleCopyWith._(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({Object? timestamps = dataforgeUndefined}) {
    final res = ListDateTimeExample(
      timestamps: (timestamps == dataforgeUndefined
          ? _instance.timestamps
          : (timestamps as List).cast<DateTime>()),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R timestamps(List<DateTime> value) {
    final res = ListDateTimeExample(timestamps: value);
    return (_then != null ? _then!(res) : res as R);
  }
}
''')
@Dataforge()
class ListDateTimeExample {
  final List<DateTime> timestamps;

  ListDateTimeExample({this.timestamps = const []});
}

class CustomDateTimeConverter extends JsonTypeConverter<DateTime, String> {
  const CustomDateTimeConverter();

  @override
  DateTime? fromJson(String? json) {
    if (json == null) return null;
    return DateTime.tryParse(json);
  }

  @override
  String? toJson(DateTime? object) {
    if (object == null) return null;
    return object.toIso8601String();
  }
}

@ShouldGenerate(r'''
mixin _CustomDateTimeConverterExample {
  abstract final DateTime? customDateTime;
  @pragma('vm:prefer-inline')
  _CustomDateTimeConverterExampleCopyWith<CustomDateTimeConverterExample>
  get copyWith =>
      _CustomDateTimeConverterExampleCopyWith<CustomDateTimeConverterExample>._(
        this,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CustomDateTimeConverterExample) return false;

    return other.customDateTime == customDateTime;
  }

  @override
  int get hashCode => Object.hashAll([customDateTime]);

  @override
  String toString() =>
      'CustomDateTimeConverterExample(customDateTime: $customDateTime)';

  Map<String, dynamic> toJson() {
    return {
      'customDateTime': const CustomDateTimeConverter().toJson(customDateTime),
    };
  }

  static CustomDateTimeConverterExample fromJson(Map<String, dynamic> json) {
    return CustomDateTimeConverterExample(
      customDateTime: const CustomDateTimeConverter().fromJson(
        json['customDateTime'],
      ),
    );
  }
}

class _CustomDateTimeConverterExampleCopyWith<R> {
  final _CustomDateTimeConverterExample _instance;
  final R Function(CustomDateTimeConverterExample)? _then;
  _CustomDateTimeConverterExampleCopyWith._(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({Object? customDateTime = dataforgeUndefined}) {
    final res = CustomDateTimeConverterExample(
      customDateTime: (customDateTime == dataforgeUndefined
          ? _instance.customDateTime
          : customDateTime as DateTime?),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R customDateTime(DateTime? value) {
    final res = CustomDateTimeConverterExample(customDateTime: value);
    return (_then != null ? _then!(res) : res as R);
  }
}
''')
@Dataforge()
class CustomDateTimeConverterExample {
  @JsonKey(converter: CustomDateTimeConverter())
  final DateTime? customDateTime;

  CustomDateTimeConverterExample({this.customDateTime});
}

@ShouldGenerate(r'''
mixin _DateTimeWithDefaultExample {
  abstract final DateTime createdAt;
  @pragma('vm:prefer-inline')
  _DateTimeWithDefaultExampleCopyWith<DateTimeWithDefaultExample>
  get copyWith =>
      _DateTimeWithDefaultExampleCopyWith<DateTimeWithDefaultExample>._(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DateTimeWithDefaultExample) return false;

    return other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hashAll([createdAt]);

  @override
  String toString() => 'DateTimeWithDefaultExample(createdAt: $createdAt)';

  Map<String, dynamic> toJson() {
    return {'createdAt': const DefaultDateTimeConverter().toJson(createdAt)};
  }

  static DateTimeWithDefaultExample fromJson(Map<String, dynamic> json) {
    return DateTimeWithDefaultExample(
      createdAt:
          (SafeCasteUtil.readValue<DateTime>(json, 'createdAt') ??
          DateTime.fromMillisecondsSinceEpoch(0)),
    );
  }
}

class _DateTimeWithDefaultExampleCopyWith<R> {
  final _DateTimeWithDefaultExample _instance;
  final R Function(DateTimeWithDefaultExample)? _then;
  _DateTimeWithDefaultExampleCopyWith._(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({Object? createdAt = dataforgeUndefined}) {
    final res = DateTimeWithDefaultExample(
      createdAt: (createdAt == dataforgeUndefined
          ? _instance.createdAt
          : createdAt as DateTime),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R createdAt(DateTime value) {
    final res = DateTimeWithDefaultExample(createdAt: value);
    return (_then != null ? _then!(res) : res as R);
  }
}
''')
@Dataforge()
class DateTimeWithDefaultExample {
  final DateTime createdAt;

  DateTimeWithDefaultExample({
    required this.createdAt,
  });
}
