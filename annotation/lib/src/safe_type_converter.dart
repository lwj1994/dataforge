/// 安全类型转换工具类
/// 解决 Dart 泛型在运行时无法直接通过 T == type 判断的问题
class SafeCasteUtil {
  /// 核心方法：将 dynamic 转换为指定的 T 类型
  static T? safeCast<T>(dynamic value) {
    if (value == null) return null;

    // 1. 快速匹配：如果类型已经符合，直接返回
    if (value is T) return value;

    try {
      // 2. Map 转换: 确保返回 Map<String, dynamic>
      if (value is Map && <Map<String, dynamic>>[] is List<T>) {
        return value.cast<String, dynamic>() as T;
      }

      // 3. 基础列表转换: 支持 List<String>, List<int>, List<double>
      if (value is List) {
        if (<List<String>>[] is List<T>) {
          return value.map((e) => e.toString()).toList() as T;
        }
        if (<List<int>>[] is List<T>) {
          return value.map((e) => safeCast<int>(e)).whereType<int>().toList()
              as T;
        }
        if (<List<double>>[] is List<T>) {
          return value
              .map((e) => safeCast<double>(e))
              .whereType<double>()
              .toList() as T;
        }
      }

      // 4. String 转换
      if (<String>[] is List<T>) {
        if (value is Map || value is List) return null; // 过滤无意义的结构体转字符串
        return value.toString() as T;
      }

      // 5. int 转换
      if (<int>[] is List<T>) {
        if (value is num) return value.toInt() as T;
        if (value is String) return int.tryParse(value) as T?;
      }

      // 6. double 转换
      if (<double>[] is List<T>) {
        if (value is num) return value.toDouble() as T;
        if (value is String) return double.tryParse(value) as T?;
      }

      // 7. bool 转换 (兼容 1/0, "true"/"false", "yes"/"no")
      if (<bool>[] is List<T>) {
        if (value is bool) return value as T;
        if (value is String) {
          final lower = value.toLowerCase();
          if (['true', '1', 'yes', 'y'].contains(lower)) return true as T;
          if (['false', '0', 'no', 'n'].contains(lower)) return false as T;
        }
        if (value is num) return (value != 0) as T;
      }

      return null;
    } catch (e) {
      // 开发环境下建议打印错误，生产环境保持静默
      return null;
    }
  }

  // --- Map 读取相关方法 ---

  /// 从 Map 中读取可选值
  static T? readValue<T>(Map<String, dynamic>? map, String key) {
    if (map == null || !map.containsKey(key)) return null;
    return safeCast<T>(map[key]);
  }

  /// 从 Map 中读取必填值，转换失败或缺失则抛出异常
  static T readRequiredValue<T>(Map<String, dynamic> map, String key) {
    final value = safeCast<T>(map[key]);
    if (value == null) {
      throw ArgumentError(
          'Key "$key" is required and must be of type $T. Found: ${map[key]}');
    }
    return value;
  }

  static T readRequiredObject<T>(
    Map<String, dynamic>? map,
    String key,
    T Function(Map<String, dynamic>) factory,
  ) {
    final res = readObject(map, key, factory);
    if (res == null)
      throw Exception("Key \"$key\" is required and must be of type $T.");
    return res;
  }

  // --- 对象解析相关方法 ---

  /// 解析嵌套对象
  static T? readObject<T>(
    Map<String, dynamic>? map,
    String key,
    T Function(Map<String, dynamic>) factory,
  ) {
    final data = readValue<Map<String, dynamic>>(map, key);
    if (data == null) return null;
    return factory(data);
  }

  /// 解析对象列表
  static List<T>? readObjectList<T>(
    Map<String, dynamic>? map,
    String key,
    T Function(Map<String, dynamic>) factory,
  ) {
    final list = readValue<List>(map, key);
    if (list == null) return null;
    return list
        .map((e) => safeCast<Map<String, dynamic>>(e))
        .where((e) => e != null)
        .map((e) => factory(e!))
        .toList();
  }
}
