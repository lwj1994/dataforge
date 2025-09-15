import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:collection/collection.dart';

part 'enum_import_model.data.dart';

// This file contains enum definitions for testing cross-file enum references
// It does not need a main function as it's a model definition file

// Define enums in this file
enum LocalStatus {
  pending,
  active,
  inactive,
  suspended,
}

enum LocalPriority {
  low,
  medium,
  high,
  urgent,
}

@Dataforge()
class EnumImportTest with _EnumImportTest {
  @override
  final LocalStatus status;
  @override
  final LocalPriority priority;
  @override
  final List<LocalStatus> statusList;
  @override
  final Map<String, LocalPriority> priorityMap;

  const EnumImportTest({
    required this.status,
    required this.priority,
    required this.statusList,
    required this.priorityMap,
  });

  factory EnumImportTest.fromJson(Map<String, dynamic> json) {
    return _EnumImportTest.fromJson(json);
  }
}
