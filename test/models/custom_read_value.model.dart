import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:collection/collection.dart';

part 'custom_read_value.model.data.dart';

@Dataforge()
class CustomReadValue with _CustomReadValue {
  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey(readValue: CustomReadValue._readValue)
  final String title;
  @override
  @JsonKey(readValue: CustomReadValue._readValue)
  final int count;
  @override
  @JsonKey(readValue: CustomReadValue._readValue)
  final bool enabled;
  @override
  @JsonKey(readValue: CustomReadValue._readValue)
  final DateTime? createdDate;
  @override
  @JsonKey(readValue: CustomReadValue._readValue)
  final Map<String, dynamic>? config;
  @override
  @JsonKey(readValue: CustomReadValue._readValue)
  final List<String>? tags;

  const CustomReadValue({
    required this.id,
    required this.name,
    required this.title,
    required this.count,
    required this.enabled,
    this.createdDate,
    this.config,
    this.tags,
  });

  // Unified static method for handling various field reading
  static Object? _readValue(Map<dynamic, dynamic> map, String key) {
    switch (key) {
      case 'title':
        return (map[key] as String?)?.toUpperCase() ?? '';
      case 'count':
        return int.tryParse(map[key]?.toString() ?? '0') ?? 0;
      case 'enabled':
        return map[key]?.toString().toLowerCase() == 'true';
      case 'createdDate':
        return map[key] != null ? DateTime.tryParse(map[key].toString()) : null;
      case 'config':
        return map[key] is String ? {} : (map[key] as Map<String, dynamic>?);
      case 'tags':
        return map[key] is String
            ? (map[key] as String).split(',').map((e) => e.trim()).toList()
            : (map[key] as List<dynamic>?)?.cast<String>();
      default:
        return map[key];
    }
  }

  factory CustomReadValue.fromJson(Map<String, dynamic> json) {
    return _CustomReadValue.fromJson(json);
  }
}
