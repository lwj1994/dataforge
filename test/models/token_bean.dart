import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:collection/collection.dart';

part 'token_bean.data.dart';

/// Token bean for testing cross-file dependencies
@Dataforge()
class TokenBean with _TokenBean {
  @override
  final String accessToken;
  @override
  final String refreshToken;
  @override
  final DateTime expiresAt;
  @override
  final String tokenType;

  const TokenBean({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.tokenType,
  });

  factory TokenBean.fromJson(Map<String, dynamic> json) {
    return _TokenBean.fromJson(json);
  }
}

/// Additional nested class for more complex testing
@Dataforge()
class TokenMetadata with _TokenMetadata {
  @override
  final String issuer;
  @override
  final List<String> scopes;
  @override
  final Map<String, dynamic> claims;

  const TokenMetadata({
    required this.issuer,
    required this.scopes,
    required this.claims,
  });
  factory TokenMetadata.fromJson(Map<String, dynamic> json) {
    return _TokenMetadata.fromJson(json);
  }
}
