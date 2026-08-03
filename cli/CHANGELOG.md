## 1.0.0-dev.0

### Added

- 新增与 build_runner 共享 resolved generation facade/renderer 的 v1 adapter。
- 新增显式 `dataforge generate [path]` 与严格只读的 `dataforge check [path]`。
- 新增内存格式化、Analyzer overlay 验证、逐文件同目录原子 rename、带 journal 的
  多文件回滚/恢复与进程锁。
- 新增 annotation 常量/part 解析、输入快照复验、事务故障恢复、monorepo 并发和
  代表性双前端字节一致性测试。
- shared renderer 支持 Record 的递归非 JSON 值语义与 exact witness 边界。

### Changed

- CLI 改为 v1-only，公开命令面仅保留显式 `generate` 与 `check` subcommand。
- generation 统一通过 resolved facade，不直接持有或渲染 raw schema。
- 最低 Dart SDK 调整为 3.9，以匹配 Analyzer 8.x 基线。
- 参数、resolve、generation、precondition、I/O 与 internal failure 使用稳定非零退出状态。
- 目录扫描确定性排序、无任意递归深度上限，并避免误跳过普通业务目录。
- annotation/base 依赖在预览期精确锁定 `1.0.0-dev.0`；本地 path dependency 移入
  `pubspec_overrides.yaml`。

### Fixed

- 非 Dart 输入、解析失败和目录失败不再被报告为成功。
- 修复带 import prefix 的完整集合类型树生成。
- `check` 遇到漂移或未完成 journal 时严格零写入，不创建 lock 或触发恢复。
- 事务提交前通过 Analyzer overlay 验证完整 library，并以所有权标记、retained part
  引用和输入快照保护 orphan 清理。
- generation journal 使用旧/新 SHA-256 追加状态；未知改写、非法 journal、symlink、
  非普通文件与目标抢占均保留现场并失败。
- 提交锁内复核源码、传递依赖、package config 与 pubspec；orphan 删除要求源文件仍
  不存在。
- monorepo 按目标 package root 分组提交；外层与嵌套调用修改同一输出时共享
  lock/journal，外层 check 也会发现嵌套 package 的未完成事务。

### Preview limitations

- generate/check 尚未提供结构化 JSON report。
- 完整类型矩阵、属性测试、跨平台故障注入与 GA 级双前端一致性门禁尚未完成。
