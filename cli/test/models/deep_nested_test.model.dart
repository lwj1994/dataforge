import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:collection/collection.dart';

part 'deep_nested_test.model.data.dart';

/// Employee class - Level 4 (deepest)
@Dataforge(chainedCopyWith: true)
class Employee with _Employee {
  @override
  final String name;
  @override
  final int id;
  @override
  final String position;

  const Employee({
    required this.name,
    required this.id,
    required this.position,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return _Employee.fromJson(json);
  }
}

/// Team class - Level 3
@Dataforge(chainedCopyWith: true)
class Team with _Team {
  @override
  final String name;
  @override
  final Employee leader;
  @override
  final List<Employee> members;

  const Team({
    required this.name,
    required this.leader,
    required this.members,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return _Team.fromJson(json);
  }
}

/// Department class - Level 2
@Dataforge(chainedCopyWith: true)
class Department with _Department {
  @override
  final String name;
  @override
  final String code;
  @override
  final List<Team> teams;

  const Department({
    required this.name,
    required this.code,
    required this.teams,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return _Department.fromJson(json);
  }
}

/// Company class - Level 1 (top level)
@Dataforge(chainedCopyWith: true)
class Company with _Company {
  @override
  final String name;
  @override
  final String address;
  @override
  final List<Department> departments;

  const Company({
    required this.name,
    required this.address,
    required this.departments,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return _Company.fromJson(json);
  }
}
