import 'package:test/test.dart';
import 'models/alternate_names_test.model.dart';

void main() {
  group('AlternateNames Tests', () {
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
        'age': 30, // using first alternate name instead of 'user_age'
        'email_address': 'jane@example.com', // using first alternate name
        'active': false, // using first alternate name instead of 'is_active'
        'tags_list': <String>['designer', 'ui'] // using first alternate name
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
        'years': 35, // using second alternate name
        'mail': 'bob@example.com', // using second alternate name
        'enabled': true, // using second alternate name
        'labels': <String>[
          'manager',
          'team-lead'
        ] // using second alternate name
      };

      final result = AlternateNamesTest.fromJson(json);

      expect(result.name, equals('Bob Wilson'));
      expect(result.age, equals(35));
      expect(result.email, equals('bob@example.com'));
      expect(result.isActive, equals(true));
      expect(result.tags, equals(['manager', 'team-lead']));
    });

    test('should use third alternate name when others are missing', () {
      final json = {
        'name': 'Alice Brown',
        'years': 28,
        'e_mail': 'alice@example.com', // using third alternate name
        'enabled': false,
        'labels': <String>['analyst']
      };

      final result = AlternateNamesTest.fromJson(json);

      expect(result.name, equals('Alice Brown'));
      expect(result.age, equals(28));
      expect(result.email, equals('alice@example.com'));
      expect(result.isActive, equals(false));
      expect(result.tags, equals(['analyst']));
    });

    test('should prioritize primary field over alternate names', () {
      final json = {
        'name': 'Charlie Davis',
        'user_age': 40, // primary field
        'age': 35, // alternate name - should be ignored
        'years': 30, // alternate name - should be ignored
        'email': 'charlie@example.com', // primary field
        'email_address': 'old@example.com', // alternate - should be ignored
        'is_active': true, // primary field
        'active': false, // alternate - should be ignored
        'tags': <String>['senior'], // primary field
        'tags_list': <String>['junior'] // alternate - should be ignored
      };

      final result = AlternateNamesTest.fromJson(json);

      expect(result.name, equals('Charlie Davis'));
      expect(result.age, equals(40)); // should use primary 'user_age'
      expect(result.email,
          equals('charlie@example.com')); // should use primary 'email'
      expect(result.isActive, equals(true)); // should use primary 'is_active'
      expect(result.tags, equals(['senior'])); // should use primary 'tags'
    });

    test('should use default values when all field names are missing', () {
      final json = {
        'name': 'David Lee',
        // missing all age fields - should use default 0
        // missing all email fields - should use default ""
        // missing all isActive fields - should use default false
        // missing all tags fields - should use default []
      };

      final result = AlternateNamesTest.fromJson(json);

      expect(result.name, equals('David Lee'));
      expect(result.age, equals(0));
      expect(result.email, equals(''));
      expect(result.isActive, equals(false));
      expect(result.tags, equals([]));
    });

    test('toJson should use primary field names', () {
      final instance = AlternateNamesTest(
        name: 'Test User',
        age: 25,
        email: 'test@example.com',
        isActive: true,
        tags: ['test'],
      );

      final json = instance.toJson();

      expect(json['name'], equals('Test User'));
      expect(json['user_age'], equals(25)); // should use primary name
      expect(json['email'], equals('test@example.com'));
      expect(json['is_active'], equals(true)); // should use primary name
      expect(json['tags'], equals(['test']));

      // Should not contain alternate names
      expect(json.containsKey('age'), isFalse);
      expect(json.containsKey('years'), isFalse);
      expect(json.containsKey('email_address'), isFalse);
      expect(json.containsKey('active'), isFalse);
      expect(json.containsKey('enabled'), isFalse);
      expect(json.containsKey('tags_list'), isFalse);
      expect(json.containsKey('labels'), isFalse);
    });
  });
}
