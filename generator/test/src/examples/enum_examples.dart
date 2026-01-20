import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:source_gen_test/annotations.dart';

enum Status { active, inactive, pending }

enum Priority { low, medium, high, critical }

@ShouldGenerate(r'''
mixin _EnumTypes {
  abstract final Status status;
  _EnumTypesCopyWith<EnumTypes> get copyWith =>
      _EnumTypesCopyWith<EnumTypes>._(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EnumTypes) return false;

    return other.status == status;
  }

  @override
  int get hashCode => Object.hashAll([status]);

  @override
  String toString() => 'EnumTypes(status: $status)';

  Map<String, dynamic> toJson() {
    return {'status': DefaultEnumConverter(Status.values).toJson(status)};
  }

  static EnumTypes fromJson(Map<String, dynamic> json) {
    return EnumTypes(
      status:
          (DefaultEnumConverter(
            Status.values,
          ).fromJson(SafeCasteUtil.readValue<String>(json, 'status')) ??
          Status.values.first),
    );
  }
}

class _EnumTypesCopyWith<R> {
  final _EnumTypes _instance;
  final R Function(EnumTypes)? _then;
  _EnumTypesCopyWith._(this._instance, [this._then]);

  R call({Object? status = dataforgeUndefined}) {
    final res = EnumTypes(
      status: (status == dataforgeUndefined
          ? _instance.status
          : status as Status),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  R status(Status value) {
    final res = EnumTypes(status: value);
    return (_then != null ? _then!(res) : res as R);
  }
}
''')
@Dataforge()
class EnumTypes {
  final Status status;
  EnumTypes({required this.status});
}

@ShouldGenerate(r'''
mixin _EnumListModel {
  abstract final List<Status> statuses;
  _EnumListModelCopyWith<EnumListModel> get copyWith =>
      _EnumListModelCopyWith<EnumListModel>._(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EnumListModel) return false;

    if (!const DeepCollectionEquality().equals(statuses, other.statuses)) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hashAll([const DeepCollectionEquality().hash(statuses)]);

  @override
  String toString() => 'EnumListModel(statuses: $statuses)';

  Map<String, dynamic> toJson() {
    return {
      'statuses': statuses
          .map(
            (e) => const DefaultEnumConverter<Status>(Status.values).toJson(e),
          )
          .toList(),
    };
  }

  static EnumListModel fromJson(Map<String, dynamic> json) {
    return EnumListModel(
      statuses:
          (((SafeCasteUtil.safeCast<List<dynamic>>(json['statuses'])
              ?.map(
                (e) =>
                    (Status.values.firstWhere((ev) => ev.name == e.toString())),
              )
              .toList())) ??
          (const [])),
    );
  }
}

class _EnumListModelCopyWith<R> {
  final _EnumListModel _instance;
  final R Function(EnumListModel)? _then;
  _EnumListModelCopyWith._(this._instance, [this._then]);

  R call({Object? statuses = dataforgeUndefined}) {
    final res = EnumListModel(
      statuses: (statuses == dataforgeUndefined
          ? _instance.statuses
          : (statuses as List).cast<Status>()),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  R statuses(List<Status> value) {
    final res = EnumListModel(statuses: value);
    return (_then != null ? _then!(res) : res as R);
  }
}
''')
@Dataforge()
class EnumListModel {
  final List<Status> statuses;
  EnumListModel({this.statuses = const []});
}

@ShouldGenerate(r'''
mixin _NullableEnumExample {
  abstract final Status? status;
  abstract final Priority? priority;
  _NullableEnumExampleCopyWith<NullableEnumExample> get copyWith =>
      _NullableEnumExampleCopyWith<NullableEnumExample>._(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NullableEnumExample) return false;

    return other.status == status && other.priority == priority;
  }

  @override
  int get hashCode => Object.hashAll([status, priority]);

  @override
  String toString() =>
      'NullableEnumExample(status: $status, priority: $priority)';

  Map<String, dynamic> toJson() {
    return {
      'status': DefaultEnumConverter(Status.values).toJson(status),
      'priority': DefaultEnumConverter(Priority.values).toJson(priority),
    };
  }

  static NullableEnumExample fromJson(Map<String, dynamic> json) {
    return NullableEnumExample(
      status: DefaultEnumConverter(
        Status.values,
      ).fromJson(SafeCasteUtil.readValue<String>(json, 'status')),
      priority: DefaultEnumConverter(
        Priority.values,
      ).fromJson(SafeCasteUtil.readValue<String>(json, 'priority')),
    );
  }
}

class _NullableEnumExampleCopyWith<R> {
  final _NullableEnumExample _instance;
  final R Function(NullableEnumExample)? _then;
  _NullableEnumExampleCopyWith._(this._instance, [this._then]);

  R call({
    Object? status = dataforgeUndefined,
    Object? priority = dataforgeUndefined,
  }) {
    final res = NullableEnumExample(
      status: (status == dataforgeUndefined
          ? _instance.status
          : status as Status?),
      priority: (priority == dataforgeUndefined
          ? _instance.priority
          : priority as Priority?),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  R status(Status? value) {
    final res = NullableEnumExample(
      status: value,
      priority: _instance.priority,
    );
    return (_then != null ? _then!(res) : res as R);
  }

  R priority(Priority? value) {
    final res = NullableEnumExample(status: _instance.status, priority: value);
    return (_then != null ? _then!(res) : res as R);
  }
}
''')
@Dataforge()
class NullableEnumExample {
  final Status? status;
  final Priority? priority;

  NullableEnumExample({
    this.status,
    this.priority,
  });
}

@ShouldGenerate(r'''
mixin _EnumWithDefaultExample {
  abstract final Status status;
  abstract final Priority priority;
  _EnumWithDefaultExampleCopyWith<EnumWithDefaultExample> get copyWith =>
      _EnumWithDefaultExampleCopyWith<EnumWithDefaultExample>._(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EnumWithDefaultExample) return false;

    return other.status == status && other.priority == priority;
  }

  @override
  int get hashCode => Object.hashAll([status, priority]);

  @override
  String toString() =>
      'EnumWithDefaultExample(status: $status, priority: $priority)';

  Map<String, dynamic> toJson() {
    return {
      'status': DefaultEnumConverter(Status.values).toJson(status),
      'priority': DefaultEnumConverter(Priority.values).toJson(priority),
    };
  }

  static EnumWithDefaultExample fromJson(Map<String, dynamic> json) {
    return EnumWithDefaultExample(
      status:
          ((DefaultEnumConverter(
            Status.values,
          ).fromJson(SafeCasteUtil.readValue<String>(json, 'status'))) ??
          (Status.active)),
      priority:
          ((DefaultEnumConverter(
            Priority.values,
          ).fromJson(SafeCasteUtil.readValue<String>(json, 'priority'))) ??
          (Priority.medium)),
    );
  }
}

class _EnumWithDefaultExampleCopyWith<R> {
  final _EnumWithDefaultExample _instance;
  final R Function(EnumWithDefaultExample)? _then;
  _EnumWithDefaultExampleCopyWith._(this._instance, [this._then]);

  R call({
    Object? status = dataforgeUndefined,
    Object? priority = dataforgeUndefined,
  }) {
    final res = EnumWithDefaultExample(
      status: (status == dataforgeUndefined
          ? _instance.status
          : status as Status),
      priority: (priority == dataforgeUndefined
          ? _instance.priority
          : priority as Priority),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  R status(Status value) {
    final res = EnumWithDefaultExample(
      status: value,
      priority: _instance.priority,
    );
    return (_then != null ? _then!(res) : res as R);
  }

  R priority(Priority value) {
    final res = EnumWithDefaultExample(
      status: _instance.status,
      priority: value,
    );
    return (_then != null ? _then!(res) : res as R);
  }
}
''')
@Dataforge()
class EnumWithDefaultExample {
  final Status status;
  final Priority priority;

  EnumWithDefaultExample({
    this.status = Status.active,
    this.priority = Priority.medium,
  });
}

@ShouldGenerate(r'''
mixin _MultipleEnumsExample {
  abstract final Status status;
  abstract final Priority priority;
  abstract final List<Status> statusHistory;
  _MultipleEnumsExampleCopyWith<MultipleEnumsExample> get copyWith =>
      _MultipleEnumsExampleCopyWith<MultipleEnumsExample>._(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MultipleEnumsExample) return false;

    if (status != other.status) {
      return false;
    }
    if (priority != other.priority) {
      return false;
    }
    if (!const DeepCollectionEquality().equals(
      statusHistory,
      other.statusHistory,
    )) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([
    status,
    priority,
    const DeepCollectionEquality().hash(statusHistory),
  ]);

  @override
  String toString() =>
      'MultipleEnumsExample(status: $status, priority: $priority, statusHistory: $statusHistory)';

  Map<String, dynamic> toJson() {
    return {
      'status': DefaultEnumConverter(Status.values).toJson(status),
      'priority': DefaultEnumConverter(Priority.values).toJson(priority),
      'statusHistory': statusHistory
          .map(
            (e) => const DefaultEnumConverter<Status>(Status.values).toJson(e),
          )
          .toList(),
    };
  }

  static MultipleEnumsExample fromJson(Map<String, dynamic> json) {
    return MultipleEnumsExample(
      status:
          (DefaultEnumConverter(
            Status.values,
          ).fromJson(SafeCasteUtil.readValue<String>(json, 'status')) ??
          Status.values.first),
      priority:
          (DefaultEnumConverter(
            Priority.values,
          ).fromJson(SafeCasteUtil.readValue<String>(json, 'priority')) ??
          Priority.values.first),
      statusHistory:
          (((SafeCasteUtil.safeCast<List<dynamic>>(json['statusHistory'])
              ?.map(
                (e) =>
                    (Status.values.firstWhere((ev) => ev.name == e.toString())),
              )
              .toList())) ??
          (const [])),
    );
  }
}

class _MultipleEnumsExampleCopyWith<R> {
  final _MultipleEnumsExample _instance;
  final R Function(MultipleEnumsExample)? _then;
  _MultipleEnumsExampleCopyWith._(this._instance, [this._then]);

  R call({
    Object? status = dataforgeUndefined,
    Object? priority = dataforgeUndefined,
    Object? statusHistory = dataforgeUndefined,
  }) {
    final res = MultipleEnumsExample(
      status: (status == dataforgeUndefined
          ? _instance.status
          : status as Status),
      priority: (priority == dataforgeUndefined
          ? _instance.priority
          : priority as Priority),
      statusHistory: (statusHistory == dataforgeUndefined
          ? _instance.statusHistory
          : (statusHistory as List).cast<Status>()),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  R status(Status value) {
    final res = MultipleEnumsExample(
      status: value,
      priority: _instance.priority,
      statusHistory: _instance.statusHistory,
    );
    return (_then != null ? _then!(res) : res as R);
  }

  R priority(Priority value) {
    final res = MultipleEnumsExample(
      status: _instance.status,
      priority: value,
      statusHistory: _instance.statusHistory,
    );
    return (_then != null ? _then!(res) : res as R);
  }

  R statusHistory(List<Status> value) {
    final res = MultipleEnumsExample(
      status: _instance.status,
      priority: _instance.priority,
      statusHistory: value,
    );
    return (_then != null ? _then!(res) : res as R);
  }
}
''')
@Dataforge()
class MultipleEnumsExample {
  final Status status;
  final Priority priority;
  final List<Status> statusHistory;

  MultipleEnumsExample({
    required this.status,
    required this.priority,
    this.statusHistory = const [],
  });
}
