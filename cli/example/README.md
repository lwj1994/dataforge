# Dataforge CLI v1 clean consumer

该示例从没有生成文件的状态开始，使用 CLI 生成一个 `abstract final` 模型的
`final` 实现，并验证嵌套集合防御性复制和 JSON 往返值语义。

```bash
dart pub get
dart run dataforge_cli:dataforge_cli generate .
dart analyze --fatal-infos
dart run bin/main.dart
dart run dataforge_cli:dataforge_cli check .
```
