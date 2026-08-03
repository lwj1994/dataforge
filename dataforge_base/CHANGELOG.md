## 1.0.0-dev.0

### Added

- 新增 analyzer-independent `TypeShape` / `ModelSchema` IR 与稳定 diagnostic code。
- 新增 resolved Analyzer schema builder、跨模型验证与 Dart renderer。
- 新增 final implementation、递归冻结、strict JSON、深度 equality/hash、Record 与
  泛型 witness 代码生成。
- 生成 model witness 使用完整语义类型树 identity；freeze/equality/hash 统一递归到
  叶节点 witness。
- 新增 mutation attack、schema、diagnostic、public API boundary 与 writer golden 测试。

### Changed

- public API 收敛为 resolved v1 generation facade、diagnostic 与稳定 `SchemaId`。
- raw schema、schema builder 与 renderer 仅保留为 package implementation detail。
- 最低 Dart SDK 调整为 3.9，以匹配 Analyzer 8.x 基线。
- 所有公开 diagnostic/list/map 内容在构造边界递归快照并冻结。

### Fixed

- 修复 Analyzer 8 prefixed import、show/hide、re-export 与 typedef namespace 识别。
- Record witness identity 仅包含布局和子 witness，不包含宿主模型。
- model witness 在 identical 快路前验证内部 witness compatibility。
- JSON 启用时在生成期拒绝无法唯一编码为 String 的 Map key 语义。
- 泛型 equality 按擦除后的模型声明与完整 witness 树比较，并为容器、model 与 Record
  生成 erased equality bridge，保证交叉协变场景仍对称且 hash 一致。
- exact `DataforgeType<X>` 作为完整 TypeShape 子树边界，不越界检查内部 Record、Map
  key 或嵌套 model JSON capability。
- strict JSON 生成代码携带稳定 DFJ code、expected/actual、canonical model id 与
  schema field。
- 补齐生成成员、Object 成员、import/type qualifier、Dart 类型与局部变量命名冲突诊断。
- JSON object 输入先复制到标准 String equality 的不可修改 Map；ignored/default 值的
  freeze 失败保留结构化路径。
- resolved 声明边界拒绝额外 named constructor、继承、implements、用户实现与生成
  私有成员直引。
- `DataforgeDefault` 使用 resolved 常量类型校验 enum prefix/re-export/typedef 与精确
  `int` → `double`。
- model witness 校验使用 Analyzer 已实例化的 constructor 签名，避免对 hidden
  companion、Record 与递归签名产生无关误拒。

### Preview limitations

- 这是内部核心预览；独立 adapter 与生成事务由 `dataforge_cli` 提供。
- 完整 GA 类型、属性、平台和故障注入矩阵仍未完成。
