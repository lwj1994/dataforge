import 'package:test/test.dart';
import 'models/jsonkey_generic_test.model.dart';

/// Test file to verify JsonKey fromJson/toJson parameters with generics
void main() {
  group('JsonKey Generic Functionality Tests', () {
    test('ApiResponse<User> serialization and deserialization', () {
      // Create test data
      final user = User(
        id: 1,
        name: 'John Doe',
        email: 'john@example.com',
        age: 30,
      );

      final apiResponse = ApiResponse<User>(
        success: true,
        message: 'User retrieved successfully',
        data: user,
      );

      // Test serialization (toJson)
      final json = apiResponse.toJson();
      expect(json['success'], true);
      expect(json['message'], 'User retrieved successfully');
      expect(json['data'], isA<Map<String, dynamic>>());
      expect(json['data']['id'], 1);
      expect(json['data']['name'], 'John Doe');
      expect(json['data']['email'], 'john@example.com');
      expect(json['data']['age'], 30);

      // Test deserialization (fromJson)
      final deserializedResponse = ApiResponse<User>.fromJson(json);
      expect(deserializedResponse.success, true);
      expect(deserializedResponse.message, 'User retrieved successfully');
      expect(deserializedResponse.data, isNotNull);
      expect(deserializedResponse.data!.id, 1);
      expect(deserializedResponse.data!.name, 'John Doe');
      expect(deserializedResponse.data!.email, 'john@example.com');
      expect(deserializedResponse.data!.age, 30);
    });

    test('ApiResponse<String> with primitive type', () {
      final apiResponse = ApiResponse<String>(
        success: true,
        message: 'Operation successful',
        data: 'Hello World',
      );

      // Test serialization
      final json = apiResponse.toJson();
      expect(json['success'], true);
      expect(json['message'], 'Operation successful');
      expect(json['data'], 'Hello World');

      // Test deserialization
      final deserializedResponse = ApiResponse<String>.fromJson(json);
      expect(deserializedResponse.success, true);
      expect(deserializedResponse.message, 'Operation successful');
      expect(deserializedResponse.data, 'Hello World');
    });

    test('ListResponse<User> serialization and deserialization', () {
      // Create test data
      final users = [
        User(id: 1, name: 'John Doe', email: 'john@example.com', age: 30),
        User(id: 2, name: 'Jane Smith', email: 'jane@example.com', age: 25),
      ];

      final listResponse = ListResponse<User>(
        total: 2,
        items: users,
      );

      // Test serialization
      final json = listResponse.toJson();
      expect(json['total'], 2);
      expect(json['items'], isA<List>());
      expect(json['items'].length, 2);
      expect(json['items'][0]['id'], 1);
      expect(json['items'][0]['name'], 'John Doe');
      expect(json['items'][1]['id'], 2);
      expect(json['items'][1]['name'], 'Jane Smith');

      // Test deserialization
      final deserializedResponse = ListResponse<User>.fromJson(json);
      expect(deserializedResponse.total, 2);
      expect(deserializedResponse.items, isNotNull);
      expect(deserializedResponse.items!.length, 2);
      expect(deserializedResponse.items![0].id, 1);
      expect(deserializedResponse.items![0].name, 'John Doe');
      expect(deserializedResponse.items![1].id, 2);
      expect(deserializedResponse.items![1].name, 'Jane Smith');
    });

    test('ApiResponse with null data', () {
      final apiResponse = ApiResponse<User>(
        success: false,
        message: 'User not found',
        data: null,
      );

      // Test serialization
      final json = apiResponse.toJson();
      expect(json['success'], false);
      expect(json['message'], 'User not found');
      // When data is null, the 'data' key is not included in the JSON
      expect(json.containsKey('data'), false);

      // Test deserialization
      final deserializedResponse = ApiResponse<User>.fromJson(json);
      expect(deserializedResponse.success, false);
      expect(deserializedResponse.message, 'User not found');
      expect(deserializedResponse.data, null);
    });

    test('ListResponse with empty list', () {
      final listResponse = ListResponse<User>(
        total: 0,
        items: [],
      );

      // Test serialization
      final json = listResponse.toJson();
      expect(json['total'], 0);
      expect(json['items'], isA<List>());
      expect(json['items'].length, 0);

      // Test deserialization
      final deserializedResponse = ListResponse<User>.fromJson(json);
      expect(deserializedResponse.total, 0);
      expect(deserializedResponse.items, isNotNull);
      expect(deserializedResponse.items!.length, 0);
    });

    test('Nested generic types - ApiResponse<ListResponse<User>>', () {
      // Create nested test data
      final users = [
        User(id: 1, name: 'John Doe', email: 'john@example.com'),
      ];

      final listResponse = ListResponse<User>(
        total: 1,
        items: users,
      );

      final apiResponse = ApiResponse<ListResponse<User>>(
        success: true,
        message: 'Users retrieved successfully',
        data: listResponse,
      );

      // Test serialization
      final json = apiResponse.toJson();
      expect(json['success'], true);
      expect(json['message'], 'Users retrieved successfully');
      expect(json['data'], isA<Map<String, dynamic>>());
      expect(json['data']['total'], 1);
      expect(json['data']['items'], isA<List>());
      expect(json['data']['items'][0]['name'], 'John Doe');

      // Test deserialization
      final deserializedResponse =
          ApiResponse<ListResponse<User>>.fromJson(json);
      expect(deserializedResponse.success, true);
      expect(deserializedResponse.message, 'Users retrieved successfully');
      expect(deserializedResponse.data, isNotNull);
      expect(deserializedResponse.data!.total, 1);
      expect(deserializedResponse.data!.items, isNotNull);
      expect(deserializedResponse.data!.items!.length, 1);
      expect(deserializedResponse.data!.items![0].name, 'John Doe');
    });
  });
}
