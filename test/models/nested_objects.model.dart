import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:collection/collection.dart';

part 'nested_objects.model.data.dart';

@Dataforge()
class Address with _Address {
  @override
  final String street;
  @override
  final String city;
  @override
  final String? state;
  @override
  final String zipCode;
  @override
  final String country;
  @override
  @JsonKey(name: 'is_primary')
  final bool isPrimary;

  const Address({
    required this.street,
    required this.city,
    this.state,
    required this.zipCode,
    required this.country,
    required this.isPrimary,
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
  @override
  @JsonKey(name: 'contact_type')
  final String contactType;

  const Contact({
    required this.email,
    this.phone,
    required this.contactType,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return _Contact.fromJson(json);
  }
}

@Dataforge()
class Company with _Company {
  @override
  final String name;
  @override
  final Address headquarters;
  @override
  final List<Address>? branches;
  @override
  final Contact primaryContact;
  @override
  final List<Contact>? additionalContacts;

  const Company({
    required this.name,
    required this.headquarters,
    this.branches,
    required this.primaryContact,
    this.additionalContacts,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return _Company.fromJson(json);
  }
}

@Dataforge()
class NestedObjects with _NestedObjects {
  @override
  final String name;
  @override
  final Address homeAddress;
  @override
  final Address? workAddress;
  @override
  final List<Address> previousAddresses;
  @override
  final Map<String, Address>? namedAddresses;
  @override
  final Contact primaryContact;
  @override
  final List<Contact>? contacts;
  @override
  final Company? employer;
  @override
  final Address? customAddress;
  @override
  @JsonKey(readValue: NestedObjects._readValue)
  final List<Contact>? parsedContacts;

  const NestedObjects({
    required this.name,
    required this.homeAddress,
    this.workAddress,
    required this.previousAddresses,
    this.namedAddresses,
    required this.primaryContact,
    this.contacts,
    this.employer,
    this.customAddress,
    this.parsedContacts,
  });

  factory NestedObjects.fromJson(Map<String, dynamic> json) {
    return _NestedObjects.fromJson(json);
  }

  static Object? _readValue(Map<dynamic, dynamic> map, String key) {
    final value = map[key];

    switch (key) {
      case 'customAddress':
        if (value == null) return null;
        if (value is Map<String, dynamic>) {
          return value; // Return Map, let generated code handle conversion
        }
        if (value is String) {
          // Parse address from string format: "street,city,zipCode,country"
          final parts = value.split(',');
          if (parts.length >= 4) {
            return {
              'street': parts[0].trim(),
              'city': parts[1].trim(),
              'zipCode': parts[2].trim(),
              'country': parts[3].trim(),
              'is_primary': false,
            };
          }
        }
        return value; // Return the original value for other types

      case 'parsedContacts':
        if (value == null) return null;
        if (value is List) {
          return value.whereType<Map<String, dynamic>>().toList();
        }
        if (value is String) {
          // Parse contacts from string format: "email1:phone1;email2:phone2"
          final contactStrings = value.split(';');
          return contactStrings.map((contactStr) {
            final parts = contactStr.split(':');
            return {
              'email': parts[0].trim(),
              'phone': parts.length > 1 ? parts[1].trim() : null,
              'contact_type': 'parsed',
            };
          }).toList();
        }
        return null;

      default:
        return null;
    }
  }
}
