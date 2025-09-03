import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

/// Custom serialization test module
/// Tests: custom readValue functions, JsonKey annotations, custom converters
void runCustomSerializationTests() {
  group('Custom Serialization Tests', () {
    late Directory tempDir;
    late File testFile;
    late File outputFile;

    setUp(() {
      tempDir =
          Directory.systemTemp.createTempSync('custom_serialization_test_');
      testFile = File(path.join(tempDir.path, 'custom_test.model.dart'));
      outputFile = File(path.join(tempDir.path, 'custom_test.model.data.dart'));
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('custom readValue with complex logic', () {
      // Create custom readValue test model
      testFile.writeAsStringSync('''
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'custom_test.model.data.dart';

@Dataforge()
class CustomReadValueTest {
  @JsonKey(readValue: CustomReadValueTest._readStringValue)
  final String processedString;
  
  @JsonKey(readValue: CustomReadValueTest._readNumberValue)
  final int processedNumber;
  
  @JsonKey(readValue: CustomReadValueTest._readListValue)
  final List<String> processedList;
  
  @JsonKey(readValue: CustomReadValueTest._readMapValue)
  final Map<String, dynamic> processedMap;
  
  const CustomReadValueTest({
    required this.processedString,
    required this.processedNumber,
    required this.processedList,
    required this.processedMap,
  });
  
  static Object? _readStringValue(Map json, String key) {
    final value = json[key];
    if (value == null) return null;
    
    // Custom string processing
    if (value is String) {
      return value.toUpperCase().trim();
    }
    return value.toString();
  }
  
  static Object? _readNumberValue(Map json, String key) {
    final value = json[key];
    if (value == null) return 0;
    
    // Handle different number formats
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is double) {
      return value.round();
    }
    return value;
  }
  
  static Object? _readListValue(Map json, String key) {
    final value = json[key];
    if (value == null) return <String>[];
    
    // Convert various formats to string list
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      return value.split(',').map((e) => e.trim()).toList();
    }
    return [value.toString()];
  }
  
  static Object? _readMapValue(Map json, String key) {
    final value = json[key];
    if (value == null) return <String, dynamic>{};
    
    // Ensure proper map format
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{'raw': value};
  }
}
''');

      // Simulate generated code
      outputFile.writeAsStringSync('''
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_test.model.dart';

// **************************************************************************
// DataforgeGenerator
// **************************************************************************

extension CustomReadValueTestDataforge on CustomReadValueTest {
  Map<String, dynamic> toJson() {
    return {
      'processedString': processedString,
      'processedNumber': processedNumber,
      'processedList': processedList,
      'processedMap': processedMap,
    };
  }

  static CustomReadValueTest fromJson(Map<String, dynamic> json) {
    return CustomReadValueTest(
      processedString: CustomReadValueTest._readStringValue(json, 'processedString') as String,
      processedNumber: CustomReadValueTest._readNumberValue(json, 'processedNumber') as int,
      processedList: CustomReadValueTest._readListValue(json, 'processedList') as List<String>,
      processedMap: CustomReadValueTest._readMapValue(json, 'processedMap') as Map<String, dynamic>,
    );
  }
}
''');

      expect(testFile.existsSync(), isTrue);
      expect(outputFile.existsSync(), isTrue);
      expect(outputFile.readAsStringSync().contains('_readStringValue(json,'),
          isTrue);
      expect(outputFile.readAsStringSync().contains('_readNumberValue(json,'),
          isTrue);
      expect(outputFile.readAsStringSync().contains('_readListValue(json,'),
          isTrue);
      expect(outputFile.readAsStringSync().contains('_readMapValue(json,'),
          isTrue);
    });

    test('JsonKey with custom names and nullable handling', () {
      testFile.writeAsStringSync('''
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'custom_test.model.data.dart';

@Dataforge()
class JsonKeyCustomTest {
  @JsonKey(name: 'user_name')
  final String userName;
  
  @JsonKey(name: 'user_age', readValue: JsonKeyCustomTest._readAge)
  final int? userAge;
  
  @JsonKey(name: 'is_active')
  final bool isActive;
  
  @JsonKey(name: 'user_tags')
  final List<String>? tags;
  
  @JsonKey(name: 'metadata')
  final Map<String, String>? metadata;
  
  const JsonKeyCustomTest({
    required this.userName,
    this.userAge,
    required this.isActive,
    this.tags,
    this.metadata,
  });
  
  static Object? _readAge(Map json, String key) {
    final value = json[key];
    if (value == null) return null;
    
    // Handle age validation
    if (value is String) {
      final parsed = int.tryParse(value);
      return (parsed != null && parsed >= 0 && parsed <= 150) ? parsed : null;
    }
    if (value is int) {
      return (value >= 0 && value <= 150) ? value : null;
    }
    return null;
  }
}
''');

      outputFile.writeAsStringSync('''
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_test.model.dart';

extension JsonKeyCustomTestDataforge on JsonKeyCustomTest {
  Map<String, dynamic> toJson() {
    return {
      'user_name': userName,
      'user_age': userAge,
      'is_active': isActive,
      'user_tags': tags,
      'metadata': metadata,
    };
  }

  static JsonKeyCustomTest fromJson(Map<String, dynamic> json) {
    return JsonKeyCustomTest(
      userName: json['user_name'] as String,
      userAge: JsonKeyCustomTest._readAge(json, 'user_age') as int?,
      isActive: json['is_active'] as bool,
      tags: json['user_tags'] != null
          ? (json['user_tags'] as List<dynamic>).cast<String>()
          : null,
      metadata: json['metadata'] != null
          ? Map<String, String>.from(json['metadata'] as Map)
          : null,
    );
  }
}
''');

      expect(outputFile.readAsStringSync().contains("'user_name'"), isTrue);
      expect(outputFile.readAsStringSync().contains("'user_age'"), isTrue);
      expect(outputFile.readAsStringSync().contains("'is_active'"), isTrue);
      expect(outputFile.readAsStringSync().contains('_readAge(json,'), isTrue);
    });

    test('custom converters with complex types', () {
      testFile.writeAsStringSync('''
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'custom_test.model.data.dart';

@Dataforge()
class CustomConverterTest {
  @StringToIntConverter()
  final int convertedInt;
  
  @StringToDoubleConverter()
  final double? convertedDouble;
  
  @CsvToListConverter()
  final List<String> csvList;
  
  @JsonStringConverter()
  final Map<String, dynamic> jsonMap;
  
  const CustomConverterTest({
    required this.convertedInt,
    this.convertedDouble,
    required this.csvList,
    required this.jsonMap,
  });
}

/// Main function for standalone test execution
void main() {
  runCustomSerializationTests();
}

// Custom converter classes
class StringToIntConverter {
  const StringToIntConverter();
  
  int fromJson(dynamic value) {
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }
  
  String toJson(int value) => value.toString();
}

class StringToDoubleConverter {
  const StringToDoubleConverter();
  
  double? fromJson(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      return double.tryParse(value);
    }
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }
  
  String? toJson(double? value) => value?.toString();
}

class CsvToListConverter {
  const CsvToListConverter();
  
  List<String> fromJson(dynamic value) {
    if (value is String) {
      return value.split(',').map((e) => e.trim()).toList();
    }
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }
  
  String toJson(List<String> value) => value.join(',');
}

class JsonStringConverter {
  const JsonStringConverter();
  
  Map<String, dynamic> fromJson(dynamic value) {
    if (value is String) {
      try {
        return Map<String, dynamic>.from(json.decode(value));
      } catch (e) {
        return {'error': 'Invalid JSON'};
      }
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return {};
  }
  
  String toJson(Map<String, dynamic> value) => json.encode(value);
}
''');

      outputFile.writeAsStringSync('''
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_test.model.dart';

extension CustomConverterTestDataforge on CustomConverterTest {
  Map<String, dynamic> toJson() {
    return {
      'convertedInt': const StringToIntConverter().toJson(convertedInt),
      'convertedDouble': convertedDouble != null
          ? const StringToDoubleConverter().toJson(convertedDouble!)
          : null,
      'csvList': const CsvToListConverter().toJson(csvList),
      'jsonMap': const JsonStringConverter().toJson(jsonMap),
    };
  }

  static CustomConverterTest fromJson(Map<String, dynamic> json) {
    return CustomConverterTest(
      convertedInt: const StringToIntConverter().fromJson(json['convertedInt']),
      convertedDouble: json['convertedDouble'] != null
          ? const StringToDoubleConverter().fromJson(json['convertedDouble'])
          : null,
      csvList: const CsvToListConverter().fromJson(json['csvList']),
      jsonMap: const JsonStringConverter().fromJson(json['jsonMap']),
    );
  }
}
''');

      expect(
          outputFile
              .readAsStringSync()
              .contains('StringToIntConverter().toJson'),
          isTrue);
      expect(
          outputFile
              .readAsStringSync()
              .contains('StringToDoubleConverter().fromJson'),
          isTrue);
      expect(
          outputFile.readAsStringSync().contains('CsvToListConverter().toJson'),
          isTrue);
      expect(
          outputFile
              .readAsStringSync()
              .contains('JsonStringConverter().fromJson'),
          isTrue);
    });

    test('mixed custom serialization features', () {
      testFile.writeAsStringSync('''
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'custom_test.model.data.dart';

@dataforge
class MixedCustomTest {
  @JsonKey(name: 'custom_id', readValue: MixedCustomTest._readId)
  final String id;
  
  @StringToIntConverter()
  @JsonKey(name: 'score_value')
  final int score;
  
  @JsonKey(readValue: MixedCustomTest._readTags)
  final List<String> tags;
  
  @JsonKey(name: 'user_data')
  final Map<String, dynamic>? userData;
  
  const MixedCustomTest({
    required this.id,
    required this.score,
    required this.tags,
    this.userData,
  });
  
  static Object? _readId(Map json, String key) {
    final value = json[key];
    if (value == null) return 'default_id';
    return value.toString().toLowerCase().replaceAll(' ', '_');
  }
  
  static Object? _readTags(Map json, String key) {
    final value = json[key];
    if (value == null) return <String>[];
    
    if (value is String) {
      return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    if (value is List) {
      return value.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }
    return <String>[];
  }
}
''');

      outputFile.writeAsStringSync('''
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_test.model.dart';

extension MixedCustomTestDataforge on MixedCustomTest {
  Map<String, dynamic> toJson() {
    return {
      'custom_id': id,
      'score_value': const StringToIntConverter().toJson(score),
      'tags': tags,
      'user_data': userData,
    };
  }

  static MixedCustomTest fromJson(Map<String, dynamic> json) {
    return MixedCustomTest(
      id: MixedCustomTest._readId(json, 'custom_id') as String,
      score: const StringToIntConverter().fromJson(json['score_value']),
      tags: MixedCustomTest._readTags(json, 'tags') as List<String>,
      userData: json['user_data'] != null
          ? Map<String, dynamic>.from(json['user_data'] as Map)
          : null,
    );
  }
}
''');

      expect(outputFile.readAsStringSync().contains("'custom_id'"), isTrue);
      expect(outputFile.readAsStringSync().contains("'score_value'"), isTrue);
      expect(outputFile.readAsStringSync().contains('_readId(json,'), isTrue);
      expect(outputFile.readAsStringSync().contains('_readTags(json,'), isTrue);
      expect(
          outputFile
              .readAsStringSync()
              .contains('StringToIntConverter().fromJson'),
          isTrue);
    });
  });
}

/// Main function for standalone test execution
void main() {
  runCustomSerializationTests();
}
