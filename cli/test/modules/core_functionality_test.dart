import 'package:test/test.dart';
import '../models/alternate_names_test.model.dart';
import '../models/backward_compatibility_test.model.dart';
import '../models/default_values.model.dart';

/// 核心功能测试模块
/// 包含：字段别名、向后兼容性、默认值等基础功能测试
void runCoreFunctionalityTests() {
  group('Core Functionality Tests', () {
    group('Alternate Names', () {
      test('should use primary field names when available', () {
        final json = {
          'name': 'John Doe',
          'user_age': 25,
          'email': 'john@example.com',
          'is_active': true,
          'tags': <String>['developer', 'flutter']
        };

        final result = AlternateNamesTest.fromJson(json);

        expect(result.name, equals('John Doe'));
        expect(result.age, equals(25));
        expect(result.email, equals('john@example.com'));
        expect(result.isActive, equals(true));
        expect(result.tags, equals(['developer', 'flutter']));
      });

      test('should use first alternate name when primary field is missing', () {
        final json = {
          'name': 'Jane Smith',
          'age': 30,
          'email_address': 'jane@example.com',
          'active': false,
          'tags_list': <String>['designer', 'ui']
        };

        final result = AlternateNamesTest.fromJson(json);

        expect(result.name, equals('Jane Smith'));
        expect(result.age, equals(30));
        expect(result.email, equals('jane@example.com'));
        expect(result.isActive, equals(false));
        expect(result.tags, equals(['designer', 'ui']));
      });

      test('should use second alternate name when first is also missing', () {
        final json = {
          'name': 'Bob Wilson',
          'years': 35,
          'mail': 'bob@example.com',
          'enabled': true,
          'labels': <String>['manager', 'team-lead']
        };

        final result = AlternateNamesTest.fromJson(json);

        expect(result.name, equals('Bob Wilson'));
        expect(result.age, equals(35));
        expect(result.email, equals('bob@example.com'));
        expect(result.isActive, equals(true));
        expect(result.tags, equals(['manager', 'team-lead']));
      });
    });

    group('Backward Compatibility', () {
      test('Dataforge annotation should work', () {
        final user = UserDataforge(
          name: 'John Doe',
          age: 30,
          email: 'john@example.com',
        );

        expect(user.name, 'John Doe');
        expect(user.age, 30);
        expect(user.email, 'john@example.com');

        final json = user.toJson();
        expect(json['name'], 'John Doe');
        expect(json['age'], 30);
        expect(json['email'], 'john@example.com');

        final userFromJson = UserDataforge.fromJson(json);
        expect(userFromJson.name, 'John Doe');
        expect(userFromJson.age, 30);
        expect(userFromJson.email, 'john@example.com');
      });

      test('DataClass annotation should still work (deprecated)', () {
        final user = UserDataClass(
          name: 'Jane Doe',
          age: 25,
          email: 'jane@example.com',
        );

        expect(user.name, 'Jane Doe');
        expect(user.age, 25);
        expect(user.email, 'jane@example.com');

        final json = user.toJson();
        expect(json['name'], 'Jane Doe');
        expect(json['age'], 25);
        expect(json['email'], 'jane@example.com');

        final userFromJson = UserDataClass.fromJson(json);
        expect(userFromJson.name, 'Jane Doe');
        expect(userFromJson.age, 25);
        expect(userFromJson.email, 'jane@example.com');
      });
    });

    group('Default Values', () {
      test('should use default values when fields are missing from JSON', () {
        final json = {
          'stringValue': 'Test String',
        };

        final result = DefaultValues.fromJson(json);

        expect(result.stringValue, equals('Test String'));
        expect(result.intValue, equals(42)); // default value
        expect(result.boolValue, equals(true)); // default value
        expect(result.listValue, equals(['default'])); // default value
        expect(result.doubleValue, equals(3.14)); // default value
      });

      test('should override default values when provided in JSON', () {
        final json = {
          'stringValue': 'Custom String',
          'intValue': 25,
          'boolValue': false,
          'listValue': ['custom', 'tags'],
          'doubleValue': 95.5,
        };

        final result = DefaultValues.fromJson(json);

        expect(result.stringValue, equals('Custom String'));
        expect(result.intValue, equals(25));
        expect(result.boolValue, equals(false));
        expect(result.listValue, equals(['custom', 'tags']));
        expect(result.doubleValue, equals(95.5));
      });
    });
  });
}

/// Main function for standalone test execution
void main() {
  runCoreFunctionalityTests();
}
