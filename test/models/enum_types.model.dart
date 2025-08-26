import 'package:data_class_annotation/data_class_annotation.dart';
import 'package:collection/collection.dart';

part 'enum_types.model.data.dart';

enum Status { active, inactive, pending }

enum UserRole { admin, user, guest }

enum Priority { low, medium, high, urgent }

@DataClass()
class EnumTypes with _EnumTypes {
  @override
  final Status status;
  @override
  final UserRole? optionalRole;
  @override
  @JsonKey(name: 'user_type')
  final UserRole userType;
  @override
  final Priority priority;
  @override
  @JsonKey(readValue: EnumTypes._readValue)
  final Status parsedStatus;
  @override
  @JsonKey(readValue: EnumTypes._readValue)
  final UserRole? roleFromInt;
  @override
  final List<Status>? statusList;
  @override
  final Map<String, UserRole>? roleMap;

  const EnumTypes({
    required this.status,
    this.optionalRole,
    required this.userType,
    required this.priority,
    required this.parsedStatus,
    this.roleFromInt,
    this.statusList,
    this.roleMap,
  });

  factory EnumTypes.fromJson(Map<String, dynamic> json) {
    return _EnumTypes.fromJson(json);
  }

  static Object? _readValue(Map<dynamic, dynamic> map, String key) {
    final value = map[key];

    switch (key) {
      case 'parsedStatus':
        if (value == null) return null;
        final statusStr = value.toString().toLowerCase();
        switch (statusStr) {
          case 'active':
          case '1':
          case 'true':
            return Status.active;
          case 'inactive':
          case '0':
          case 'false':
            return Status.inactive;
          case 'pending':
          case '2':
            return Status.pending;
          default:
            return Status.pending;
        }

      case 'roleFromInt':
        if (value == null) return null;
        final roleInt = int.tryParse(value.toString()) ?? 0;
        switch (roleInt) {
          case 0:
            return UserRole.admin;
          case 1:
            return UserRole.user;
          case 2:
            return UserRole.guest;
          default:
            return UserRole.user;
        }

      default:
        return null;
    }
  }
}
