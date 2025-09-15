import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:collection/collection.dart';
import 'enum_import_model.dart'; // Import file containing enums

part 'cross_enum_model.data.dart';

@Dataforge()
class CrossEnumTest with _CrossEnumTest {
  @override
  final LocalStatus status; // Enum from imported file
  @override
  final LocalPriority priority; // Enum from imported file
  @override
  final List<LocalStatus> statusList; // List of enums from imported file
  @override
  final Map<String, LocalPriority>
      priorityMap; // Map with enum values from imported file

  const CrossEnumTest({
    required this.status,
    required this.priority,
    required this.statusList,
    required this.priorityMap,
  });

  factory CrossEnumTest.fromJson(Map<String, dynamic> json) {
    return _CrossEnumTest.fromJson(json);
  }
}
