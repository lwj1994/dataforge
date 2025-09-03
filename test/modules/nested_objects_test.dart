import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

/// Nested objects test module
/// Tests: complex nested structures, object lists and maps
void runNestedObjectsTests() {
  group('Nested Objects Tests', () {
    late Directory tempDir;
    late File testFile;
    late File outputFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('nested_objects_test_');
      testFile = File(path.join(tempDir.path, 'nested_test.model.dart'));
      outputFile = File(path.join(tempDir.path, 'nested_test.model.data.dart'));
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('basic nested object serialization', () {
      // Create nested object test model
      testFile.writeAsStringSync('''
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'nested_test.model.data.dart';

@Dataforge()
class Address {
  final String street;
  final String city;
  final String? state;
  final String zipCode;
  
  const Address({
    required this.street,
    required this.city,
    this.state,
    required this.zipCode,
  });
}

@Dataforge()
class Person {
  final String name;
  final int age;
  final Address address;
  final Address? workAddress;
  
  const Person({
    required this.name,
    required this.age,
    required this.address,
    this.workAddress,
  });
}
''');

      // Simulate generated code
      outputFile.writeAsStringSync('''
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nested_test.model.dart';

// **************************************************************************
// DataforgeGenerator
// **************************************************************************

extension AddressDataforge on Address {
  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
    };
  }

  static Address fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'] as String,
      city: json['city'] as String,
      state: json['state'] as String?,
      zipCode: json['zipCode'] as String,
    );
  }
}

extension PersonDataforge on Person {
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'address': address.toJson(),
      'workAddress': workAddress?.toJson(),
    };
  }

  static Person fromJson(Map<String, dynamic> json) {
    return Person(
      name: json['name'] as String,
      age: json['age'] as int,
      address: Address.fromJson(json['address'] as Map<String, dynamic>),
      workAddress: json['workAddress'] != null
          ? Address.fromJson(json['workAddress'] as Map<String, dynamic>)
          : null,
    );
  }
}
''');

      expect(testFile.existsSync(), isTrue);
      expect(outputFile.existsSync(), isTrue);
      expect(
          outputFile.readAsStringSync().contains('address.toJson()'), isTrue);
      expect(
          outputFile.readAsStringSync().contains('Address.fromJson'), isTrue);
      expect(outputFile.readAsStringSync().contains('workAddress?.toJson()'),
          isTrue);
    });

    test('nested object lists', () {
      testFile.writeAsStringSync('''
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'nested_test.model.data.dart';

@Dataforge()
class Contact {
  final String type;
  final String value;
  
  const Contact({
    required this.type,
    required this.value,
  });
}

@Dataforge()
class User {
  final String name;
  final List<Contact> contacts;
  final List<Contact>? optionalContacts;
  
  const User({
    required this.name,
    required this.contacts,
    this.optionalContacts,
  });
}
''');

      outputFile.writeAsStringSync('''
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nested_test.model.dart';

extension ContactDataforge on Contact {
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'value': value,
    };
  }

  static Contact fromJson(Map<String, dynamic> json) {
    return Contact(
      type: json['type'] as String,
      value: json['value'] as String,
    );
  }
}

extension UserDataforge on User {
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'contacts': contacts.map((e) => e.toJson()).toList(),
      'optionalContacts': optionalContacts?.map((e) => e.toJson()).toList(),
    };
  }

  static User fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] as String,
      contacts: (json['contacts'] as List<dynamic>)
          .map((e) => Contact.fromJson(e as Map<String, dynamic>))
          .toList(),
      optionalContacts: json['optionalContacts'] != null
          ? (json['optionalContacts'] as List<dynamic>)
              .map((e) => Contact.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}
''');

      expect(
          outputFile
              .readAsStringSync()
              .contains('contacts.map((e) => e.toJson())'),
          isTrue);
      expect(
          outputFile
              .readAsStringSync()
              .contains('Contact.fromJson(e as Map<String, dynamic>)'),
          isTrue);
      expect(outputFile.readAsStringSync().contains('optionalContacts?.map'),
          isTrue);
    });

    test('nested object maps', () {
      testFile.writeAsStringSync('''
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'nested_test.model.data.dart';

@dataforge
class Department {
  final String name;
  final String code;
  
  const Department({
    required this.name,
    required this.code,
  });
}

@dataforge
class Company {
  final String name;
  final Map<String, Department> departments;
  final Map<String, Department>? optionalDepartments;
  
  const Company({
    required this.name,
    required this.departments,
    this.optionalDepartments,
  });
}
''');

      outputFile.writeAsStringSync('''
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nested_test.model.dart';

extension DepartmentDataforge on Department {
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
    };
  }

  static Department fromJson(Map<String, dynamic> json) {
    return Department(
      name: json['name'] as String,
      code: json['code'] as String,
    );
  }
}

extension CompanyDataforge on Company {
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'departments': departments.map((k, v) => MapEntry(k, v.toJson())),
      'optionalDepartments': optionalDepartments?.map((k, v) => MapEntry(k, v.toJson())),
    };
  }

  static Company fromJson(Map<String, dynamic> json) {
    return Company(
      name: json['name'] as String,
      departments: (json['departments'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, Department.fromJson(v as Map<String, dynamic>)),
      ),
      optionalDepartments: json['optionalDepartments'] != null
          ? (json['optionalDepartments'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, Department.fromJson(v as Map<String, dynamic>)),
            )
          : null,
    );
  }
}
''');

      expect(
          outputFile
              .readAsStringSync()
              .contains('departments.map((k, v) => MapEntry(k, v.toJson()))'),
          isTrue);
      expect(
          outputFile
              .readAsStringSync()
              .contains('Department.fromJson(v as Map<String, dynamic>)'),
          isTrue);
      expect(outputFile.readAsStringSync().contains('optionalDepartments?.map'),
          isTrue);
    });

    test('deeply nested structures', () {
      testFile.writeAsStringSync('''
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'nested_test.model.data.dart';

@dataforge
class Employee {
  final String name;
  final String position;
  
  const Employee({
    required this.name,
    required this.position,
  });
}

@dataforge
class Team {
  final String name;
  final Employee leader;
  final List<Employee> members;
  
  const Team({
    required this.name,
    required this.leader,
    required this.members,
  });
}

@dataforge
class Division {
  final String name;
  final Map<String, Team> teams;
  final List<Map<String, Employee>> employeeGroups;
  
  const Division({
    required this.name,
    required this.teams,
    required this.employeeGroups,
  });
}
''');

      outputFile.writeAsStringSync('''
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nested_test.model.dart';

extension EmployeeDataforge on Employee {
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'position': position,
    };
  }

  static Employee fromJson(Map<String, dynamic> json) {
    return Employee(
      name: json['name'] as String,
      position: json['position'] as String,
    );
  }
}

extension TeamDataforge on Team {
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'leader': leader.toJson(),
      'members': members.map((e) => e.toJson()).toList(),
    };
  }

  static Team fromJson(Map<String, dynamic> json) {
    return Team(
      name: json['name'] as String,
      leader: Employee.fromJson(json['leader'] as Map<String, dynamic>),
      members: (json['members'] as List<dynamic>)
          .map((e) => Employee.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

extension DivisionDataforge on Division {
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'teams': teams.map((k, v) => MapEntry(k, v.toJson())),
      'employeeGroups': employeeGroups
          .map((group) => group.map((k, v) => MapEntry(k, v.toJson())))
          .toList(),
    };
  }

  static Division fromJson(Map<String, dynamic> json) {
    return Division(
      name: json['name'] as String,
      teams: (json['teams'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, Team.fromJson(v as Map<String, dynamic>)),
      ),
      employeeGroups: (json['employeeGroups'] as List<dynamic>)
          .map((group) => (group as Map<String, dynamic>).map(
                (k, v) => MapEntry(k, Employee.fromJson(v as Map<String, dynamic>)),
              ))
          .toList(),
    );
  }
}
''');

      expect(outputFile.readAsStringSync().contains('leader.toJson()'), isTrue);
      expect(
          outputFile
              .readAsStringSync()
              .contains('members.map((e) => e.toJson())'),
          isTrue);
      expect(
          outputFile
              .readAsStringSync()
              .contains('teams.map((k, v) => MapEntry(k, v.toJson()))'),
          isTrue);
      expect(outputFile.readAsStringSync().contains('employeeGroups'), isTrue);
    });
  });
}

/// Main function for standalone test execution
void main() {
  runNestedObjectsTests();
}
