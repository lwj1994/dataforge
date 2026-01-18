import 'package:test/test.dart';
import 'models/jsonkey_generic_test.model.dart';

void main() {
  group('JsonKey Generic Tests', () {
    test('ApiResponse with User data should serialize/deserialize correctly',
        () {
      // Create test data
      final user = User(
        id: 1,
        name: 'John Doe',
        email: 'john@example.com',
        age: 30,
      );

      final apiResponse = ApiResponse<User>(
        success: true,
        message: 'Success',
        data: user,
      );

      // Test toJson
      final json = apiResponse.toJson();
      expect(json['success'], true);
      expect(json['message'], 'Success');
      expect(json['data'], isA<Map<String, dynamic>>());

      // Test fromJson
      final restored = ApiResponse<User>.fromJson(json);
      expect(restored.success, true);
      expect(restored.message, 'Success');
      expect(restored.data, isA<User>());
      expect(restored.data?.id, 1);
      expect(restored.data?.name, 'John Doe');
      expect(restored.data?.email, 'john@example.com');
      expect(restored.data?.age, 30);
    });

    test('ApiResponse with null data should work correctly', () {
      final apiResponse = ApiResponse<User>(
        success: false,
        message: 'Error occurred',
        data: null,
      );

      // Test toJson
      final json = apiResponse.toJson();
      expect(json['success'], false);
      expect(json['message'], 'Error occurred');
      expect(json.containsKey('data'),
          false); // null values should not be included

      // Test fromJson
      final restored = ApiResponse<User>.fromJson(json);
      expect(restored.success, false);
      expect(restored.message, 'Error occurred');
      expect(restored.data, null);
    });

    test('ListResponse with User items should serialize/deserialize correctly',
        () {
      // Create test data
      final users = [
        User(id: 1, name: 'John', email: 'john@example.com', age: 30),
        User(id: 2, name: 'Jane', email: 'jane@example.com', age: 25),
      ];

      final listResponse = ListResponse<User>(
        total: 2,
        items: users,
      );

      // Test toJson
      final json = listResponse.toJson();
      expect(json['total'], 2);
      expect(json['items'], isA<List>());
      expect((json['items'] as List).length, 2);

      // Test fromJson
      final restored = ListResponse<User>.fromJson(json);
      expect(restored.total, 2);
      expect(restored.items, isA<List<User>>());
      expect(restored.items?.length, 2);
      expect(restored.items?[0].name, 'John');
      expect(restored.items?[1].name, 'Jane');
    });

    test('ListResponse with null items should work correctly', () {
      final listResponse = ListResponse<User>(
        total: 0,
        items: null,
      );

      // Test toJson
      final json = listResponse.toJson();
      expect(json['total'], 0);
      expect(json.containsKey('items'),
          false); // null values should not be included

      // Test fromJson
      final restored = ListResponse<User>.fromJson(json);
      expect(restored.total, 0);
      expect(restored.items, null);
    });

    test('Nested generic types should work correctly', () {
      // Create nested structure: ApiResponse<ListResponse<User>>
      final users = [
        User(id: 1, name: 'Alice', email: 'alice@example.com'),
        User(id: 2, name: 'Bob', email: 'bob@example.com'),
      ];

      final listResponse = ListResponse<User>(
        total: 2,
        items: users,
      );

      final apiResponse = ApiResponse<ListResponse<User>>(
        success: true,
        message: 'Users retrieved successfully',
        data: listResponse,
      );

      // Test toJson
      final json = apiResponse.toJson();
      expect(json['success'], true);
      expect(json['message'], 'Users retrieved successfully');
      expect(json['data'], isA<Map<String, dynamic>>());

      final dataJson = json['data'] as Map<String, dynamic>;
      expect(dataJson['total'], 2);
      expect(dataJson['items'], isA<List>());

      // Test fromJson
      final restored = ApiResponse<ListResponse<User>>.fromJson(json);
      expect(restored.success, true);
      expect(restored.message, 'Users retrieved successfully');
      expect(restored.data, isA<ListResponse<User>>());
      expect(restored.data?.total, 2);
      expect(restored.data?.items?.length, 2);
      expect(restored.data?.items?[0].name, 'Alice');
      expect(restored.data?.items?[1].name, 'Bob');
    });
  });
}
