import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'custom_type_read_value_test.model.data.dart';

/// Test class for readValue returning custom types
@Dataforge()
class CustomTypeReadValueTest with _CustomTypeReadValueTest {
  @override
  @JsonKey(readValue: _readTradeInfo)
  final TradeInfoBean? tradeInfo;

  @override
  @JsonKey(readValue: _readUserInfo)
  final UserInfo userInfo;

  const CustomTypeReadValueTest({
    this.tradeInfo,
    required this.userInfo,
  });

  /// Custom readValue method that returns TradeInfoBean (custom type)
  static Object? _readTradeInfo(Map<dynamic, dynamic> map, String key) {
    final value = map[key];
    if (value != null) {
      if (value["status"] == "SOLD_OUT") {
        return null;
      }
    }
    return value;
  }

  /// Custom readValue method that returns UserInfo (custom type)
  static Object? _readUserInfo(Map<dynamic, dynamic> map, String key) {
    final value = map[key] ?? map["user"] ?? {};
    return value;
  }

  factory CustomTypeReadValueTest.fromJson(Map<String, dynamic> json) {
    return _CustomTypeReadValueTest.fromJson(json);
  }
}

/// Supporting class for testing
@Dataforge()
class TradeInfoBean with _TradeInfoBean {
  @override
  final String status;
  @override
  final double price;

  const TradeInfoBean({
    required this.status,
    required this.price,
  });
  factory TradeInfoBean.fromJson(Map<String, dynamic> json) {
    return _TradeInfoBean.fromJson(json);
  }
}

/// Supporting class for testing
@Dataforge()
class UserInfo with _UserInfo {
  @override
  final String name;
  @override
  final int age;

  const UserInfo({
    required this.name,
    required this.age,
  });
  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return _UserInfo.fromJson(json);
  }
}
