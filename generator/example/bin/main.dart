import 'package:dataforge_generator_example/example.dart';

void main() {
  // Test User class
  final user = User(name: 'John', age: 30, email: 'john@example.com');
  print('Original user: $user');

  // Test traditional copyWith (via call method)
  final updatedUser = user.copyWith(name: 'Jane', age: 25);
  print('Updated user: $updatedUser');

  // Test toJson
  final userJson = user.toJson();
  print('User JSON: $userJson');

  // Test fromJson
  final userFromJson = User.fromJson(userJson);
  print('User from JSON: $userFromJson');

  // Test equality
  print('user == userFromJson: ${user == userFromJson}');

  // Test Product with JsonKey
  final product = Product(
    id: '123',
    productName: 'Widget',
    unitPrice: 9.99,
    createdAt: DateTime.now(),
  );
  print('\nOriginal product: $product');

  final productJson = product.toJson();
  print('Product JSON: $productJson'); // Should use snake_case keys

  // Test generic Result
  final result = Result<String>(
    data: 'Success!',
    success: true,
  );
  print('\nResult: $result');

  final failedResult = Result<String>(
    error: 'Something went wrong',
    success: false,
  );
  print('Failed result: $failedResult');

  // Test Address with traditional copyWith
  final address = Address(
    street: '123 Main St',
    city: 'Springfield',
    country: 'USA',
  );
  print('\nOriginal address: $address');

  final updatedAddress = address.copyWith(city: 'New York');
  print('Updated address: $updatedAddress');

  // Test ComplexUser with Nested CopyWith
  final complexUser = ComplexUser(
    user: user,
    address: address,
    nickname: 'Johnny',
  );
  print('\nOriginal complex user: $complexUser');

  // Test Flat Accessor CopyWith: updates sub-fields using flat methods with $ separator
  final updatedComplexUser =
      complexUser.copyWith.user$name('Jane').copyWith.address$city('Chicago');
  print('Updated complex user (true chain): $updatedComplexUser');

  // Verify changes
  if (updatedComplexUser.user.name == 'Jane' &&
      updatedComplexUser.address.city == 'Chicago' &&
      updatedComplexUser.nickname == 'Johnny') {
    print('✅ Nested copyWith verified!');
  } else {
    print('❌ Nested copyWith failed!');
  }

  print('\n✅ All tests passed!');
}
