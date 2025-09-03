// Example demonstrating the usage of built-in type converters

import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'builtin_converters_example.data.dart';

// Example enum for demonstration
enum Priority {
  low,
  medium,
  high,
  critical,
}

// Example data class using built-in converters
@dataforge
class Task with _Task {
  @override
  final String title;

  // Using DateTimeConverter to serialize DateTime as ISO 8601 string
  @override
  @JsonKey(converter: DateTimeConverter())
  final DateTime createdAt;

  // Using DateTimeMillisecondsConverter to serialize DateTime as timestamp
  @override
  @JsonKey(converter: DateTimeMillisecondsConverter())
  final DateTime? dueDate;

  // Using DurationConverter to serialize Duration as microseconds
  @override
  @JsonKey(converter: DurationConverter())
  final Duration estimatedTime;

  // Using DurationMillisecondsConverter to serialize Duration as milliseconds
  @override
  @JsonKey(converter: DurationMillisecondsConverter())
  final Duration? actualTime;

  // Using EnumConverter to serialize enum as string name
  @override
  @JsonKey(converter: EnumConverter(Priority.values))
  final Priority priority;

  // Using EnumIndexConverter to serialize enum as index
  @override
  @JsonKey(converter: EnumIndexConverter(Priority.values))
  final Priority? secondaryPriority;

  @override
  final bool isCompleted;

  const Task({
    required this.title,
    required this.createdAt,
    this.dueDate,
    required this.estimatedTime,
    this.actualTime,
    required this.priority,
    this.secondaryPriority,
    this.isCompleted = false,
  });
  factory Task.fromJson(Map<String, dynamic> json) {
    return _Task.fromJson(json);
  }
}

void main() {
  // Create a sample task
  final task = Task(
    title: 'Implement built-in converters',
    createdAt: DateTime(2023, 12, 25, 10, 30, 45),
    dueDate: DateTime(2023, 12, 31, 23, 59, 59),
    estimatedTime: const Duration(hours: 8),
    actualTime: const Duration(hours: 6, minutes: 30),
    priority: Priority.high,
    secondaryPriority: Priority.medium,
    isCompleted: true,
  );

  print('Task created: ${task.title}');
  print('Created at: ${task.createdAt}');
  print('Due date: ${task.dueDate}');
  print('Estimated time: ${task.estimatedTime}');
  print('Actual time: ${task.actualTime}');
  print('Priority: ${task.priority}');
  print('Secondary priority: ${task.secondaryPriority}');
  print('Is completed: ${task.isCompleted}');

  // Note: To see the actual JSON serialization, you would need to run
  // the code generator to create the toJson() and fromJson() methods.
  // Example generated JSON would look like:
  // {
  //   "title": "Implement built-in converters",
  //   "createdAt": "2023-12-25T10:30:45.000",
  //   "dueDate": 1704067199000,
  //   "estimatedTime": 28800000000,
  //   "actualTime": 23400000,
  //   "priority": "high",
  //   "secondaryPriority": 1,
  //   "isCompleted": true
  // }
}
