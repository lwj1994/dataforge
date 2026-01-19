import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'map_types.model.data.dart';

@Dataforge()
class MapTypes with _MapTypes {
  @override
  final Map<String, dynamic> dynamicMap;

  const MapTypes({
    required this.dynamicMap,
  });

  factory MapTypes.fromJson(Map<String, dynamic> json) {
    return _MapTypes.fromJson(json);
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

@Dataforge()
class MapWithObjects with _MapWithObjects {
  @override
  final Map<String, Address> addresses;
  @override
  final Map<String, Contact> contacts;

  const MapWithObjects({
    required this.addresses,
    required this.contacts,
  });

  factory MapWithObjects.fromJson(Map<String, dynamic> json) {
    return _MapWithObjects.fromJson(json);
  }
}
