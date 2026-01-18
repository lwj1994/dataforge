import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:collection/collection.dart';

part 'map_types.model.data.dart';

@Dataforge()
class MapTypes with _MapTypes {
  @override
  final Map<String, String> stringMap;
  @override
  final Map<String, int> intMap;
  @override
  final Map<String, double> doubleMap;
  @override
  final Map<String, bool> boolMap;
  @override
  final Map<String, dynamic> dynamicMap;
  @override
  final Map<String, String>? optionalStringMap;
  @override
  final Map<String, List<String>> listMap;
  @override
  final Map<String, Map<String, String>> nestedMap;
  @override
  @JsonKey(name: 'str_map')
  final Map<String, String> namedMap;
  @override
  @JsonKey(readValue: MapTypes._readValue)
  final Map<String, String>? parsedMap;
  @override
  @JsonKey(readValue: MapTypes._readValue)
  final Map<String, int> customIntMap;
  @override
  @JsonKey(readValue: MapTypes._readValue)
  final Map<String, Map<String, dynamic>>? complexMap;
  @override
  final List<Map<String, String>> mapList;
  @override
  final Map<int, String>? intKeyMap;

  const MapTypes({
    required this.stringMap,
    required this.intMap,
    required this.doubleMap,
    required this.boolMap,
    required this.dynamicMap,
    this.optionalStringMap,
    required this.listMap,
    required this.nestedMap,
    required this.namedMap,
    this.parsedMap,
    required this.customIntMap,
    this.complexMap,
    required this.mapList,
    this.intKeyMap,
  });

  factory MapTypes.fromJson(Map<String, dynamic> json) {
    return _MapTypes.fromJson(json);
  }

  static Object? _readValue(Map<dynamic, dynamic> map, String key) {
    final value = map[key];

    switch (key) {
      case 'parsedMap':
        if (value == null) return null;
        if (value is Map) {
          return Map<String, String>.from(
              value.map((k, v) => MapEntry(k.toString(), v.toString())));
        }
        if (value is String) {
          // Parse from string format: "key1:value1,key2:value2"
          final result = <String, String>{};
          final pairs = value.split(',');
          for (final pair in pairs) {
            final parts = pair.split(':');
            if (parts.length == 2) {
              result[parts[0].trim()] = parts[1].trim();
            }
          }
          return result;
        }
        return null;

      case 'customIntMap':
        if (value == null) return <String, int>{};
        if (value is Map) {
          final result = <String, int>{};
          value.forEach((k, v) {
            final intValue = int.tryParse(v.toString()) ?? 0;
            result[k.toString()] = intValue;
          });
          return result;
        }
        if (value is String) {
          // Parse from string format: "key1:123,key2:456"
          final result = <String, int>{};
          final pairs = value.split(',');
          for (final pair in pairs) {
            final parts = pair.split(':');
            if (parts.length == 2) {
              final intValue = int.tryParse(parts[1].trim()) ?? 0;
              result[parts[0].trim()] = intValue;
            }
          }
          return result;
        }
        return <String, int>{};

      case 'complexMap':
        if (value == null) return null;
        if (value is Map) {
          final result = <String, Map<String, dynamic>>{};
          value.forEach((k, v) {
            if (v is Map) {
              result[k.toString()] = Map<String, dynamic>.from(v);
            } else {
              result[k.toString()] = {'value': v};
            }
          });
          return result;
        }
        return null;

      default:
        return null;
    }
  }
}

@Dataforge()
class MapWithObjects with _MapWithObjects {
  @override
  final Map<String, Address> addressMap;
  @override
  final Map<String, List<Contact>> contactListMap;
  @override
  final Map<String, Address>? optionalAddressMap;
  @override
  @JsonKey(readValue: MapWithObjects._readValue)
  final Map<String, Address>? parsedAddressMap;

  const MapWithObjects({
    required this.addressMap,
    required this.contactListMap,
    this.optionalAddressMap,
    this.parsedAddressMap,
  });

  factory MapWithObjects.fromJson(Map<String, dynamic> json) {
    return _MapWithObjects.fromJson(json);
  }

  static Object? _readValue(Map<dynamic, dynamic> map, String key) {
    final value = map[key];

    switch (key) {
      case 'parsedAddressMap':
        if (value == null) return null;
        if (value is Map) {
          final result = <String, Address>{};
          value.forEach((k, v) {
            if (v is Map<String, dynamic>) {
              result[k.toString()] = Address.fromJson(v);
            }
          });
          return result;
        }
        return null;

      default:
        return null;
    }
  }
}

@Dataforge()
class Address with _Address {
  @override
  final String street;
  @override
  final String city;
  @override
  final String zipCode;

  const Address({
    required this.street,
    required this.city,
    required this.zipCode,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return _Address.fromJson(json);
  }
}

@Dataforge()
class Contact with _Contact {
  @override
  final String email;
  @override
  final String? phone;

  const Contact({
    required this.email,
    this.phone,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return _Contact.fromJson(json);
  }
}
