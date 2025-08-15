import 'dart:io';
import 'dart:convert';
import 'package:data_class_annotation/data_class_annotation.dart';

class ConfigLoader {
  static GlobalConfig loadFromFile(String path) {
    final file = File(path);
    if (!file.existsSync()) return GlobalConfig();

    final content = file.readAsStringSync();
    final json = jsonDecode(content) as Map<String, dynamic>;

    return GlobalConfig(
      includeFromJson:
          json['includeFromJson'] ?? json['includeFromMap'] ?? true,
      includeToJson: json['includeToJson'] ?? json['includeToMap'] ?? true,
    );
  }
}
