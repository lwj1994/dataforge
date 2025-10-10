// @author luwenjie on 2025/1/15 10:00:00

import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'default_chained_test.model.data.dart';

@dataforge // Should use chainedCopyWith = true by default
class DefaultChainedTest with _DefaultChainedTest {
  @override
  final String name;
  @override
  final int age;
  @override
  final bool isActive;

  const DefaultChainedTest({
    required this.name,
    required this.age,
    this.isActive = true,
  });

  factory DefaultChainedTest.fromJson(Map<String, dynamic> json) =>
      _DefaultChainedTest.fromJson(json);
}
