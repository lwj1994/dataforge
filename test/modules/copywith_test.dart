import 'package:test/test.dart';

import '../models/chained_copywith_test.model.dart';
import '../models/deep_nested_test.model.dart';
import '../models/traditional_copywith_test.model.dart' as traditional;

/// CopyWith功能测试模块
/// 包含：链式copyWith、传统copyWith、深度嵌套copyWith测试
void runCopyWithTests() {
  group('CopyWith Functionality Tests', () {
    group('Chained CopyWith', () {
      test('chained copyWith should work correctly', () {
        final user = User(
          name: 'John',
          age: 25,
          email: 'john@example.com',
        );

        // Test chained copyWith for single field
        final updatedName = user.copyWith.name('Jane').build();
        expect(updatedName.name, equals('Jane'));
        expect(updatedName.age, equals(25));
        expect(updatedName.email, equals('john@example.com'));

        // Test chained copyWith for different field
        final updatedAge = user.copyWith.age(30).build();
        expect(updatedAge.name, equals('John'));
        expect(updatedAge.age, equals(30));
        expect(updatedAge.email, equals('john@example.com'));

        // Test chained copyWith for nullable field
        final updatedEmail = user.copyWith.email('jane@example.com').build();
        expect(updatedEmail.name, equals('John'));
        expect(updatedEmail.age, equals(25));
        expect(updatedEmail.email, equals('jane@example.com'));

        // Test setting nullable field to null
        final noEmail = user.copyWith.email(null).build();
        expect(noEmail.name, equals('John'));
        expect(noEmail.age, equals(25));
        expect(noEmail.email, isNull);
      });

      test('traditional copyWith call method should work', () {
        final user = User(
          name: 'John',
          age: 25,
          email: 'john@example.com',
        );

        // Test traditional copyWith through call method
        final updated = user.copyWith(
          name: 'Jane',
          age: 30,
        );

        expect(updated.name, equals('Jane'));
        expect(updated.age, equals(30));
        expect(updated.email, equals('john@example.com')); // unchanged
      });
    });

    group('Traditional CopyWith', () {
      test('traditional copyWith should work correctly', () {
        final user = traditional.User(
          name: 'John',
          age: 25,
          email: 'john@example.com',
        );

        final updated = user.copyWith(
          name: 'Jane',
          age: 30,
        );

        expect(updated.name, equals('Jane'));
        expect(updated.age, equals(30));
        expect(updated.email, equals('john@example.com')); // unchanged
      });
    });

    group('Deep Nested CopyWith', () {
      late Company testCompany;
      late Employee employee1;
      late Employee employee2;
      late Team team1;
      late Department department1;

      setUp(() {
        employee1 = const Employee(
          name: 'John Doe',
          id: 1,
          position: 'Developer',
        );

        employee2 = const Employee(
          name: 'Jane Smith',
          id: 2,
          position: 'Designer',
        );

        team1 = Team(
          name: 'Frontend Team',
          leader: employee1,
          members: [employee1, employee2],
        );

        department1 = Department(
          name: 'Engineering',
          code: 'ENG',
          teams: [team1],
        );

        testCompany = Company(
          name: 'Tech Corp',
          address: '123 Tech Street',
          departments: [department1],
        );
      });

      test('should support chained copyWith for Employee (Level 4)', () {
        final updatedEmployee = employee1.copyWith.name('John Updated').build();

        expect(updatedEmployee.name, equals('John Updated'));
        expect(updatedEmployee.id, equals(employee1.id));
        expect(updatedEmployee.position, equals(employee1.position));
      });

      test('should support chained copyWith for Team (Level 3)', () {
        final updatedTeam = team1.copyWith.name('Backend Team').build();

        expect(updatedTeam.name, equals('Backend Team'));
        expect(updatedTeam.leader, equals(employee1));
        expect(updatedTeam.members, equals([employee1, employee2]));
      });

      test('should support chained copyWith for Department (Level 2)', () {
        final updatedDepartment =
            department1.copyWith.name('Marketing').build();

        expect(updatedDepartment.name, equals('Marketing'));
        expect(updatedDepartment.code, equals('ENG'));
        expect(updatedDepartment.teams, equals([team1]));
      });

      test('should support chained copyWith for Company (Level 1)', () {
        final updatedCompany =
            testCompany.copyWith.name('New Tech Corp').build();

        expect(updatedCompany.name, equals('New Tech Corp'));
        expect(updatedCompany.address, equals('123 Tech Street'));
        expect(updatedCompany.departments, equals([department1]));
      });

      test('should support nested object updates', () {
        // Update employee within team within department within company
        final newEmployee = employee1.copyWith.name('John Senior').build();
        final newTeam = team1.copyWith.leader(newEmployee).build();
        final newDepartment = department1.copyWith.teams([newTeam]).build();
        final newCompany =
            testCompany.copyWith.departments([newDepartment]).build();

        expect(newCompany.departments.first.teams.first.leader.name,
            equals('John Senior'));
        expect(newCompany.name, equals('Tech Corp')); // unchanged
        expect(newCompany.address, equals('123 Tech Street')); // unchanged
      });
    });
  });
}

/// Main function for standalone test execution
void main() {
  runCopyWithTests();
}
