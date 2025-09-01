import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'auto_type_matching_example.data.dart';

// Example enum for demonstration
enum Priority { low, medium, high }

enum Status { pending, active, completed, cancelled }

/// Example demonstrating automatic type matching for converters
///
/// When you declare fields with DateTime, Duration, or enum types,
/// the system will automatically apply the appropriate converters
/// without requiring explicit @JsonKey(converter: ...) annotations.
@dataforge
class AutoMatchingExample with _AutoMatchingExample {
  // DateTime fields - automatically uses DateTimeConverter
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;

  // Duration fields - automatically uses DurationConverter
  @override
  final Duration processingTime;
  @override
  final Duration? timeout;

  // Enum fields - automatically uses EnumConverter
  @override
  final Priority priority;
  @override
  final Status? status;

  // Basic types - no converter needed
  @override
  final String title;
  @override
  final int count;
  @override
  final double price;
  @override
  final bool isActive;

  // You can still override with explicit converters if needed
  @override
  @JsonKey(converter: DateTimeMillisecondsConverter())
  final DateTime timestampField;

  @override
  @JsonKey(converter: EnumIndexConverter<Priority>(Priority.values))
  final Priority indexBasedPriority;

  const AutoMatchingExample({
    required this.createdAt,
    this.updatedAt,
    required this.processingTime,
    this.timeout,
    required this.priority,
    this.status,
    required this.title,
    required this.count,
    required this.price,
    required this.isActive,
    required this.timestampField,
    required this.indexBasedPriority,
  });
  factory AutoMatchingExample.fromJson(Map<String, dynamic> json) {
    return _AutoMatchingExample.fromJson(json);
  }
}

// Example usage and expected JSON output
void main() {
  final example = AutoMatchingExample(
    createdAt: DateTime(2024, 1, 15, 10, 30),
    updatedAt: DateTime(2024, 1, 16, 14, 45),
    processingTime: Duration(minutes: 5, seconds: 30),
    timeout: Duration(seconds: 30),
    priority: Priority.high,
    status: Status.active,
    title: 'Auto Matching Demo',
    count: 42,
    price: 99.99,
    isActive: true,
    timestampField: DateTime(2024, 1, 15, 10, 30),
    indexBasedPriority: Priority.medium,
  );

  print('=== Auto Type Matching Example ===');
  print('Original object: $example');

  // Convert to JSON - automatic converters will be applied
  final json = example.toJson();
  print('\nJSON representation:');
  print(json);

  // Convert back from JSON - automatic converters will be applied
  final restored = AutoMatchingExample.fromJson(json);
  print('\nRestored object: $restored');

  print('\n=== Expected JSON Structure ===');
  print('''
{
  "createdAt": "2024-01-15T10:30:00.000",     // DateTimeConverter (ISO 8601)
  "updatedAt": "2024-01-16T14:45:00.000",     // DateTimeConverter (ISO 8601)
  "processingTime": 330000000,                 // DurationConverter (microseconds)
  "timeout": 30000000,                         // DurationConverter (microseconds)
  "priority": "high",                          // EnumConverter (string name)
  "status": "active",                          // EnumConverter (string name)
  "title": "Auto Matching Demo",               // No converter (basic type)
  "count": 42,                                 // No converter (basic type)
  "price": 99.99,                              // No converter (basic type)
  "isActive": true,                            // No converter (basic type)
  "timestampField": 1705314600000,             // DateTimeMillisecondsConverter (explicit)
  "indexBasedPriority": 1                      // EnumIndexConverter (explicit)
}''');
}

/*
Key Benefits of Auto Type Matching:

1. **Reduced Boilerplate**: No need to explicitly specify converters for common types
2. **Consistency**: All DateTime fields use the same converter by default
3. **Flexibility**: Can still override with explicit converters when needed
4. **Type Safety**: Automatic detection based on Dart type system
5. **Maintainability**: Less code to maintain and fewer chances for errors

Supported Auto-Matching Types:
- DateTime → DateTimeConverter (ISO 8601 strings)
- Duration → DurationConverter (microseconds)
- Enum types → EnumConverter (string names)

Basic types (String, int, double, bool, etc.) don't need converters and are handled natively.
*/
