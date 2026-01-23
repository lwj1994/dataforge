// Test for circular dependency detection

import 'package:dataforge_base/dataforge_base.dart';
import 'package:test/test.dart';

void main() {
  group('CircularDependencyDetector', () {
    late CircularDependencyDetector detector;

    setUp(() {
      detector = CircularDependencyDetector();
    });

    test('detects simple circular dependency (A -> B -> A)', () {
      final classA = ClassInfo(
        name: 'User',
        mixinName: '_\$UserMixin',
        fields: [
          FieldInfo(
            name: 'favoritePost',
            type: 'Post?',
            isFinal: true,
            isFunction: false,
            isRecord: false,
            defaultValue: '',
            isDataforge: true,
          ),
        ],
      );

      final classB = ClassInfo(
        name: 'Post',
        mixinName: '_\$PostMixin',
        fields: [
          FieldInfo(
            name: 'author',
            type: 'User',
            isFinal: true,
            isFunction: false,
            isRecord: false,
            defaultValue: '',
            isDataforge: true,
          ),
        ],
      );

      detector.addClass(classA);
      detector.addClass(classB);

      final cycles = detector.detectCycles();
      expect(cycles.length, equals(1));
      expect(cycles[0], containsAll(['User', 'Post']));
    });

    test('detects self-referencing class (A -> A)', () {
      final classA = ClassInfo(
        name: 'TreeNode',
        mixinName: '_\$TreeNodeMixin',
        fields: [
          FieldInfo(
            name: 'children',
            type: 'List<TreeNode>',
            isFinal: true,
            isFunction: false,
            isRecord: false,
            defaultValue: '',
            isInnerDataforge: true,
          ),
        ],
      );

      detector.addClass(classA);

      final cycles = detector.detectCycles();
      expect(cycles.length, equals(1));
      expect(cycles[0], contains('TreeNode'));
    });

    test('detects longer cycle (A -> B -> C -> A)', () {
      final classA = ClassInfo(
        name: 'Company',
        mixinName: '_\$CompanyMixin',
        fields: [
          FieldInfo(
            name: 'employees',
            type: 'List<Employee>',
            isFinal: true,
            isFunction: false,
            isRecord: false,
            defaultValue: '',
            isInnerDataforge: true,
          ),
        ],
      );

      final classB = ClassInfo(
        name: 'Employee',
        mixinName: '_\$EmployeeMixin',
        fields: [
          FieldInfo(
            name: 'department',
            type: 'Department',
            isFinal: true,
            isFunction: false,
            isRecord: false,
            defaultValue: '',
            isDataforge: true,
          ),
        ],
      );

      final classC = ClassInfo(
        name: 'Department',
        mixinName: '_\$DepartmentMixin',
        fields: [
          FieldInfo(
            name: 'company',
            type: 'Company',
            isFinal: true,
            isFunction: false,
            isRecord: false,
            defaultValue: '',
            isDataforge: true,
          ),
        ],
      );

      detector.addClass(classA);
      detector.addClass(classB);
      detector.addClass(classC);

      final cycles = detector.detectCycles();
      expect(cycles.length, equals(1));
      expect(cycles[0], containsAll(['Company', 'Employee', 'Department']));
    });

    test('no cycles detected in acyclic graph', () {
      final classA = ClassInfo(
        name: 'User',
        mixinName: '_\$UserMixin',
        fields: [
          FieldInfo(
            name: 'name',
            type: 'String',
            isFinal: true,
            isFunction: false,
            isRecord: false,
            defaultValue: '',
          ),
        ],
      );

      final classB = ClassInfo(
        name: 'Post',
        mixinName: '_\$PostMixin',
        fields: [
          FieldInfo(
            name: 'authorId',
            type: 'String',
            isFinal: true,
            isFunction: false,
            isRecord: false,
            defaultValue: '',
          ),
        ],
      );

      detector.addClass(classA);
      detector.addClass(classB);

      final cycles = detector.detectCycles();
      expect(cycles, isEmpty);
    });

    test('ignores @JsonKey(ignore: true) fields', () {
      final classA = ClassInfo(
        name: 'User',
        mixinName: '_\$UserMixin',
        fields: [
          FieldInfo(
            name: 'favoritePost',
            type: 'Post?',
            isFinal: true,
            isFunction: false,
            isRecord: false,
            defaultValue: '',
            isDataforge: true,
            jsonKey: JsonKeyInfo(
              name: '',
              alternateNames: [],
              readValue: '',
              ignore: true, // This field is ignored
            ),
          ),
        ],
      );

      final classB = ClassInfo(
        name: 'Post',
        mixinName: '_\$PostMixin',
        fields: [
          FieldInfo(
            name: 'author',
            type: 'User',
            isFinal: true,
            isFunction: false,
            isRecord: false,
            defaultValue: '',
            isDataforge: true,
          ),
        ],
      );

      detector.addClass(classA);
      detector.addClass(classB);

      final cycles = detector.detectCycles();
      // No cycle because User.favoritePost is ignored
      expect(cycles, isEmpty);
    });

    test('formatCycleWarning produces readable output', () {
      final cycles = [
        ['User', 'Post', 'User'],
        ['Company', 'Employee', 'Department', 'Company'],
      ];

      final warning = CircularDependencyDetector.formatCycleWarning(cycles);

      expect(warning, contains('⚠️  Circular dependency detected!'));
      expect(warning, contains('Cycle 1: User → Post → User'));
      expect(warning, contains('Cycle 2: Company → Employee → Department → Company'));
      expect(warning, contains('@JsonKey(ignore: true)'));
    });
  });
}
