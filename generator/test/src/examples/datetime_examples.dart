import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:source_gen_test/annotations.dart';

@ShouldGenerate(r'''
mixin _DateTimeExample {
  abstract final DateTime? dateTime;
  @pragma('vm:prefer-inline')
  DateTimeExampleCopyWith<DateTimeExample> get copyWith =>
      DateTimeExampleCopyWith<DateTimeExample>(this);

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

class DateTimeExampleCopyWith<R> {
  final _DateTimeExample _instance;
  final R Function(DateTimeExample)? _then;
  // ignore: library_private_types_in_public_api
  DateTimeExampleCopyWith(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({Object? dateTime = dataforgeUndefined}) {
    final res = DateTimeExample(
      dateTime: SafeCasteUtil.copyWithCastNullable<DateTime>(
        dateTime,
        'dateTime',
        _instance.dateTime,
      ),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R dateTime(DateTime? value) {
    final res = call(dateTime: value);
    return res;
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
  RequiredDateTimeExampleCopyWith<RequiredDateTimeExample> get copyWith =>
      RequiredDateTimeExampleCopyWith<RequiredDateTimeExample>(this);

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
      createdAt: SafeCasteUtil.readRequiredValue<DateTime>(json, 'createdAt'),
      updatedAt: SafeCasteUtil.readRequiredValue<DateTime>(json, 'updatedAt'),
    );
  }
}

class RequiredDateTimeExampleCopyWith<R> {
  final _RequiredDateTimeExample _instance;
  final R Function(RequiredDateTimeExample)? _then;
  // ignore: library_private_types_in_public_api
  RequiredDateTimeExampleCopyWith(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({
    Object? createdAt = dataforgeUndefined,
    Object? updatedAt = dataforgeUndefined,
  }) {
    final res = RequiredDateTimeExample(
      createdAt: SafeCasteUtil.copyWithCast<DateTime>(
        createdAt,
        'createdAt',
        _instance.createdAt,
      ),
      updatedAt: SafeCasteUtil.copyWithCast<DateTime>(
        updatedAt,
        'updatedAt',
        _instance.updatedAt,
      ),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R createdAt(DateTime value) {
    final res = call(createdAt: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  R updatedAt(DateTime value) {
    final res = call(updatedAt: value);
    return res;
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
  ListDateTimeExampleCopyWith<ListDateTimeExample> get copyWith =>
      ListDateTimeExampleCopyWith<ListDateTimeExample>(this);

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
    return {
      'timestamps': timestamps
          .map((e) => const DefaultDateTimeConverter().toJson(e))
          .toList(),
    };
  }

  static ListDateTimeExample fromJson(Map<String, dynamic> json) {
    return ListDateTimeExample(
      timestamps:
          (((SafeCasteUtil.readValue<List<dynamic>>(json, 'timestamps')
              ?.map(
                (e) =>
                    ((SafeCasteUtil.safeCast<DateTime>(e)) ??
                    (throw ArgumentError(
                      'Required field "timestamps" (type: DateTime) is missing or invalid. in collection field "timestamps"',
                    ))),
              )
              .toList())) ??
          (const [])),
    );
  }
}

class ListDateTimeExampleCopyWith<R> {
  final _ListDateTimeExample _instance;
  final R Function(ListDateTimeExample)? _then;
  // ignore: library_private_types_in_public_api
  ListDateTimeExampleCopyWith(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({Object? timestamps = dataforgeUndefined}) {
    final res = ListDateTimeExample(
      timestamps: SafeCasteUtil.copyWithCastList<DateTime>(
        timestamps,
        'timestamps',
        _instance.timestamps,
      ),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R timestamps(List<DateTime> value) {
    final res = call(timestamps: value);
    return res;
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
  CustomDateTimeConverterExampleCopyWith<CustomDateTimeConverterExample>
  get copyWith =>
      CustomDateTimeConverterExampleCopyWith<CustomDateTimeConverterExample>(
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
      'customDateTime': (CustomDateTimeConverter()).toJson(customDateTime),
    };
  }

  static CustomDateTimeConverterExample fromJson(Map<String, dynamic> json) {
    return CustomDateTimeConverterExample(
      customDateTime: (CustomDateTimeConverter()).fromJson(
        json['customDateTime'],
      ),
    );
  }
}

class CustomDateTimeConverterExampleCopyWith<R> {
  final _CustomDateTimeConverterExample _instance;
  final R Function(CustomDateTimeConverterExample)? _then;
  // ignore: library_private_types_in_public_api
  CustomDateTimeConverterExampleCopyWith(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({Object? customDateTime = dataforgeUndefined}) {
    final res = CustomDateTimeConverterExample(
      customDateTime: SafeCasteUtil.copyWithCastNullable<DateTime>(
        customDateTime,
        'customDateTime',
        _instance.customDateTime,
      ),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R customDateTime(DateTime? value) {
    final res = call(customDateTime: value);
    return res;
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
  DateTimeWithDefaultExampleCopyWith<DateTimeWithDefaultExample> get copyWith =>
      DateTimeWithDefaultExampleCopyWith<DateTimeWithDefaultExample>(this);

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
      createdAt: SafeCasteUtil.readRequiredValue<DateTime>(json, 'createdAt'),
    );
  }
}

class DateTimeWithDefaultExampleCopyWith<R> {
  final _DateTimeWithDefaultExample _instance;
  final R Function(DateTimeWithDefaultExample)? _then;
  // ignore: library_private_types_in_public_api
  DateTimeWithDefaultExampleCopyWith(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({Object? createdAt = dataforgeUndefined}) {
    final res = DateTimeWithDefaultExample(
      createdAt: SafeCasteUtil.copyWithCast<DateTime>(
        createdAt,
        'createdAt',
        _instance.createdAt,
      ),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R createdAt(DateTime value) {
    final res = call(createdAt: value);
    return res;
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
