import 'package:test/test.dart';
import 'models/deep_nested_test.model.dart';

void main() {
  group('Deep Nested CopyWith Tests', () {
    late Company testCompany;
    late Employee employee1;
    late Employee employee2;
    late Team team1;
    late Department department1;

    setUp(() {
      // Create test data with 4 levels of nesting
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
      // Test deepest level chained copyWith
      final updatedEmployee = employee1.copyWith.name('John Updated');

      expect(updatedEmployee.name, equals('John Updated'));
      expect(updatedEmployee.id, equals(employee1.id));
      expect(updatedEmployee.position, equals(employee1.position));

      // Test multiple chained updates
      final multiUpdated = employee1.copyWith
          .name('New Name')
          .copyWith
          .position('Senior Developer');

      expect(multiUpdated.name, equals('New Name'));
      expect(multiUpdated.position, equals('Senior Developer'));
      expect(multiUpdated.id, equals(employee1.id));
    });

    test('should support chained copyWith for Team (Level 3)', () {
      // Test team level chained copyWith
      final newLeader = const Employee(
        name: 'New Leader',
        id: 99,
        position: 'Team Lead',
      );

      final updatedTeam = team1.copyWith.leader(newLeader);

      expect(updatedTeam.leader.name, equals('New Leader'));
      expect(updatedTeam.name, equals(team1.name));
      expect(updatedTeam.members.length, equals(team1.members.length));
    });

    test('should support chained copyWith for Department (Level 2)', () {
      // Test department level chained copyWith
      final updatedDepartment =
          department1.copyWith.name('Updated Engineering');

      expect(updatedDepartment.name, equals('Updated Engineering'));
      expect(updatedDepartment.code, equals(department1.code));
      expect(updatedDepartment.teams.length, equals(department1.teams.length));
    });

    test('should support chained copyWith for Company (Level 1)', () {
      // Test top level chained copyWith
      final updatedCompany = testCompany.copyWith.name('New Tech Corp');

      expect(updatedCompany.name, equals('New Tech Corp'));
      expect(updatedCompany.address, equals(testCompany.address));
      expect(updatedCompany.departments.length,
          equals(testCompany.departments.length));
    });

    test('should support traditional copyWith syntax through call method', () {
      // Test traditional copyWith compatibility at all levels
      final updatedEmployee = employee1.copyWith(
        name: 'Traditional Update',
        position: 'Senior Dev',
      );

      expect(updatedEmployee.name, equals('Traditional Update'));
      expect(updatedEmployee.position, equals('Senior Dev'));
      expect(updatedEmployee.id, equals(employee1.id));

      final updatedCompany = testCompany.copyWith(
        name: 'Traditional Corp',
        address: 'New Address',
      );

      expect(updatedCompany.name, equals('Traditional Corp'));
      expect(updatedCompany.address, equals('New Address'));
    });

    test('should handle complex nested updates', () {
      // Create a new employee for the leader position
      final newLeader = const Employee(
        name: 'Super Leader',
        id: 100,
        position: 'CTO',
      );

      // Create a new team with the new leader
      final newTeam =
          team1.copyWith.leader(newLeader).copyWith.name('Elite Team');

      // Create a new department with the updated team
      final newDepartment = department1.copyWith.teams([newTeam]);

      // Update the company with the new department
      final updatedCompany = testCompany.copyWith.departments([newDepartment]);

      // Verify the deep nested update
      expect(updatedCompany.departments[0].teams[0].leader.name,
          equals('Super Leader'));
      expect(updatedCompany.departments[0].teams[0].name, equals('Elite Team'));
      expect(updatedCompany.name,
          equals(testCompany.name)); // Original name preserved
    });

    test('should maintain immutability across all levels', () {
      // Update at each level and verify original objects are unchanged
      final updatedEmployee = employee1.copyWith.name('Changed');
      final updatedTeam = team1.copyWith.name('Changed Team');
      final updatedDepartment = department1.copyWith.name('Changed Dept');
      final updatedCompany = testCompany.copyWith.name('Changed Corp');

      // Verify originals are unchanged
      expect(employee1.name, equals('John Doe'));
      expect(team1.name, equals('Frontend Team'));
      expect(department1.name, equals('Engineering'));
      expect(testCompany.name, equals('Tech Corp'));

      // Verify updates worked
      expect(updatedEmployee.name, equals('Changed'));
      expect(updatedTeam.name, equals('Changed Team'));
      expect(updatedDepartment.name, equals('Changed Dept'));
      expect(updatedCompany.name, equals('Changed Corp'));
    });

    test('should support equality comparison across all levels', () {
      // Test equality at all nesting levels
      final sameEmployee = const Employee(
        name: 'John Doe',
        id: 1,
        position: 'Developer',
      );

      expect(employee1, equals(sameEmployee));
      expect(employee1.hashCode, equals(sameEmployee.hashCode));

      // Test inequality
      final differentEmployee = employee1.copyWith.name('Different Name');
      expect(employee1, isNot(equals(differentEmployee)));
      expect(employee1.hashCode, isNot(equals(differentEmployee.hashCode)));
    });
  });
}
