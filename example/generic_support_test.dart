import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:collection/collection.dart';

part 'generic_support_test.data.dart';

@Dataforge(includeFromJson: true, includeToJson: true)
class GenericPair<T, U> with _GenericPair<T, U> {
  @override
  final T first;
  @override
  final U second;

  const GenericPair({
    required this.first,
    required this.second,
  });
  factory GenericPair.fromJson(Map<String, dynamic> json) {
    return _GenericPair.fromJson(json);
  }
}

@Dataforge(includeFromJson: true, includeToJson: true)
class GenericWrapper<T> with _GenericWrapper<T> {
  @override
  final T value;
  @override
  final String label;

  const GenericWrapper({
    required this.value,
    required this.label,
  });
  factory GenericWrapper.fromJson(Map<String, dynamic> json) {
    return _GenericWrapper.fromJson(json);
  }
}

@Dataforge(includeFromJson: true, includeToJson: true)
class GenericBounded<T extends num> with _GenericBounded<T> {
  @override
  final T number;
  @override
  final String description;

  const GenericBounded({
    required this.number,
    required this.description,
  });
  factory GenericBounded.fromJson(Map<String, dynamic> json) {
    return _GenericBounded.fromJson(json);
  }
}

@Dataforge(includeFromJson: true, includeToJson: true)
class GenericWithFeatures<T> with _GenericWithFeatures<T> {
  @override
  final T data;
  @override
  final List<String> tags;
  @override
  final Map<String, dynamic> metadata;
  @override
  final DateTime createdAt;
  @override
  final TestStatus status;
  @override
  final Duration? timeout;

  const GenericWithFeatures({
    required this.data,
    required this.tags,
    required this.metadata,
    required this.createdAt,
    required this.status,
    this.timeout,
  });
  factory GenericWithFeatures.fromJson(Map<String, dynamic> json) {
    return _GenericWithFeatures.fromJson(json);
  }
}

enum TestStatus {
  pending,
  running,
  completed,
  failed,
}
