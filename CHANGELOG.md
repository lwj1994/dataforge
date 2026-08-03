## 1.0.0-dev.0

这是 Dataforge v1 深度不可变值对象语义的首个预发布版本，不代表 1.0 GA 门禁已经完成。

### Added

- 新增 `DataforgeDefault`，为 redirecting factory 参数提供编译期默认值。
- 新增 `DataforgeType<T>`、`DataforgeTypeIdentity`、
  `DataforgeTypeErasedEquality`、完整语义类型树 helper、strict JSON context/error 与
  稳定 `DFJ` code。
- 新增 `abstract final` factory → generated `final` implementation 的 build_runner
  与独立 CLI 预览链路。
- 新增任意深度 List/Set/Map/Record 冻结、深度 equality/hash、泛型 witness 与 strict
  JSON 生成。
- Record 支持递归非 JSON 值语义；整棵子树的 exact witness 可以提供 JSON 语义。
- CLI 新增显式 `dataforge generate [path]` 与严格只读的
  `dataforge check [path]`。
- CLI 新增内存格式化、Analyzer overlay 验证、输入快照复验、进程锁、带 journal 的
  多文件回滚/恢复与逐文件同目录原子替换。
- 新增 clean-consumer、mutation attack、事务中断/并发、双前端代表性字节一致性与
  发布归档门禁。
- 新增 1.0 RFC 和支持矩阵。

### Changed

- 四个发布包统一为 v1-only，只接受 `abstract final` factory 声明。
- 值属性由 unnamed redirecting factory 参数定义；生成实现为 `final`。
- 所有公开集合输入在构造、copyWith、默认值和 decode 边界复制并递归冻结。
- raw schema、schema builder 与 renderer 不再属于 public API；两个 adapter 只能通过
  resolved generation facade 进入。
- 四包最低 Dart SDK 统一为 3.9，以匹配 Analyzer 8.x 与生成代码基线。
- generator/cli 精确依赖同版本 annotation/base；本地 path 引用移入
  `pubspec_overrides.yaml` 并排除在发布归档之外。
- 所有 authored Dart source comment 与 public API doc comment 统一使用英文。

### Fixed

- copyWith 未传值 sentinel 使用私有 identity，避免与任意合法字段值碰撞。
- 内置与生成 witness 按完整语义类型树比较并计算 hash；自定义 witness 默认保持对象
  identity 语义。
- Set/Map 冻结拒绝 witness 语义下重复元素/key，Set JSON decode 以 DFJ1009 拒绝
  解码后重复元素，避免静默丢值；NaN 具有一致的模型 equality/hash，同时仍被 strict
  JSON 拒绝。
- DateTime JSON 输出正规化为 UTC `Z`，保证跨时区往返表示同一时刻。
- enum witness 拒绝未声明值与重复值列表，identity 使用实际 enum 类型与无序名称集。
- non-null witness encode 返回 null 时统一失败；nullable witness 仍可合法编码 null。
- 泛型 equality 先验证完整 witness compatibility，再以 erased protocol 递归比较容器、
  model 与 Record，修复交叉协变和非对称比较。
- exact witness 成为完整 TypeShape 子树边界，可覆盖 Object/dynamic、自定义值、泛型
  model 和 Record composite。
- strict JSON decode 以 DFJ1008 拒绝循环容器，并分别检查原始 String key 与解码后
  witness key 的重复。
- strict JSON 错误稳定携带 code、path、expected/actual、canonical model 与 schema
  field；生成器同时拒绝会遮蔽 import/type qualifier 的命名。
- 自定义 witness 契约要求行为与 identity 图生命周期内不可变、有限且无环。
- resolved frontend 拒绝额外 named constructor、非 Object 继承、implements、手写
  生成实现/mixin/helper 与生成私有成员直引。
- `DataforgeDefault` 使用 resolved 常量类型验证可赋值性，并支持安全的精确
  `int` → `double`、enum alias/prefix 与 typedef。
- CLI `check` 遇到漂移或未完成 journal 时保持严格只读，不创建 lock 或改写文件。
- 生成提交前使用 Analyzer overlay 验证完整 library；orphan 删除同时校验所有权、
  retained part 引用与输入快照。
- generation journal 使用带旧/新 SHA-256 的追加状态；未知改写、非法状态与 symlink
  一律保留现场并失败。
- monorepo 按目标 package root 获取 lock/journal，外层与嵌套调用不会并发写同一输出。

### Preview limitations

- generate/check 尚未提供结构化 JSON report。
- CLI/build_runner 只完成代表性 fixture 的字节一致性验证；完整类型矩阵、属性测试、
  跨平台故障注入与 GA 门禁仍未完成。
- API、诊断与生成格式在后续 dev/beta 版本中仍可能破坏性调整。
