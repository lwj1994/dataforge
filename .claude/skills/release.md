# Release Skill

用于发布 dataforge 项目的所有包到 pub.dev。

## 使用方法

```
/release <version>
```

例如：`/release 0.6.1` 或 `/release 1.0.0`

## 发布流程

此 skill 会自动执行以下步骤：

1. **格式化代码** - 对所有包执行 `dart format`
2. **运行测试** - 确保所有测试通过
3. **更新版本号** - 更新所有包的 pubspec.yaml 和 CHANGELOG.md
4. **创建 Git Tag** - 创建版本标签并推送到远程
5. **发布包** - 按依赖顺序发布包，每个包间隔 4 分钟：
   - dataforge_annotation
   - dataforge_base
   - dataforge (generator)
   - dataforge_cli

---

## 实现

### 步骤 1: 格式化代码

对所有包执行代码格式化：

```bash
dart format annotation/ dataforge_base/ generator/ cli/
```

### 步骤 2: 运行测试

确保所有包的测试都通过：

```bash
cd annotation && dart test && cd ..
cd dataforge_base && dart test && cd ..
cd generator && dart test && cd ..
cd cli && dart test && cd ..
```

如果任何测试失败，停止发布流程并报告错误。

### 步骤 3: 更新版本号和 CHANGELOG

#### 3.1 更新 pubspec.yaml 版本号

更新以下文件中的版本号：
- `annotation/pubspec.yaml` - 第 3 行 `version: {version}`
- `dataforge_base/pubspec.yaml` - 第 3 行 `version: {version}`
- `generator/pubspec.yaml` - 第 3 行 `version: {version}`
- `cli/pubspec.yaml` - 第 3 行 `version: {version}`

#### 3.2 更新 CHANGELOG.md

在每个包的 CHANGELOG.md 文件顶部添加新版本条目：

**文件列表：**
- `CHANGELOG.md` (根目录，用于整体项目记录)
- `annotation/CHANGELOG.md`
- `dataforge_base/CHANGELOG.md`
- `generator/CHANGELOG.md`
- `cli/CHANGELOG.md`

**格式示例：**

```markdown
## {version}
- [变更描述 1]
- [变更描述 2]
- [变更描述 3]

## {previous_version}
...
```

**注意事项：**
1. 新版本条目添加在文件最顶部
2. 不需要添加发布日期（与现有格式保持一致）
3. 使用 `-` 开头的列表格式描述变更
4. 如果是主要版本，可以分类：
   - `### Added` - 新增功能
   - `### Fixed` - Bug 修复
   - `### Changed` - 变更内容
   - `### Documentation` - 文档更新

**示例：**

```markdown
## 0.7.0
- Support for nullable types in JSON serialization
- Add new CLI flag `--watch` for hot reload
- Fix DateTime parsing edge cases

## 0.6.0
...
```

### 步骤 4: 创建 Git Tag 并推送

```bash
git add .
git commit -m "release: version {version}"
git tag v{version}
git push origin main
git push origin v{version}
```

### 步骤 5: 发布包

按依赖顺序发布包，每个包间隔 4 分钟以确保 pub.dev 同步完成：

```bash
# 1. 发布 annotation (无依赖)
cd annotation && dart pub publish --force && cd ..

# 等待 4 分钟
sleep 240

# 2. 发布 dataforge_base (无依赖)
cd dataforge_base && dart pub publish --force && cd ..

# 等待 4 分钟
sleep 240

# 3. 发布 generator (依赖 annotation 和 dataforge_base)
cd generator && dart pub publish --force && cd ..

# 等待 4 分钟
sleep 240

# 4. 发布 cli (依赖 annotation 和 dataforge_base)
cd cli && dart pub publish --force && cd ..
```

## 注意事项

- 确保你已经登录 pub.dev (`dart pub login`)
- 确保你有权限发布这些包
- 发布前会显示每个包的变更内容供确认
- 如果发布过程中某个包失败，会停止后续发布并报告错误
- 使用 `--force` 跳过发布确认，自动化发布流程

## 错误处理

如果在任何步骤失败：
1. **测试失败** - 修复测试问题后重新运行
2. **发布失败** - 检查网络连接和 pub.dev 权限，手动发布剩余的包
3. **Git 推送失败** - 检查远程仓库权限

## 回滚

如果需要回滚：
1. Git tag 可以删除: `git tag -d v{version} && git push origin :refs/tags/v{version}`
2. 已发布的包无法从 pub.dev 删除，只能发布新版本修复
