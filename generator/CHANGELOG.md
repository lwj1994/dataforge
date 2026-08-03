## 1.0.0-dev.0

### Added

- 新增 v1 `abstract final` factory 模型的 resolved Analyzer → schema → renderer
  build_runner 链路。
- 新增从无生成文件开始的 clean-consumer 集成测试，覆盖深层集合、strict JSON、
  Record 与泛型 witness。
- 新增代表性 library ordering、namespace 与 CLI 字节一致性测试。

### Changed

- generator 改为 v1-only，只接受 `abstract final` factory 声明。
- adapter 只调用 dataforge_base 的 resolved generation facade，不直接访问 raw schema
  或 renderer。
- 最低 Dart SDK 调整为 3.9，以匹配 Analyzer 8.x 基线。
- annotation/base 依赖在预览期精确锁定 `1.0.0-dev.0`；本地 path dependency 移入
  `pubspec_overrides.yaml`。
- published builder 固定生成 `.data.dart` part。

### Fixed

- build_runner 入口继承 resolved frontend 的声明边界、完整生成符号冲突、
  `DataforgeDefault` 可赋值性与 exact witness 校验。
- 非法声明在写出源码前产生带位置的稳定 diagnostic。

### Preview limitations

- 已有代表性 fixture 验证 build_runner 与 CLI 字节一致；完整类型矩阵和跨平台 GA
  验证尚未完成。
- 生成 API 与输出格式在后续 dev/beta 版本中仍可能改变。
