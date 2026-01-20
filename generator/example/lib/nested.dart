import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'nested.data.dart';

@Dataforge()
class NestedDefaultValues with _NestedDefaultValues {
  final String name;
  final InnerDefaultValues nested;
  NestedDefaultValues({
    this.name = 'nested_default',
    this.nested = const InnerDefaultValues(),
  });

  factory NestedDefaultValues.fromJson(Map<String, dynamic> json) =>
      _NestedDefaultValues.fromJson(json);
}

@Dataforge()
class DeepRootExample with _DeepRootExample {
  final String id;
  final NestedDefaultValues root;

  DeepRootExample({
    required this.id,
    required this.root,
  });

  factory DeepRootExample.fromJson(Map<String, dynamic> json) =>
      _DeepRootExample.fromJson(json);
}

@Dataforge()
class SuperDeepRoot with _SuperDeepRoot {
  final DeepRootExample root;
  SuperDeepRoot({required this.root});

  factory SuperDeepRoot.fromJson(Map<String, dynamic> json) =>
      _SuperDeepRoot.fromJson(json);
}

@Dataforge()
class InnerDefaultValues with _InnerDefaultValues {
  final int intValue;
  final String stringValue;
  final bool boolValue;

  const InnerDefaultValues({
    this.intValue = 42,
    this.stringValue = 'default',
    this.boolValue = true,
  });

  factory InnerDefaultValues.fromJson(Map<String, dynamic> json) =>
      _InnerDefaultValues.fromJson(json);
}
