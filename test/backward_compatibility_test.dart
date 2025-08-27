import 'package:test/test.dart';
import 'models/backward_compatibility_test.model.dart';

void main() {
  group('Backward Compatibility Tests', () {
    test('Dataforge annotation should work', () {
      final user = UserDataforge(
        name: 'John Doe',
        age: 30,
        email: 'john@example.com',
      );

      expect(user.name, 'John Doe');
      expect(user.age, 30);
      expect(user.email, 'john@example.com');

      // Test toJson
      final json = user.toJson();
      expect(json['name'], 'John Doe');
      expect(json['age'], 30);
      expect(json['email'], 'john@example.com');

      // Test fromJson
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

      // Test toJson
      final json = user.toJson();
      expect(json['name'], 'Jane Doe');
      expect(json['age'], 25);
      expect(json['email'], 'jane@example.com');

      // Test fromJson
      final userFromJson = UserDataClass.fromJson(json);
      expect(userFromJson.name, 'Jane Doe');
      expect(userFromJson.age, 25);
      expect(userFromJson.email, 'jane@example.com');
    });

    test('dataClass constant should still work (deprecated)', () {
      final user = UserDataClassConstant(
        name: 'Bob Smith',
        age: 35,
      );

      expect(user.name, 'Bob Smith');
      expect(user.age, 35);

      // Test toJson
      final json = user.toJson();
      expect(json['name'], 'Bob Smith');
      expect(json['age'], 35);

      // Test fromJson
      final userFromJson = UserDataClassConstant.fromJson(json);
      expect(userFromJson.name, 'Bob Smith');
      expect(userFromJson.age, 35);
    });

    test('dataforge constant should work', () {
      final user = UserDataforgeConstant(
        name: 'Alice Johnson',
        age: 28,
      );

      expect(user.name, 'Alice Johnson');
      expect(user.age, 28);

      // Test toJson
      final json = user.toJson();
      expect(json['name'], 'Alice Johnson');
      expect(json['age'], 28);

      // Test fromJson
      final userFromJson = UserDataforgeConstant.fromJson(json);
      expect(userFromJson.name, 'Alice Johnson');
      expect(userFromJson.age, 28);
    });

    test('All classes should have proper equality and hashCode', () {
      final user1 =
          UserDataforge(name: 'Test', age: 20, email: 'test@example.com');
      final user2 =
          UserDataforge(name: 'Test', age: 20, email: 'test@example.com');
      final user3 =
          UserDataforge(name: 'Different', age: 20, email: 'test@example.com');

      expect(user1, equals(user2));
      expect(user1.hashCode, equals(user2.hashCode));
      expect(user1, isNot(equals(user3)));
    });

    test('All classes should have proper copyWith functionality', () {
      final user = UserDataforge(
          name: 'Original', age: 25, email: 'original@example.com');
      final copied = user.copyWith(name: 'Updated');

      expect(copied.name, 'Updated');
      expect(copied.age, 25); // Should remain the same
      expect(copied.email, 'original@example.com'); // Should remain the same
    });
  });
}
