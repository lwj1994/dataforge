import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'nested.data.dart';

@Dataforge()
class NestedDefaultValues with _NestedDefaultValues {
  @override
  final String name;
  @override
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
  @override
  final String id;
  @override
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
  @override
  final DeepRootExample root;
  SuperDeepRoot({required this.root});

  factory SuperDeepRoot.fromJson(Map<String, dynamic> json) =>
      _SuperDeepRoot.fromJson(json);
}

@Dataforge()
class InnerDefaultValues with _InnerDefaultValues {
  @override
  final int intValue;
  @override
  final String stringValue;
  @override
  final bool boolValue;

  const InnerDefaultValues({
    this.intValue = 42,
    this.stringValue = 'default',
    this.boolValue = true,
  });

  factory InnerDefaultValues.fromJson(Map<String, dynamic> json) =>
      _InnerDefaultValues.fromJson(json);
}
