import 'dart:convert';
import 'package:test/test.dart';
import '../models/cross_enum_model.dart';
import '../models/enum_import_model.dart';

/// Cross-file enum reference test module
/// Tests: enum types from imported files, enum serialization/deserialization
void runCrossEnumTests() {
  group('Cross-file Enum Reference Tests', () {
    test('enum types from imported files should work correctly', () {
      // Create instance with enums from imported file
      final crossEnum = CrossEnumTest(
        status: LocalStatus.active,
        priority: LocalPriority.high,
        statusList: [LocalStatus.active, LocalStatus.pending],
        priorityMap: {
          'urgent': LocalPriority.high,
          'normal': LocalPriority.medium,
        },
      );

      // Test serialization
      final json = crossEnum.toJson();
      expect(json['status'], equals('active'));
      expect(json['priority'], equals('high'));
      expect(json['statusList'], equals(['active', 'pending']));
      expect(
          json['priorityMap'],
          equals({
            'urgent': 'high',
            'normal': 'medium',
          }));

      // Test deserialization
      final restored = CrossEnumTest.fromJson(json);
      expect(restored.status, equals(LocalStatus.active));
      expect(restored.priority, equals(LocalPriority.high));
      expect(restored.statusList,
          equals([LocalStatus.active, LocalStatus.pending]));
      expect(
          restored.priorityMap,
          equals({
            'urgent': LocalPriority.high,
            'normal': LocalPriority.medium,
          }));

      // Test equality
      expect(restored, equals(crossEnum));
    });

    test('JSON round-trip with cross-file enums', () {
      final original = CrossEnumTest(
        status: LocalStatus.inactive,
        priority: LocalPriority.low,
        statusList: [
          LocalStatus.pending,
          LocalStatus.active,
          LocalStatus.inactive
        ],
        priorityMap: {
          'task1': LocalPriority.high,
          'task2': LocalPriority.medium,
          'task3': LocalPriority.low,
        },
      );

      // Convert to JSON string and back
      final jsonString = jsonEncode(original.toJson());
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final restored = CrossEnumTest.fromJson(decoded);

      expect(restored.status, equals(original.status));
      expect(restored.priority, equals(original.priority));
      expect(restored.statusList, equals(original.statusList));
      expect(restored.priorityMap, equals(original.priorityMap));
      expect(restored, equals(original));
    });

    test('copyWith functionality with cross-file enums', () {
      final original = CrossEnumTest(
        status: LocalStatus.active,
        priority: LocalPriority.medium,
        statusList: [LocalStatus.active],
        priorityMap: {'test': LocalPriority.low},
      );

      // Test copyWith for status
      final updated1 = original.copyWith.status(LocalStatus.pending).build();
      expect(updated1.status, equals(LocalStatus.pending));
      expect(updated1.priority, equals(original.priority));
      expect(updated1.statusList, equals(original.statusList));
      expect(updated1.priorityMap, equals(original.priorityMap));

      // Test copyWith for priority
      final updated2 = original.copyWith.priority(LocalPriority.high).build();
      expect(updated2.status, equals(original.status));
      expect(updated2.priority, equals(LocalPriority.high));
      expect(updated2.statusList, equals(original.statusList));
      expect(updated2.priorityMap, equals(original.priorityMap));

      // Test chained copyWith
      final updated3 = original.copyWith
          .status(LocalStatus.inactive)
          .priority(LocalPriority.high)
          .build();
      expect(updated3.status, equals(LocalStatus.inactive));
      expect(updated3.priority, equals(LocalPriority.high));
      expect(updated3.statusList, equals(original.statusList));
      expect(updated3.priorityMap, equals(original.priorityMap));
    });
  });
}

/// Main function to run cross-file enum tests
void main() {
  runCrossEnumTests();
}
