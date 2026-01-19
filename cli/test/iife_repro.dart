class UserInfo {
  final String name;
  UserInfo({required this.name});
  static UserInfo fromJson(Map<String, dynamic> json) =>
      UserInfo(name: json['name'] as String? ?? '');
}

void main() {
  final dynamic v = <dynamic, dynamic>{'name': 'test'};

  final result = ((dynamic v) {
    if (v is UserInfo) return v;
    if (v is Map) {
      print('v is Map');
      return UserInfo.fromJson(v.cast<String, dynamic>());
    }
    print('Fallthrough cast');
    return v as UserInfo;
  })(v);

  print('Result: ${result.name}');
}
