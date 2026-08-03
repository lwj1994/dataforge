import 'package:dataforge_cli_example/user.dart';

void main() {
  final input = <List<int>>[
    <int>[1, 2],
  ];
  final user = User(name: 'milu', scores: input);

  input.single.add(3);
  if (user.scores.single.length != 2) {
    throw StateError('构造后仍受外部嵌套集合修改影响。');
  }
  _expectUnsupported(() => user.scores.add(<int>[4]));
  _expectUnsupported(() => user.scores.single.add(4));

  final decoded = User.fromJson(user.toJson());
  if (decoded != user || decoded.hashCode != user.hashCode) {
    throw StateError('JSON 往返没有保持完整值语义。');
  }

  print(decoded);
}

void _expectUnsupported(void Function() mutation) {
  try {
    mutation();
  } on UnsupportedError {
    return;
  }
  throw StateError('模型公开了可修改集合。');
}
