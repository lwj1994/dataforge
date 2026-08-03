import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:test/test.dart';

void main() {
  test('DataforgeDefault 保留递归 const 默认值', () {
    const annotation = DataforgeDefault(<String, Object?>{
      'items': <int>[1, 2],
      'enabled': true,
      'label': null,
    });

    expect(
      annotation.value,
      equals(<String, Object?>{
        'items': <int>[1, 2],
        'enabled': true,
        'label': null,
      }),
    );
  });

  test('JsonKey metadata 的 const alternateNames 深度不可修改', () {
    const annotation = JsonKey(alternateNames: ['previous_name', 'old_name']);

    expect(annotation.alternateNames, ['previous_name', 'old_name']);
    expect(
      () => annotation.alternateNames.add('mutable'),
      throwsUnsupportedError,
    );
  });
}
