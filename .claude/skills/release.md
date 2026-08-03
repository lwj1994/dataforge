# Release Skill

用于把 Dataforge v1 monorepo 的四个包发布到 pub.dev。

## 触发与安全边界

只有用户明确要求“发布版本”或调用 `/release <version>` 时，才能执行外部发布、push
和 tag。普通重构、版本准备或“执行计划”不等于发布授权。

```text
/release 1.0.0-dev.0
/release 1.0.0
```

`1.0.0-dev.0` 是预览版本。发布说明必须明确尚未完成的 GA 类型/平台门禁，不得写成
正式稳定版。1.0 只发布 v1 `abstract final` 模型链路。

## 包与顺序

四包共享版本，必须按依赖顺序发布：

1. `annotation/` → `dataforge_annotation`
2. `dataforge_base/` → `dataforge_base`
3. `generator/` → `dataforge`
4. `cli/` → `dataforge_cli`

`generator` 和 `cli` 的公开 pubspec 必须精确依赖同版本 annotation/base。monorepo
本地 path 引用只放在 `pubspec_overrides.yaml`，并由 `.pubignore` 排除。

## 发布流程

### 1. 对齐版本与文档

更新四个 `pubspec.yaml` 版本，以及 generator/cli 的两个内部 hosted 精确约束。

同时更新：

- 根 `CHANGELOG.md`（annotation 通过软链接共享）；
- `dataforge_base/CHANGELOG.md`、`generator/CHANGELOG.md`、`cli/CHANGELOG.md`；
- 根与各包 README；
- `docs/1.0/RFC.md`、`docs/1.0/SUPPORT_MATRIX.md`；
- `.agents/skills/dataforge/SKILL.md` 中的当前版本边界。

主要版本条目使用 `Added`、`Changed`、`Fixed`、`Preview limitations` 分类。预览版不得
把未通过的 GA 门禁写成已交付。

### 2. 依赖解析

分别在四个 package 运行：

```bash
dart pub get
```

确认 `dart pub deps --style=compact` 中内部包均解析到本次相同版本。两个 example 也要
使用兼容 SDK 和 annotation 约束。

### 3. 格式、分析、测试与示例

```bash
(cd annotation && dart format --output=none --set-exit-if-changed .)
(cd dataforge_base && dart format --output=none --set-exit-if-changed .)
(cd generator && dart format --output=none --set-exit-if-changed lib test example)
(cd cli && dart format --output=none --set-exit-if-changed lib bin test example)
```

随后在每个 package 独立执行：

```bash
dart analyze --fatal-infos
dart test
```

还必须验证：

- generator example 从无 `.data.dart` 状态 build、analyze、test；
- CLI example 从无 `.data.dart` 状态 generate、analyze、run、`check`；
- `dataforge check` 在输出漂移或遗留 journal 存在时严格零写入；
- 最低 Dart SDK、stable、Linux、macOS、Windows CI 矩阵全部通过。

任何失败都停止发布，不允许用 `--force`、`|| true` 或跳过校验掩盖。

### 4. 在无 Git metadata 的快照中执行首次归档 dry-run

发布准备尚未提交时，直接运行 `dart pub publish --dry-run` 会产生 dirty-repository
warning。严格 wrapper 会正确拒绝该 warning，因此首次归档验证必须在包含当前内容、
但不包含 `.git` 的临时快照中执行：

```bash
release_snapshot="$(mktemp -d)"
rsync -a --exclude '.git' --exclude '.dart_tool' ./ "$release_snapshot/"

(cd "$release_snapshot/annotation" && dart pub get)
(cd "$release_snapshot/dataforge_base" && dart pub get)
(cd "$release_snapshot/generator" && dart pub get)
(cd "$release_snapshot/cli" && dart pub get)

(cd "$release_snapshot/annotation" && dart run ../tool/validate_publish_dry_run.dart)
(cd "$release_snapshot/dataforge_base" && dart run ../tool/validate_publish_dry_run.dart)
(cd "$release_snapshot/generator" && dart run ../tool/validate_publish_dry_run.dart dataforge_annotation dataforge_base)
(cd "$release_snapshot/cli" && dart run ../tool/validate_publish_dry_run.dart dataforge_annotation dataforge_base)
```

保留并记录 `release_snapshot` 路径，直到发布完成；不要让清理命令使用空变量或仓库根。

逐项检查：

- package 名、版本、入口、README、CHANGELOG 与 LICENSE 正确；
- archive 不含二进制、`.exe`、lockfile、临时文件、生成/构建目录；
- archive 不含 `pubspec_overrides.yaml` 或本地 path dependency；
- annotation/base 为 0 warning；
- 预览期 generator/cli 只允许 wrapper 精确匹配 annotation/base 的两条
  tight-dependency warning；
- 只允许 0 hint，或精确匹配两个内部依赖的 override hint；
- wrapper 输出格式无法识别、marker 缺失/重复或出现额外 warning/hint 时必须非零退出。

进入 GA 时移除预览 allowlist，并恢复四包全部 0 warning。

### 5. 审阅并提交

向用户汇总版本、变更、测试、示例、快照 dry-run 和已知限制。只有得到发布授权后才
stage、commit、tag 或 push。

```text
release: 1.0.0-dev.0
```

建议 tag：

```text
v1.0.0-dev.0
```

### 6. 在干净提交上复验并逐包发布

提交后先确认工作树干净，再在真实 checkout 中重新执行四条 strict wrapper 命令。
这次不得使用快照来掩盖遗漏提交的文件。

对每个包按依赖顺序执行：

```bash
dart pub publish
```

不要默认使用 `--force`。上游包发布后，以 pub.dev 实际可解析为准，不使用固定时长
sleep。禁用下游本地 override，完成 hosted `dart pub get` 和 strict dry-run 后再发布。

### 7. 完成验证

- 从干净临时 consumer 仅使用 hosted 依赖执行 `dart pub get`；
- 从无 `.data.dart` 状态生成、analyze、test；
- 检查 pub.dev README 与 archive 内容；
- 最后才 push release commit 与 tag（若授权包含 push）。

## 失败与回退

- format、analysis、test、example、dry-run 或 hosted 解析失败：停止后续发布。
- 某包已发布而下游失败：已发布版本不能删除；修复后发布新的预发布 patch，不重用
  版本号。
- tag 未 push 时可在授权范围内处理；已 push tag 只有用户明确授权后才能删除远端。
- 保存完整命令输出和失败包名，不把部分发布报告成全部成功。
