import 'package:test/test.dart';
import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'token_bean.dart';

part 'cross_file_test.data.dart';

@Dataforge()
class UserProfile with _UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.token, // 跨文件引用TokenBean
  });

  @override
  final int id;
  @override
  final String name;
  @override
  final TokenBean token; // 跨文件引用TokenBean

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return _UserProfile.fromJson(json);
  }
}

@Dataforge()
class SessionData with _SessionData {
  const SessionData({
    required this.sessionId,
    required this.user, // 跨文件引用UserProfile
  });

  @override
  final String sessionId;
  @override
  final UserProfile user; // 跨文件引用UserProfile

  factory SessionData.fromJson(Map<String, dynamic> json) {
    return _SessionData.fromJson(json);
  }
}

void main() {
  group('跨文件测试', () {
    test('TokenBean 序列化和反序列化', () {
      final token = TokenBean(
        accessToken: 'access123',
        refreshToken: 'refresh456',
        expiresAt: DateTime(2024, 12, 31),
        tokenType: 'Bearer',
      );

      final json = token.toJson();
      expect(json['accessToken'], 'access123');
      expect(json['refreshToken'], 'refresh456');

      final fromJson = TokenBean.fromJson(json);
      expect(fromJson.accessToken, 'access123');
      expect(fromJson.refreshToken, 'refresh456');
    });

    test('UserProfile 跨文件引用 TokenBean', () {
      final token = TokenBean(
        accessToken: 'access123',
        refreshToken: 'refresh456',
        expiresAt: DateTime(2024, 12, 31),
        tokenType: 'Bearer',
      );

      final user = UserProfile(
        id: 1,
        name: 'John',
        token: token,
      );

      final json = user.toJson();
      expect(json['id'], 1);
      expect(json['name'], 'John');
      expect(json['token'], isA<Map<String, dynamic>>());
      final tokenJson = json['token'] as Map<String, dynamic>;
      expect(tokenJson['accessToken'], 'access123');
      expect(tokenJson['refreshToken'], 'refresh456');

      final fromJson = UserProfile.fromJson(json);
      expect(fromJson.id, 1);
      expect(fromJson.name, 'John');
      expect(fromJson.token.accessToken, 'access123');
      expect(fromJson.token.refreshToken, 'refresh456');
    });

    test('SessionData 跨文件引用 UserProfile', () {
      final token = TokenBean(
        accessToken: 'access123',
        refreshToken: 'refresh456',
        expiresAt: DateTime(2024, 12, 31),
        tokenType: 'Bearer',
      );

      final user = UserProfile(
        id: 1,
        name: 'John',
        token: token,
      );

      final session = SessionData(
        sessionId: 'session123',
        user: user,
      );

      final json = session.toJson();
      expect(json['sessionId'], 'session123');
      expect(json['user'], isA<Map<String, dynamic>>());
      final userJson = json['user'] as Map<String, dynamic>;
      expect(userJson['id'], 1);
      expect(userJson['name'], 'John');
      expect(userJson['token'], isA<Map<String, dynamic>>());
      final tokenJson = userJson['token'] as Map<String, dynamic>;
      expect(tokenJson['accessToken'], 'access123');

      final fromJson = SessionData.fromJson(json);
      expect(fromJson.sessionId, 'session123');
      expect(fromJson.user.id, 1);
      expect(fromJson.user.name, 'John');
      expect(fromJson.user.token.accessToken, 'access123');
    });

    test('copyWith 功能测试', () {
      final token = TokenBean(
        accessToken: 'access123',
        refreshToken: 'refresh456',
        expiresAt: DateTime(2024, 12, 31),
        tokenType: 'Bearer',
      );

      final user = UserProfile(
        id: 1,
        name: 'John',
        token: token,
      );

      final newToken = TokenBean(
        accessToken: 'newAccess789',
        refreshToken: 'newRefresh012',
        expiresAt: DateTime(2024, 12, 31),
        tokenType: 'Bearer',
      );

      final updatedUser = user.copyWith.token(newToken).build();
      expect(updatedUser.id, 1);
      expect(updatedUser.name, 'John');
      expect(updatedUser.token.accessToken, 'newAccess789');
      expect(updatedUser.token.refreshToken, 'newRefresh012');
    });
  });
}
