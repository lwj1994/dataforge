import 'package:collection/collection.dart';

abstract class TypeHandler {
  bool canHandle(String type);
  String generateFromMapCode(String valueExpress, String defaultValue);
  String generateToMapCode(String fieldName);
}

class StringTypeHandler implements TypeHandler {
  @override
  bool canHandle(String type) => type.replaceAll('?', '') == 'String';

  @override
  String generateFromMapCode(String valueExpress, String defaultValue) {
    return "$valueExpress?.toString()$defaultValue";
  }

  @override
  String generateToMapCode(String fieldName) => fieldName;
}

class IntTypeHandler implements TypeHandler {
  @override
  bool canHandle(String type) => type.replaceAll('?', '') == 'int';

  @override
  String generateFromMapCode(String valueExpress, String defaultValue) {
    return "($valueExpress != null ? int.tryParse($valueExpress?.toString() ?? '') : null)$defaultValue";
  }

  @override
  String generateToMapCode(String fieldName) => fieldName;
}

class BoolTypeHandler implements TypeHandler {
  @override
  bool canHandle(String type) => type.replaceAll('?', '') == 'bool';

  @override
  String generateFromMapCode(String valueExpress, String defaultValue) {
    return "($valueExpress != null ? ($valueExpress as bool?) : null)$defaultValue";
  }

  @override
  String generateToMapCode(String fieldName) => fieldName;
}

class DoubleTypeHandler implements TypeHandler {
  @override
  bool canHandle(String type) => type.replaceAll('?', '') == 'double';

  @override
  String generateFromMapCode(String valueExpress, String defaultValue) {
    return "($valueExpress != null ? double.tryParse($valueExpress?.toString() ?? '') : null)$defaultValue";
  }

  @override
  String generateToMapCode(String fieldName) => fieldName;
}

class TypeHandlerRegistry {
  static final List<TypeHandler> _handlers = [
    StringTypeHandler(),
    IntTypeHandler(),
    BoolTypeHandler(),
    DoubleTypeHandler(),
  ];

  static TypeHandler? findHandler(String type) {
    return _handlers.firstWhereOrNull((h) => h.canHandle(type));
  }
}
