import 'package:test/test.dart';
import '../lib/nested.dart';

void main() {
  group('Nested CopyWith Tests', () {
    test('Traditional copyWith works', () {
      final user = NestedDefaultValues(name: 'original');
      final updated = user.copyWith(name: 'updated');

      expect(updated.name, 'updated');
      expect(updated.nested.intValue, 42); // remains default
    });

    test('Traditional nested replacement works', () {
      final user = NestedDefaultValues();
      final newNested = InnerDefaultValues(intValue: 100);

      final updated = user.copyWith(nested: newNested);

      expect(updated.nested.intValue, 100);
      expect(updated.nested.stringValue, 'default');
    });

    test('New chained copyWith using \$ prefix works', () {
      final user = NestedDefaultValues(name: 'tester');

      // 使用新的 $nested 链式入口修改内层属性
      final updated = user.copyWith.$nested.intValue(999);

      expect(updated.name, 'tester'); // 外层属性保持
      expect(updated.nested.intValue, 999); // 内层属性已更新
      expect(updated.nested.stringValue, 'default'); // 内层其他属性保持
    });

    test('Deeply chained copyWith multiple calls', () {
      final user = NestedDefaultValues();

      // 链式调用多次修改
      final updated = user.copyWith.$nested
          .intValue(123)
          .copyWith
          .$nested
          .stringValue('hello');

      expect(updated.nested.intValue, 123);
      expect(updated.nested.stringValue, 'hello');
      expect(updated.nested.boolValue, true);
    });

    test('3-level deep chained copyWith works', () {
      final deep = DeepRootExample(
        id: '1',
        root: NestedDefaultValues(
          name: 'root_name',
          nested: InnerDefaultValues(intValue: 10),
        ),
      );

      // 修改最深层的 intValue
      // 这里的每一级 $xxx 操作都通过 _then 传回根部 R (DeepRootExample)
      final updated = deep.copyWith.$root.$nested.intValue(777);

      expect(updated.id, '1');
      expect(updated.root.name, 'root_name');
      expect(updated.root.nested.intValue, 777);
    });

    test('4-level deep chained copyWith works', () {
      final superDeep = SuperDeepRoot(
        root: DeepRootExample(
          id: 'root-1',
          root: NestedDefaultValues(
            name: 'level-2',
            nested: InnerDefaultValues(intValue: 100),
          ),
        ),
      );

      // 4层深度修改：SuperDeepRoot -> DeepRootExample -> NestedDefaultValues -> InnerDefaultValues
      // superDeep.copyWith.$root.$root.$nested.intValue(888)
      // 注意：DeepRootExample 里的字段名也叫 root
      final updated = superDeep.copyWith.$root.$root.$nested.intValue(888);

      expect(updated.root.id, 'root-1');
      expect(updated.root.root.name, 'level-2');
      expect(updated.root.root.nested.intValue, 888);
    });
  });
}
