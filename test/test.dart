import 'package:test/test.dart';

import 'modules/auto_generation_test.dart';
import 'modules/converters_test.dart';
import 'modules/copywith_test.dart';
// Import all test modules
import 'modules/core_functionality_test.dart';
import 'modules/custom_serialization_test.dart';
import 'modules/datetime_extended_test.dart';
import 'modules/enum_types_test.dart';
import 'modules/generator_test.dart';
import 'modules/ignore_test.dart';
import 'modules/map_types_test.dart';
import 'modules/nested_objects_test.dart';
import 'modules/performance_test.dart';

/// 统一测试入口
///
/// 按功能模块组织的完整测试套件：
/// - 核心功能：字段别名、向后兼容性、默认值处理
/// - CopyWith功能：链式copyWith、传统copyWith、深度嵌套copyWith
/// - 转换器：内置转换器、自动类型匹配
/// - 忽略字段：忽略逻辑、忽略验证
/// - 性能测试：文件操作性能
/// - 代码生成器：端到端生成测试
/// - 枚举类型：枚举序列化、反序列化、集合处理
/// - Map类型：基础Map、嵌套Map、自定义键名
/// - 嵌套对象：基础嵌套、对象列表、对象映射、深层嵌套
/// - DateTime扩展：多种格式、集合类型、自定义解析、转换器集成
/// - 自定义序列化：readValue函数、JsonKey注解、自定义转换器
/// - 自动生成：with子句、导入语句、构造函数、工具方法
void main() {
  group('Data Class Generator Test Suite', () {
    group('Core Functionality', () {
      runCoreFunctionalityTests();
    });

    group('CopyWith Functionality', () {
      runCopyWithTests();
    });

    group('Type Converters', () {
      runConvertersTests();
    });

    group('Ignore Fields', () {
      runIgnoreTests();
    });

    group('Performance', () {
      runPerformanceTests();
    });

    group('Code Generator', () {
      runGeneratorTests();
    });

    group('Enum Types', () {
      runEnumTypesTests();
    });

    group('Map Types', () {
      runMapTypesTests();
    });

    group('Nested Objects', () {
      runNestedObjectsTests();
    });

    group('DateTime Extended', () {
      runDateTimeExtendedTests();
    });

    group('Custom Serialization', () {
      runCustomSerializationTests();
    });

    group('Auto Generation', () {
      runAutoGenerationTests();
    });
  });
}
